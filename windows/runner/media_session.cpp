#include "media_session.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <systemmediatransportcontrolsinterop.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.h>
#include <winrt/Windows.Storage.Streams.h>

#include <chrono>
#include <condition_variable>
#include <memory>
#include <mutex>
#include <optional>
#include <queue>
#include <string>
#include <thread>
#include <utility>
#include <vector>

using namespace winrt;
using namespace winrt::Windows::Media;
using namespace winrt::Windows::Storage::Streams;

using flutter::EncodableMap;
using flutter::EncodableValue;

namespace {

constexpr UINT WM_MEDIA_EVENT = WM_USER + 43;

std::unique_ptr<flutter::MethodChannel<EncodableValue>> g_channel;
HWND g_msg_window = nullptr;

// Obtained on the UI thread (STA), used by the worker (MTA): agile_ref
// handles marshalling if the object isn't agile.
winrt::agile_ref<SystemMediaTransportControls> g_smtc;
SystemMediaTransportControls g_smtc_ui{nullptr};
winrt::event_token g_tok_button{};
winrt::event_token g_tok_seek{};

// --- Events from Windows to Dart (always on the UI thread) ---

std::mutex g_events_m;
std::queue<std::pair<std::string, EncodableValue>> g_events;

void PostEvent(std::string method, EncodableValue arg) {
  {
    std::lock_guard<std::mutex> lk(g_events_m);
    g_events.emplace(std::move(method), std::move(arg));
  }
  if (g_msg_window != nullptr) {
    PostMessageW(g_msg_window, WM_MEDIA_EVENT, 0, 0);
  }
}

void DrainEvents() {
  std::queue<std::pair<std::string, EncodableValue>> local;
  {
    std::lock_guard<std::mutex> lk(g_events_m);
    std::swap(local, g_events);
  }
  while (!local.empty()) {
    if (g_channel) {
      g_channel->InvokeMethod(
          local.front().first,
          std::make_unique<EncodableValue>(std::move(local.front().second)));
    }
    local.pop();
  }
}

LRESULT CALLBACK MsgWndProc(HWND hwnd, UINT msg, WPARAM w, LPARAM l) {
  if (msg == WM_MEDIA_EVENT) {
    DrainEvents();
    return 0;
  }
  return DefWindowProcW(hwnd, msg, w, l);
}

void EnsureMessageWindow() {
  if (g_msg_window) return;
  static const wchar_t* kClass = L"SonaMediaSessionMsgWindow";
  WNDCLASSW wc = {};
  wc.lpfnWndProc = MsgWndProc;
  wc.hInstance = GetModuleHandleW(nullptr);
  wc.lpszClassName = kClass;
  RegisterClassW(&wc);
  g_msg_window = CreateWindowExW(0, kClass, L"", 0, 0, 0, 0, 0, HWND_MESSAGE,
                                 nullptr, GetModuleHandleW(nullptr), nullptr);
}

// --- Updates from Dart to Windows (on an MTA worker) ---
// Async WinRT calls (.get()) aren't allowed on the UI thread (STA).

struct Update {
  bool clear = false;
  std::string title, artist, album;
  bool playing = false;
  int64_t position_ms = 0;
  int64_t duration_ms = 0;
  bool has_next = false;
  bool has_artwork = false;  // false = artwork unchanged
  std::vector<uint8_t> artwork;
};

std::mutex g_update_m;
std::condition_variable g_update_cv;
std::optional<Update> g_pending;
bool g_stop = false;
std::thread g_worker;

void Apply(const Update& u) {
  auto smtc = g_smtc.get();
  if (!smtc) return;
  auto display = smtc.DisplayUpdater();

  if (u.clear) {
    smtc.PlaybackStatus(MediaPlaybackStatus::Closed);
    display.ClearAll();
    display.Update();
    smtc.IsEnabled(false);
    return;
  }

  smtc.IsEnabled(true);
  smtc.IsPlayEnabled(true);
  smtc.IsPauseEnabled(true);
  smtc.IsStopEnabled(true);
  smtc.IsPreviousEnabled(true);
  smtc.IsNextEnabled(u.has_next);
  smtc.PlaybackStatus(u.playing ? MediaPlaybackStatus::Playing
                                : MediaPlaybackStatus::Paused);

  display.Type(MediaPlaybackType::Music);
  auto music = display.MusicProperties();
  music.Title(winrt::to_hstring(u.title));
  music.Artist(winrt::to_hstring(u.artist));
  music.AlbumTitle(winrt::to_hstring(u.album));
  if (u.has_artwork) {
    if (u.artwork.empty()) {
      display.Thumbnail(nullptr);
    } else {
      InMemoryRandomAccessStream stream;
      DataWriter writer(stream);
      writer.WriteBytes(winrt::array_view<const uint8_t>(u.artwork));
      writer.StoreAsync().get();
      writer.DetachStream();
      stream.Seek(0);
      display.Thumbnail(RandomAccessStreamReference::CreateFromStream(stream));
    }
  }
  display.Update();

  const auto duration = std::chrono::milliseconds(u.duration_ms);
  SystemMediaTransportControlsTimelineProperties timeline;
  timeline.StartTime(std::chrono::milliseconds(0));
  timeline.MinSeekTime(std::chrono::milliseconds(0));
  timeline.Position(std::chrono::milliseconds(u.position_ms));
  timeline.MaxSeekTime(duration);
  timeline.EndTime(duration);
  smtc.UpdateTimelineProperties(timeline);
}

void WorkerMain() {
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  for (;;) {
    Update u;
    {
      std::unique_lock<std::mutex> lk(g_update_m);
      g_update_cv.wait(lk, [] { return g_stop || g_pending.has_value(); });
      if (g_stop) break;
      u = std::move(*g_pending);
      g_pending.reset();
    }
    try {
      Apply(u);
    } catch (...) {
    }
  }
  winrt::uninit_apartment();
}

// Only the latest state matters: a pending update is replaced, but
// artwork that was not sent yet is kept.
void Schedule(Update u) {
  {
    std::lock_guard<std::mutex> lk(g_update_m);
    if (g_pending && g_pending->has_artwork && !u.has_artwork && !u.clear) {
      u.has_artwork = true;
      u.artwork = std::move(g_pending->artwork);
    }
    g_pending = std::move(u);
  }
  g_update_cv.notify_one();
}

template <typename T>
std::optional<T> Arg(const EncodableMap& m, const char* key) {
  auto it = m.find(EncodableValue(key));
  if (it == m.end()) return std::nullopt;
  if (auto* v = std::get_if<T>(&it->second)) return *v;
  return std::nullopt;
}

int64_t IntArg(const EncodableMap& m, const char* key) {
  auto it = m.find(EncodableValue(key));
  if (it == m.end()) return 0;
  if (auto* v = std::get_if<int64_t>(&it->second)) return *v;
  if (auto* v = std::get_if<int32_t>(&it->second)) return *v;
  return 0;
}

Update ParseUpdate(const EncodableMap& m) {
  Update u;
  u.title = Arg<std::string>(m, "title").value_or("");
  u.artist = Arg<std::string>(m, "artist").value_or("");
  u.album = Arg<std::string>(m, "album").value_or("");
  u.playing = Arg<bool>(m, "isPlaying").value_or(false);
  u.has_next = Arg<bool>(m, "hasNext").value_or(false);
  u.position_ms = IntArg(m, "positionMs");
  u.duration_ms = IntArg(m, "durationMs");
  auto art = m.find(EncodableValue("artwork"));
  if (art != m.end()) {
    u.has_artwork = true;  // present but null = remove the artwork
    if (auto* bytes = std::get_if<std::vector<uint8_t>>(&art->second)) {
      u.artwork = *bytes;
    }
  }
  return u;
}

const char* ButtonName(SystemMediaTransportControlsButton b) {
  switch (b) {
    case SystemMediaTransportControlsButton::Play:
      return "play";
    case SystemMediaTransportControlsButton::Pause:
      return "pause";
    case SystemMediaTransportControlsButton::Stop:
      return "stop";
    case SystemMediaTransportControlsButton::Next:
      return "next";
    case SystemMediaTransportControlsButton::Previous:
      return "previous";
    default:
      return nullptr;
  }
}

}  // namespace

namespace media_session {

void Register(flutter::FlutterEngine* engine, HWND window) {
  EnsureMessageWindow();

  try {
    auto interop = winrt::get_activation_factory<
        SystemMediaTransportControls, ISystemMediaTransportControlsInterop>();
    winrt::check_hresult(interop->GetForWindow(
        window, winrt::guid_of<SystemMediaTransportControls>(),
        winrt::put_abi(g_smtc_ui)));
    g_smtc = winrt::make_agile(g_smtc_ui);
    // Sona stays out of Windows media controls until a playlist plays.
    g_smtc_ui.IsEnabled(false);

    g_tok_button = g_smtc_ui.ButtonPressed(
        [](auto const&,
           SystemMediaTransportControlsButtonPressedEventArgs const& args) {
          if (const char* name = ButtonName(args.Button())) {
            PostEvent("button", EncodableValue(std::string(name)));
          }
        });
    g_tok_seek = g_smtc_ui.PlaybackPositionChangeRequested(
        [](auto const&,
           PlaybackPositionChangeRequestedEventArgs const& args) {
          auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                        args.RequestedPlaybackPosition())
                        .count();
          PostEvent("seek", EncodableValue(static_cast<int64_t>(ms)));
        });
  } catch (...) {
    g_smtc_ui = nullptr;
    return;  // Sona works without SMTC, it's just not visible to Windows
  }

  g_stop = false;
  g_worker = std::thread(WorkerMain);

  g_channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), "sona/media_session",
      &flutter::StandardMethodCodec::GetInstance());
  g_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        if (call.method_name() == "update") {
          const auto* args = std::get_if<EncodableMap>(call.arguments());
          if (args) Schedule(ParseUpdate(*args));
          result->Success();
        } else if (call.method_name() == "clear") {
          Update u;
          u.clear = true;
          Schedule(std::move(u));
          result->Success();
        } else {
          result->NotImplemented();
        }
      });
}

void CleanUp() {
  {
    std::lock_guard<std::mutex> lk(g_update_m);
    g_stop = true;
    g_pending.reset();
  }
  g_update_cv.notify_all();
  if (g_worker.joinable()) g_worker.join();

  if (g_smtc_ui) {
    try {
      g_smtc_ui.ButtonPressed(g_tok_button);
      g_smtc_ui.PlaybackPositionChangeRequested(g_tok_seek);
      g_smtc_ui.IsEnabled(false);
    } catch (...) {
    }
    g_smtc_ui = nullptr;
  }
  g_smtc = nullptr;
  g_channel.reset();

  if (g_msg_window != nullptr && IsWindow(g_msg_window)) {
    DestroyWindow(g_msg_window);
    g_msg_window = nullptr;
  }
}

}  // namespace media_session
