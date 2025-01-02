const windows = @import("std").os.windows;
const kernel32 = windows.kernel32;

extern "kernel32" fn SetConsoleMode(
    hConsoleOutput: windows.HANDLE,
    dwMode: windows.DWORD,
) callconv(windows.WINAPI) windows.BOOL;

extern "kernel32" fn GetConsoleMode(
    hConsoleOutput: windows.HANDLE,
    dwMode: *windows.DWORD,
) callconv(windows.WINAPI) windows.BOOL;

extern "kernel32" fn GetConsoleScreenBufferInfo(
    hConsoleOutput: windows.HANDLE,
    lpConsoleScreenBufferInfo: *windows.CONSOLE_SCREEN_BUFFER_INFO,
) callconv(windows.WINAPI) windows.BOOL;

pub const ENABLE_PROCESSED_OUTPUT: windows.DWORD = 0x0001;
pub const ENABLE_VIRTUAL_TERMINAL_PROCESSING: windows.DWORD = 0x0004;

pub fn GetConsoleModeWinApi(handle: windows.HANDLE) !windows.DWORD {
    var mode: windows.DWORD = 0;
    if (GetConsoleMode(handle, &mode) == 0) {
        switch (kernel32.GetLastError()) {
            else => |err| return windows.unexpectedError(err),
        }
    }
    return mode;
}

pub fn SetConsoleModeWinApi(handle: windows.HANDLE, mode: windows.DWORD) !void {
    if (SetConsoleMode(handle, mode) == 0) {
        switch (kernel32.GetLastError()) {
            else => |err| return windows.unexpectedError(err),
        }
    }
}

pub fn GetConsoleScreenBufferInfoWinApi(handle: windows.HANDLE) !windows.CONSOLE_SCREEN_BUFFER_INFO {
    var csbi: windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    if (GetConsoleScreenBufferInfo(handle, &csbi) == 0) {
        switch (kernel32.GetLastError()) {
            else => |err| return windows.unexpectedError(err),
        }
    }
    return csbi;
}
