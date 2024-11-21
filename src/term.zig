const std = @import("std");
const os = std.os;
const io = std.io;
const posix = std.posix;

const builtin = @import("builtin");

pub fn enableRawMode(handle: posix.fd_t) !RawTerm {
    const original_termios = try posix.tcgetattr(handle);

    var termios = original_termios;

    // https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html
    // TCSETATTR(3)
    // #define _GNU_SOURCE
    // #include <termios.h>
    //
    // void cfmakeraw(struct termios *t)
    // {
    // 	t->c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL|IXON);
    // 	t->c_oflag &= ~OPOST;
    // 	t->c_lflag &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);
    // 	t->c_cflag &= ~(CSIZE|PARENB);
    // 	t->c_cflag |= CS8;
    // 	t->c_cc[VMIN] = 1;
    // 	t->c_cc[VTIME] = 0;
    // }

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
pub fn getSize(fd: posix.fd_t) !TermSize {
    if (builtin.os.tag != .linux and builtin.os.tag != .macos) {
        return error.UnsupportedPlatform;
    }

    var ws: posix.winsize = undefined;

    // tty_ioctl(4)
    const err = std.posix.system.ioctl(fd, posix.T.IOCGWINSZ, @intFromPtr(&ws));
    if (posix.errno(err) != .SUCCESS) {
        return error.IoctlError;
    }

    return TermSize{
        .width = ws.ws_col,
        .height = ws.ws_row,
    };
}

test "entering stdin raw mode" {
    const tty = (try std.fs.cwd().openFile("/dev/tty", .{})).reader();

    const termsize = try getSize(tty.context.handle);
    std.debug.print("Terminal size: {d}x{d}\n", .{ termsize.width, termsize.height });

    // stdin.handle is the same as os.STDIN_FILENO
    // var term = try enableRawMode(tty.context.handle, .blocking);
    // defer term.disableRawMode() catch {};
}
