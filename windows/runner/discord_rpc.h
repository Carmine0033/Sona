#ifndef DISCORD_RPC_H_
#define DISCORD_RPC_H_

#include <flutter/flutter_engine.h>

// Discord Rich Presence over local IPC (discord-ipc-N named pipe), no SDK.
// Channel "sona/discord": start(clientId), setActivity(json), clear.
namespace discord_rpc {
void Register(flutter::FlutterEngine* engine);
void Shutdown();
}  // namespace discord_rpc

#endif
