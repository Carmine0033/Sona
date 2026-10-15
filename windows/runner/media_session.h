#ifndef MEDIA_SESSION_H_
#define MEDIA_SESSION_H_

#include <flutter/flutter_engine.h>
#include <windows.h>

// Publishes Sona's internal (playlist) playback to Windows media controls
// (SMTC): volume flyout, media keys and the detached mini player, which
// reads SMTC from a separate process.
namespace media_session {
void Register(flutter::FlutterEngine* engine, HWND window);
void CleanUp();
}  // namespace media_session

#endif
