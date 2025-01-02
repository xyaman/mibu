const std = @import("std");
const os = std.os;
const io = std.io;
const posix = std.posix;
const windows = std.os.windows;

const utils = @import("utils.zig");

const builtin = @import("builtin");

pub const ensureWindowsVTS = utils.ensureWindowsVTS;

pub fn enableRawMode(handle: posix.fd_t) !RawTerm {
    const original_termios = try posix.tcgetattr(handle);

    var termios = original_termios;

    // https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html
    // TCSETATTR(3)
    // reference: void cfmakeraw(struct termios *t)

    termios.iflag.BRKINT = false;
    termios.iflag.ICRNL = false;
    termios.iflag.INPCK = false;
    termios.iflag.ISTRIP = false;
    termios.iflag.IXON = false;

    termios.oflag.OPOST = false;

    termios.lflag.ECHO = false;
    termios.lflag.ICANON = false;
    termios.lflag.IEXTEN = false;
    termios.lflag.ISIG = false;

    termios.cflag.CSIZE = .CS8;

    termios.cc[@intFromEnum(posix.V.MIN)] = 1;
    termios.cc[@intFromEnum(posix.V.TIME)] = 0;

    // apply changes
    try posix.tcsetattr(handle, .FLUSH, termios);

    return RawTerm{
        .orig_termios = original_termios,
        .handle = handle,
    };
}

/// A raw terminal representation, you can enter terminal raw mode
/// using this struct. Raw mode is essential to create a TUI.
pub const RawTerm = struct {
    orig_termios: std.posix.termios,

    /// The OS-specific file descriptor or file handle.
    handle: os.linux.fd_t,

    const Self = @This();

    /// Returns to the previous terminal state
    pub fn disableRawMode(self: *Self) !void {
        try posix.tcsetattr(self.handle, .FLUSH, self.orig_termios);
    }
};

/// Returned by `getSize()`
pub const TermSize = struct {
    width: u16,
    height: u16,
};

/// Get the terminal size, use `fd` equals to 0 use stdin
pub fn getSize(handle: std.fs.File.Handle) !TermSize {
    switch (builtin.os.tag) {
        .linux => return getSizePosix(handle),
        .macos => return getSizePosix(handle),
        .windows => return getSizeWindows(handle),
        else => return error.UnsupportedPlatform,
    }
}

fn getSizePosix(fd: posix.fd_t) !TermSize {
    var ws: posix.winsize = undefined;

    // tty_ioctl(4)
    const err = std.posix.system.ioctl(fd, posix.T.IOCGWINSZ, @intFromPtr(&ws));
    if (posix.errno(err) != .SUCCESS) {
        return error.IoctlError;
    }

    return TermSize{
        .width = ws.col,
        .height = ws.row,
    };
}

fn getSizeWindows(handle: windows.HANDLE) !TermSize {
    const csbi = try utils.GetConsoleScreenBufferInfoWinApi(handle);

    return TermSize{
        .width = @intCast(csbi.srWindow.Right - csbi.srWindow.Left + 1),
        .height = @intCast(csbi.srWindow.Bottom - csbi.srWindow.Top + 1),
    };
}
/// Switches to an alternate screen mode in the console.
/// `out`: needs to be writer
pub fn enterAlternateScreen(out: anytype) !void {
    try out.print("{s}", .{utils.comptimeCsi("?1049h", .{})});
}

/// Returns the console to its normal screen mode after using the alternate screen mode.
/// `out`: needs to be writer
pub fn exitAlternateScreen(out: anytype) !void {
    try out.print("{s}", .{utils.comptimeCsi("?1049l", .{})});
}

test "entering stdin raw mode" {
    const tty = (try std.fs.cwd().openFile("/dev/tty", .{})).reader();

    const termsize = try getSize(tty.context.handle);
    std.debug.print("Terminal size: {d}x{d}\n", .{ termsize.width, termsize.height });

    // stdin.handle is the same as os.STDIN_FILENO
    // var term = try enableRawMode(tty.context.handle, .blocking);
    // defer term.disableRawMode() catch {};
}
