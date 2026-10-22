#include "single_instance.h"

namespace single_instance {
    namespace {
        #ifdef _DEBUG
        constexpr wchar_t kMutexName[] = L"SonaSingleInstanceMutex-Debug";
        constexpr wchar_t kShowMessage[] = L"Sona.ShowExistingWindow-Debug";
        #else
        constexpr wchar_t kMutexName[] = L"SonaSingleInstanceMutex";
        constexpr wchar_t kShowMessage[] = L"Sona.ShowExistingWindow";
        #endif

        HANDLE g_mutex= nullptr;
    }

    // The release mutex name is also Inno Setup's AppMutex (sona.iss): the
    // installer sees Sona running and asks to close it. The handle stays
    // open for the whole process lifetime on purpose.
    bool Acquire() {
        g_mutex = CreateMutexW(nullptr, FALSE, kMutexName);
        if (g_mutex == nullptr) return true;  // can't tell: better start than not
        return GetLastError() != ERROR_ALREADY_EXISTS;
    }

    UINT ShowMessageId() {
        static const UINT id = RegisterWindowMessageW(kShowMessage);
        return id;
    }

    // We are the process the user just launched, so we may hand the
    // foreground right to the running instance before asking it to show up.
    void ActivateExisting() {
        AllowSetForegroundWindow(ASFW_ANY);
        PostMessageW(HWND_BROADCAST, ShowMessageId(), 0, 0);
    }

    void BringToFront(HWND hwnd) {
        if (!IsWindowVisible(hwnd)) ShowWindow(hwnd, SW_SHOW);
        if (IsIconic(hwnd)) ShowWindow(hwnd, SW_RESTORE);  // was minimized
        if (!SetForegroundWindow(hwnd)) {
            FlashWindow(hwnd, TRUE);
        }
    }
}