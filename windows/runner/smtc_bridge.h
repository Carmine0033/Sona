#ifndef SMTC_BRIDGE_H_
#define SMTC_BRIDGE_H_

#include <flutter/flutter_engine.h>



namespace smtc_bridge {
    // ignore_self: true in the main window (see smtc_bridge.cpp).
    void Register(flutter::FlutterEngine* engine, bool ignore_self);
    void CleanUp();
}

#endif

