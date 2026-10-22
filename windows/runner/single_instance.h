#pragma once
#include <windows.h>

namespace single_instance
{
    bool Acquire();
    void ActivateExisting();
    UINT ShowMessageId();
    void BringToFront(HWND hwnd);
} // namespace single_instance