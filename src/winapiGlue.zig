const std = @import("std");
const builtin = @import("builtin");
const windows = std.os.windows;
const kernel32 = windows.kernel32;

pub const ENABLE_PROCESSED_OUTPUT: windows.DWORD = 0x0001;
pub const ENABLE_VIRTUAL_TERMINAL_PROCESSING: windows.DWORD = 0x0004;
pub const ENABLE_WINDOW_INPUT: windows.DWORD = 0x0008;
pub const ENABLE_MOUSE_INPUT: windows.DWORD = 0x0010;
pub const ENABLE_QUICK_EDIT_MODE: windows.DWORD = 0x0040;
pub const ENABLE_VIRTUAL_TERMINAL_INPUT: windows.DWORD = 0x0200;
pub const ENABLE_EXTENDED_FLAGS: windows.DWORD = 0x0080;

pub const DISABLE_NEWLINE_AUTO_RETURN: windows.DWORD = 0x0008;

// https://learn.microsoft.com/en-us/windows/console/getconsolemode
pub fn getConsoleMode(handle: windows.HANDLE) !windows.DWORD {
    var mode: windows.DWORD = 0;

    // nonzero value means success
    if (kernel32.GetConsoleMode(handle, &mode) == 0) {
        const err = kernel32.GetLastError();
        return windows.unexpectedError(err);
    }

    return mode;
}

pub fn setConsoleMode(handle: windows.HANDLE, mode: windows.DWORD) !void {
    // nonzero value means success
    if (kernel32.SetConsoleMode(handle, mode) == 0) {
        const err = kernel32.GetLastError();
        return windows.unexpectedError(err);
    }
}

pub fn getConsoleScreenBufferInfo(handle: windows.HANDLE) !windows.CONSOLE_SCREEN_BUFFER_INFO {
    var csbi: windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    if (kernel32.GetConsoleScreenBufferInfo(handle, &csbi) == 0) {
        const err = kernel32.GetLastError();
        return windows.unexpectedError(err);
    }
    return csbi;
}

pub const KEY_EVENT = 0x0001;
pub const MOUSE_EVENT = 0x0002;
pub const WINDOW_BUFFER_SIZE_EVENT = 0x0004;

pub const RIGHT_ALT_PRESSED = 0x0001;
pub const LEFT_ALT_PRESSED = 0x0002;
pub const RIGHT_CTRL_PRESSED = 0x0004;
pub const LEFT_CTRL_PRESSED = 0x0008;
pub const SHIFT_PRESSED = 0x0010;

pub const FROM_LEFT_1ST_BUTTON_PRESSED = 0x0001;
pub const FROM_LEFT_2ND_BUTTON_PRESSED = 0x0004;
pub const RIGHTMOST_BUTTON_PRESSED = 0x0002;

pub const MOUSE_MOVED = 0x0001;
pub const MOUSE_WHEELED = 0x0004;

pub const INPUT_RECORD = extern struct {
    EventType: windows.WORD,
    Event: extern union {
        KeyEvent: extern struct {
            bKeyDown: windows.BOOL,
            wRepeatCount: windows.WORD,
            wVirtualKeyCode: windows.WORD,
            wVirtualScanCode: windows.WORD,
            uChar: extern union {
                UnicodeChar: windows.WCHAR,
                AsciiChar: windows.CHAR,
            },
            dwControlKeyState: windows.DWORD,
        },
        MouseEvent: extern struct {
            dwMousePosition: windows.COORD,
            dwButtonState: windows.DWORD,
            dwControlKeyState: windows.DWORD,
            dwEventFlags: windows.DWORD,
        },
        WindowBufferSizeEvent: extern struct {
            dwSize: windows.COORD,
        },
        MenuEvent: extern struct {
            dwCommandId: windows.UINT,
        },
        FocusEvent: extern struct {
            bSetFocus: windows.BOOL,
        },
    },
};
pub const LPDWORD = [*c]windows.DWORD;

pub extern "kernel32" fn ReadConsoleInputW(
    console_input: windows.HANDLE,
    buffer: [*]INPUT_RECORD,
    length: windows.DWORD,
    number_of_events_read: LPDWORD,
) windows.BOOL;

pub const VK_CONTROL = 0x11;
pub const VK_SHIFT = 0x10;
pub const VK_MENU = 0x12;

pub const HKL = extern struct { unused: c_int };

pub extern "user32" fn GetKeyboardLayout(idThread: windows.DWORD) [*c]HKL;
pub extern "user32" fn ToUnicodeEx(
    wVirtKey: windows.UINT,
    wScanCode: windows.UINT,
    lpKeyState: [*c]const windows.BYTE,
    pwszBuff: windows.LPWSTR,
    cchBuff: c_int,
    wFlags: windows.UINT,
    dwhkl: [*c]HKL,
) c_int;

pub fn vkToUnicode(vk: windows.WORD, scan_code: windows.DWORD, ctrl_state: windows.DWORD) windows.WCHAR {
    var state: [256]u8 = [_]u8{0} ** 256;
    var keyboard_state: [*c]u8 = @ptrCast(state[0..]);
    keyboard_state[vk] |= 0x80;

    if (ctrl_state & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED) == 1) {
        keyboard_state[VK_CONTROL] |= 0x80;
    }
    if (ctrl_state & SHIFT_PRESSED == 1) {
        keyboard_state[VK_SHIFT] |= 0x80;
    }

    if (ctrl_state & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED) == 1) {
        keyboard_state[VK_MENU] |= 0x80;
    }

    const layout = GetKeyboardLayout(0);

    var buf: [5]windows.WCHAR = [_]windows.WCHAR{0} ** 5;
    const n = ToUnicodeEx(vk, scan_code, keyboard_state, @ptrCast(&buf), 4, 0, layout);
    return if (n > 0) buf[0] else 0;
}
