const windows = @import("std").os.windows;
const kernel32 = windows.kernel32;

pub const ENABLE_PROCESSED_OUTPUT: windows.DWORD = 0x0001;
pub const ENABLE_VIRTUAL_TERMINAL_PROCESSING: windows.DWORD = 0x0004;
pub const ENABLE_WINDOW_INPUT: windows.DWORD = 0x0008;
pub const ENABLE_MOUSE_INPUT: windows.DWORD = 0x0010;
pub const ENABLE_VIRTUAL_TERMINAL_INPUT: windows.DWORD = 0x0200;

pub const DISABLE_NEWLINE_AUTO_RETURN: windows.DWORD = 0x0008;

pub fn GetConsoleMode(handle: windows.HANDLE) !windows.DWORD {
    var mode: windows.DWORD = 0;
    if (kernel32.GetConsoleMode(handle, &mode) == 0) {
        switch (kernel32.GetLastError()) {
            else => |err| return windows.unexpectedError(err),
        }
    }
    return mode;
}

pub fn SetConsoleMode(handle: windows.HANDLE, mode: windows.DWORD) !void {
    if (kernel32.SetConsoleMode(handle, mode) == 0) {
        switch (kernel32.GetLastError()) {
            else => |err| return windows.unexpectedError(err),
        }
    }
}

pub fn GetConsoleScreenBufferInfo(handle: windows.HANDLE) !windows.CONSOLE_SCREEN_BUFFER_INFO {
    var csbi: windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    if (kernel32.GetConsoleScreenBufferInfo(handle, &csbi) == 0) {
        switch (kernel32.GetLastError()) {
            else => |err| return windows.unexpectedError(err),
        }
    }
    return csbi;
}
