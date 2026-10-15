#include "discord_rpc.h"

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace discord_rpc {
namespace {

constexpr int32_t kHandshake = 0;
constexpr int32_t kFrame = 1;
constexpr int32_t kClose = 2;
constexpr int32_t kPing = 3;
constexpr int32_t kPong = 4;

// All pipe I/O runs on the worker; the UI thread only stores the latest
// activity (coalescing) and wakes it up.
class Client {
 public:
  ~Client() { Stop(); }

  void Start(std::string client_id) {
    std::lock_guard<std::mutex> lock(mu_);
    client_id_ = std::move(client_id);
    if (!worker_.joinable()) {
      running_ = true;
      worker_ = std::thread([this] { Loop(); });
    }
  }

  // An empty activity_json clears the presence.
  void SetActivity(std::string activity_json) {
    {
      std::lock_guard<std::mutex> lock(mu_);
      pending_ = std::move(activity_json);
      has_pending_ = true;
    }
    cv_.notify_one();
  }

  void Stop() {
    {
      std::lock_guard<std::mutex> lock(mu_);
      running_ = false;
    }
    cv_.notify_one();
    if (worker_.joinable()) {
      // Unblock a ReadFile stuck in the handshake (Discord hung),
      // otherwise closing the app would hang on join().
      CancelSynchronousIo(worker_.native_handle());
      worker_.join();
    }
  }

 private:
  void Loop() {
    std::string last;
    bool dirty = false;
    for (;;) {
      std::string client_id;
      {
        std::unique_lock<std::mutex> lock(mu_);
        // Every 15 s: retry the connection and check the pipe.
        cv_.wait_for(lock, std::chrono::seconds(15),
                     [this] { return !running_ || has_pending_; });
        if (!running_) break;
        if (has_pending_) {
          last = pending_;
          has_pending_ = false;
          dirty = true;
        }
        client_id = client_id_;
      }

      if (pipe_ == INVALID_HANDLE_VALUE) {
        if (last.empty() || client_id.empty() || !Connect(client_id)) continue;
        dirty = true;
      }
      if (dirty) {
        if (Send(kFrame, BuildCommand(last))) {
          dirty = false;
        } else {
          ClosePipe();  // retry on the next round
        }
      }
      Drain();
    }

    if (pipe_ != INVALID_HANDLE_VALUE) {
      Send(kFrame, BuildCommand(""));
      ClosePipe();
    }
  }

  bool Connect(const std::string& client_id) {
    for (int i = 0; i < 10; ++i) {
      const std::wstring name =
          L"\\\\.\\pipe\\discord-ipc-" + std::to_wstring(i);
      HANDLE h = CreateFileW(name.c_str(), GENERIC_READ | GENERIC_WRITE, 0,
                             nullptr, OPEN_EXISTING, 0, nullptr);
      if (h == INVALID_HANDLE_VALUE) continue;
      pipe_ = h;
      if (Send(kHandshake,
               "{\"v\":1,\"client_id\":\"" + client_id + "\"}") &&
          ReadReady()) {
        return true;
      }
      ClosePipe();
    }
    return false;
  }

  bool Send(int32_t op, const std::string& payload) {
    if (pipe_ == INVALID_HANDLE_VALUE) return false;
    const int32_t len = static_cast<int32_t>(payload.size());
    std::vector<char> buf(8 + payload.size());
    // x86/x64 are little-endian, as the protocol requires.
    std::memcpy(buf.data(), &op, 4);
    std::memcpy(buf.data() + 4, &len, 4);
    std::memcpy(buf.data() + 8, payload.data(), payload.size());
    DWORD written = 0;
    return WriteFile(pipe_, buf.data(), static_cast<DWORD>(buf.size()),
                     &written, nullptr) &&
           written == buf.size();
  }

  bool ReadExact(void* out, DWORD n) {
    auto* p = static_cast<char*>(out);
    while (n > 0) {
      DWORD r = 0;
      if (!ReadFile(pipe_, p, n, &r, nullptr) || r == 0) return false;
      p += r;
      n -= r;
    }
    return true;
  }

  bool ReadFrame(int32_t& op, std::string& data) {
    int32_t hdr[2];
    if (!ReadExact(hdr, 8)) return false;
    op = hdr[0];
    if (hdr[1] < 0 || hdr[1] > (1 << 20)) return false;  // corrupted data
    data.resize(hdr[1]);
    return hdr[1] == 0 || ReadExact(data.data(), static_cast<DWORD>(hdr[1]));
  }

  bool ReadReady() {
    int32_t op = 0;
    std::string data;
    return ReadFrame(op, data) && op == kFrame &&
           data.find("\"READY\"") != std::string::npos;
  }

  // Reads pending replies (SET_ACTIVITY acks, pings) without blocking.
  void Drain() {
    while (pipe_ != INVALID_HANDLE_VALUE) {
      DWORD avail = 0;
      if (!PeekNamedPipe(pipe_, nullptr, 0, nullptr, &avail, nullptr)) {
        ClosePipe();  // Discord was closed
        return;
      }
      if (avail < 8) return;
      int32_t op = 0;
      std::string data;
      if (!ReadFrame(op, data) || op == kClose) {
        ClosePipe();
        return;
      }
      if (op == kPing) Send(kPong, data);
    }
  }

  std::string BuildCommand(const std::string& activity) {
    return "{\"cmd\":\"SET_ACTIVITY\",\"args\":{\"pid\":" +
           std::to_string(GetCurrentProcessId()) +
           (activity.empty() ? "" : ",\"activity\":" + activity) +
           "},\"nonce\":\"" + std::to_string(++nonce_) + "\"}";
  }

  void ClosePipe() {
    if (pipe_ != INVALID_HANDLE_VALUE) {
      CloseHandle(pipe_);
      pipe_ = INVALID_HANDLE_VALUE;
    }
  }

  std::mutex mu_;
  std::condition_variable cv_;
  std::thread worker_;
  bool running_ = false;
  bool has_pending_ = false;
  std::string pending_;
  std::string client_id_;
  HANDLE pipe_ = INVALID_HANDLE_VALUE;  // worker thread only
  uint64_t nonce_ = 0;
};

std::unique_ptr<Client> g_client;
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_channel;

}  // namespace

void Register(flutter::FlutterEngine* engine) {
  g_client = std::make_unique<Client>();
  g_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "sona/discord",
      &flutter::StandardMethodCodec::GetInstance());

  g_channel->SetMethodCallHandler([](const auto& call, auto result) {
    if (!g_client) {
      result->Success();
      return;
    }
    const auto* arg = std::get_if<std::string>(call.arguments());
    const auto& m = call.method_name();
    if (m == "start" && arg) {
      g_client->Start(*arg);
    } else if (m == "setActivity" && arg) {
      g_client->SetActivity(*arg);
    } else if (m == "clear") {
      g_client->SetActivity("");
    } else {
      result->NotImplemented();
      return;
    }
    result->Success();
  });
}

void Shutdown() {
  if (g_channel) g_channel->SetMethodCallHandler(nullptr);
  g_client.reset();  // Stop(): clears the presence and closes the pipe
  g_channel.reset();
}

}  // namespace discord_rpc
