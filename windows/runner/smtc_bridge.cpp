#include "smtc_bridge.h"

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.Control.h>
#include <winrt/Windows.Storage.Streams.h>

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <memory>
#include <mutex>
#include <queue>
#include <string>
#include <thread>
#include <vector>

using namespace winrt;
using namespace winrt::Windows::Media::Control;
using namespace winrt::Windows::Storage::Streams;

using flutter::EncodableMap;
using flutter::EncodableValue;

namespace {

// Channels & Sinks
std::unique_ptr<flutter::MethodChannel<EncodableValue>> g_method_channel;
std::unique_ptr<flutter::EventChannel<EncodableValue>> g_event_channel;

std::mutex g_sink_mutex;
std::unique_ptr<flutter::EventSink<EncodableValue>> g_sink;

constexpr UINT WM_SMTC_UPDATE = WM_USER + 42;
HWND g_msg_window = nullptr;
std::mutex g_queue_mutex;
std::queue<EncodableValue> g_queue;

struct SmtcState {
  std::recursive_mutex m;
  GlobalSystemMediaTransportControlsSessionManager manager{nullptr};
  GlobalSystemMediaTransportControlsSession session{nullptr};
  winrt::event_token tokMedia{};
  winrt::event_token tokPlayback{};
  winrt::event_token tokTimeline{};
  winrt::event_token tokCurrent{};
};
SmtcState* g_state = nullptr;

std::thread g_worker;
std::atomic<bool> g_running{false};
std::mutex g_cv_m;
std::condition_variable g_cv;

std::vector<uint8_t> ReadThumbnail(IRandomAccessStreamReference const& ref) {
  std::vector<uint8_t> bytes;
  if (!ref) return bytes;
  try {
    auto stream = ref.OpenReadAsync().get();
    uint32_t size = static_cast<uint32_t>(stream.Size());
    if (size == 0) return bytes;
    Buffer buffer(size);
    stream.ReadAsync(buffer, size, InputStreamOptions::None).get();
    auto reader = DataReader::FromBuffer(buffer);
    bytes.resize(buffer.Length());
    if (!bytes.empty()) reader.ReadBytes(winrt::array_view<uint8_t>(bytes));
  } catch (...) {
  }
  return bytes;
}

bool RunCommand(const std::string& cmd, int64_t positionMs) {
  try {
    auto manager =
        GlobalSystemMediaTransportControlsSessionManager::RequestAsync().get();
    if (!manager) return false;
    auto session = manager.GetCurrentSession();
    if (!session) return false;

    if (cmd == "playPause") {
      return session.TryTogglePlayPauseAsync().get();
    } else if (cmd == "next") {
      return session.TrySkipNextAsync().get();
    } else if (cmd == "previous") {
      return session.TrySkipPreviousAsync().get();
    } else if (cmd == "seek") {
      int64_t ticks = positionMs * 10000;
      return session.TryChangePlaybackPositionAsync(ticks).get();
    }
    return false;
  } catch (...) {
    return false;
  }
}

EncodableValue BuildPayload(GlobalSystemMediaTransportControlsSession const& session) {
  if (!session) return EncodableValue();

  static std::mutex cache_m;
  static std::string cache_id;
  static std::vector<uint8_t> cache_thumb;

  try {
    auto props = session.TryGetMediaPropertiesAsync().get();
    auto playback = session.GetPlaybackInfo();
    auto timeline = session.GetTimelineProperties();

    bool playing =
        playback.PlaybackStatus() ==
        GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing;

    auto title = winrt::to_string(props.Title());
    auto artist = winrt::to_string(props.Artist());
    auto album = winrt::to_string(props.AlbumTitle());

    int64_t posMs = std::chrono::duration_cast<std::chrono::milliseconds>(
                        timeline.Position()).count();
    int64_t durMs = std::chrono::duration_cast<std::chrono::milliseconds>(
                        timeline.EndTime() - timeline.StartTime()).count();

    std::string id = title + "|" + artist + "|" + album;
    std::vector<uint8_t> thumb;
    {
      std::lock_guard<std::mutex> lk(cache_m);
      if (id == cache_id && !cache_thumb.empty()) thumb = cache_thumb;
    }
    if (thumb.empty()) {
      thumb = ReadThumbnail(props.Thumbnail());
      if (!thumb.empty()) {
        std::lock_guard<std::mutex> lk(cache_m);
        cache_id = id;
        cache_thumb = thumb;
      }
    }

    EncodableMap map;
    map[EncodableValue("title")] = EncodableValue(title);
    map[EncodableValue("artist")] = EncodableValue(artist);
    map[EncodableValue("album")] = EncodableValue(album);
    map[EncodableValue("isPlaying")] = EncodableValue(playing);
    map[EncodableValue("positionMs")] = EncodableValue(posMs);
    map[EncodableValue("durationMs")] = EncodableValue(durMs);
    map[EncodableValue("thumbnail")] = EncodableValue(thumb);
    return EncodableValue(map);
  } catch (...) {
    return EncodableValue();
  }
}

void Enqueue(EncodableValue value) {
  if (!g_running.load()) return;
  {
    std::lock_guard<std::mutex> lk(g_queue_mutex);
    g_queue.push(std::move(value));
  }
  if (g_msg_window != nullptr && IsWindow(g_msg_window)) {
    PostMessageW(g_msg_window, WM_SMTC_UPDATE, 0, 0);
  }
}

void DrainQueue() {
  std::queue<EncodableValue> local;
  {
    std::lock_guard<std::mutex> lk(g_queue_mutex);
    std::swap(local, g_queue);
  }
  std::lock_guard<std::mutex> lk(g_sink_mutex);
  if (!g_sink || !g_running.load()) return;
  while (!local.empty()) {
    try {
      g_sink->Success(local.front());
    } catch (...) {
    }
    local.pop();
  }
}

void EmitUpdate() {
  if (!g_running.load() || g_state == nullptr) return;
  GlobalSystemMediaTransportControlsSession sess{nullptr};
  {
    std::lock_guard<std::recursive_mutex> lk(g_state->m);
    sess = g_state->session;
  }
  if (sess && g_running.load()) {
    Enqueue(BuildPayload(sess));
  }
}

void DetachSession_nolock() {
  if (g_state && g_state->session) {
    try {
      if (g_state->tokMedia.value != 0) {
        g_state->session.MediaPropertiesChanged(g_state->tokMedia);
        g_state->tokMedia = {};
      }
      if (g_state->tokPlayback.value != 0) {
        g_state->session.PlaybackInfoChanged(g_state->tokPlayback);
        g_state->tokPlayback = {};
      }
      if (g_state->tokTimeline.value != 0) {
        g_state->session.TimelinePropertiesChanged(g_state->tokTimeline);
        g_state->tokTimeline = {};
      }
    } catch (...) {
    }
    g_state->session = nullptr;
  }
}

void OnSessionChanged() {
  if (!g_running.load() || !g_state) return;
  {
    std::lock_guard<std::recursive_mutex> lk(g_state->m);
    DetachSession_nolock();
    try {
      auto s = g_state->manager
                   ? g_state->manager.GetCurrentSession()
                   : GlobalSystemMediaTransportControlsSession{nullptr};
      g_state->session = s;
      if (s && g_running.load()) {
        g_state->tokMedia = s.MediaPropertiesChanged(
            [](auto const&, auto const&) { EmitUpdate(); });
        g_state->tokPlayback = s.PlaybackInfoChanged(
            [](auto const&, auto const&) { EmitUpdate(); });
        g_state->tokTimeline = s.TimelinePropertiesChanged(
            [](auto const&, auto const&) { EmitUpdate(); });
      }
    } catch (...) {
    }
  }
  EmitUpdate();
}

void WorkerMain() {
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  try {
    auto manager =
        GlobalSystemMediaTransportControlsSessionManager::RequestAsync().get();
    if (g_running.load() && g_state) {
      std::lock_guard<std::recursive_mutex> lk(g_state->m);
      g_state->manager = manager;
      if (manager) {
        g_state->tokCurrent = manager.CurrentSessionChanged(
            [](auto const&, auto const&) { OnSessionChanged(); });
      }
    }
    OnSessionChanged();
  } catch (...) {
  }

  {
    std::unique_lock<std::mutex> lk(g_cv_m);
    g_cv.wait(lk, [] { return !g_running.load(); });
  }

  // Cleanup
  try {
    if (g_state) {
      std::lock_guard<std::recursive_mutex> lk(g_state->m);
      DetachSession_nolock();
      if (g_state->manager) {
        if (g_state->tokCurrent.value != 0) {
          g_state->manager.CurrentSessionChanged(g_state->tokCurrent);
          g_state->tokCurrent = {};
        }
        g_state->manager = nullptr;
      }
    }
  } catch (...) {
  }
  winrt::uninit_apartment();
}

void StartListening(std::unique_ptr<flutter::EventSink<EncodableValue>>&& sink) {
  {
    std::lock_guard<std::mutex> lk(g_sink_mutex);
    g_sink = std::move(sink);
  }
  g_state = new SmtcState();
  g_running = true;
  g_worker = std::thread(WorkerMain);
}

void StopListening() {
  g_running = false;
  g_cv.notify_all();
  if (g_worker.joinable()) {
    try {
      g_worker.join();
    } catch (...) {
      g_worker.detach();
    }
  }

  {
    std::lock_guard<std::mutex> lk(g_sink_mutex);
    g_sink.reset();
  }

  {
    std::lock_guard<std::mutex> lk(g_queue_mutex);
    std::queue<EncodableValue> empty;
    std::swap(g_queue, empty);
  }

  SmtcState* old = g_state;
  g_state = nullptr;
  if (old) {
    delete old;
  }
}

LRESULT CALLBACK MsgWndProc(HWND hwnd, UINT msg, WPARAM w, LPARAM l) {
  if (msg == WM_SMTC_UPDATE) {
    DrainQueue();
    return 0;
  }
  return DefWindowProcW(hwnd, msg, w, l);
}

void EnsureMessageWindow() {
  if (g_msg_window) return;
  static const wchar_t* kClass = L"SmtcBridgeMsgWindow";
  static bool registered = false;
  if (!registered) {
    WNDCLASSW wc = {};
    wc.lpfnWndProc = MsgWndProc;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = kClass;
    RegisterClassW(&wc);
    registered = true;
  }
  g_msg_window = CreateWindowExW(0, kClass, L"", 0, 0, 0, 0, 0, HWND_MESSAGE,
                                 nullptr, GetModuleHandleW(nullptr), nullptr);
}

EncodableValue ReadCurrentOnce() {
  try {
    auto manager =
        GlobalSystemMediaTransportControlsSessionManager::RequestAsync().get();
    if (!manager) return EncodableValue();
    return BuildPayload(manager.GetCurrentSession());
  } catch (...) {
    return EncodableValue();
  }
}

}  // namespace

namespace smtc_bridge {
void Register(flutter::FlutterEngine* engine) {
  EnsureMessageWindow();

  g_method_channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), "sona/smtc",
      &flutter::StandardMethodCodec::GetInstance());

  g_method_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        const std::string& method = call.method_name();

        if (call.method_name() == "getCurrentMedia") {
          auto shared = std::shared_ptr<flutter::MethodResult<EncodableValue>>(
              result.release());
          std::thread([shared]() {
            winrt::init_apartment(winrt::apartment_type::multi_threaded);
            EncodableValue data = ReadCurrentOnce();
            winrt::uninit_apartment();
            try {
              shared->Success(data);
            } catch (...) {
            }
          }).detach();
        } else if (method == "playPause" || method == "next" ||
                   method == "previous" || method == "seek") {
          int64_t positionMs = 0;
          if (method == "seek") {
            const auto* args = std::get_if<EncodableMap>(call.arguments());
            if (args) {
              auto it = args->find(EncodableValue("positionMs"));
              if (it != args->end()) {
                if (auto* v = std::get_if<int64_t>(&it->second)) {
                  positionMs = *v;
                } else if (auto* v32 = std::get_if<int32_t>(&it->second)) {
                  positionMs = *v32;
                }
              }
            }
          }
          std::string cmd = method;
          auto shared = std::shared_ptr<flutter::MethodResult<EncodableValue>>(
              result.release());
          std::thread([shared, cmd, positionMs]() {
            winrt::init_apartment(winrt::apartment_type::multi_threaded);
            bool ok = RunCommand(cmd, positionMs);
            winrt::uninit_apartment();
            try {
              shared->Success(EncodableValue(ok));
            } catch (...) {
            }
          }).detach();
        } else {
          result->NotImplemented();
        }
      });

  g_event_channel = std::make_unique<flutter::EventChannel<EncodableValue>>(
      engine->messenger(), "sona/smtc/events",
      &flutter::StandardMethodCodec::GetInstance());

  auto handler =
      std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
          [](const EncodableValue* args,
             std::unique_ptr<flutter::EventSink<EncodableValue>>&& events)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            StartListening(std::move(events));
            return nullptr;
          },
          [](const EncodableValue* args)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            StopListening();
            return nullptr;
          });

  g_event_channel->SetStreamHandler(std::move(handler));
}
}  // namespace smtc_bridge