const std = @import("std");
const os = std.os;
const io = std.io;

/// ReadMode defines the read behaivour when using raw mode
pub const ReadMode = enum {
    blocking,
    nonblocking,
};

pub fn enableRawMode(handle: os.system.fd_t, blocking: ReadMode) !RawTerm {
    // var original_termios = try os.tcgetattr(handle);
    var original_termios = try os.tcgetattr(handle);

    var termios = original_termios;

    // https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html
    // All of this are bitflags, so we do NOT and then AND to disable

    // ICRNL (iflag) : fix CTRL-M (carriage returns)
    // IXON (iflag)  : disable Ctrl-S and Ctrl-Q

    // OPOST (oflag) : turn off all output processing

    // ECHO (lflag)  : disable prints every key to terminal
    // ICANON (lflag): disable to reads byte per byte instead of line (or when user press enter)
    // IEXTEN (lflag): disable Ctrl-V
    // ISIG (lflag)  : disable Ctrl-C and Ctrl-Z

    // Miscellaneous flags (most modern terminal already have them disabled)
    // BRKINT, INPCK, ISTRIP and CS8

    termios.iflag &= ~(os.system.BRKINT | os.system.ICRNL | os.system.INPCK | os.system.ISTRIP | os.system.IXON);
    termios.oflag &= ~(os.system.OPOST);
    termios.cflag |= (os.system.CS8);
    termios.lflag &= ~(os.system.ECHO | os.system.ICANON | os.system.IEXTEN | os.system.ISIG);

    switch (blocking) {
        // Wait until it reads at least one byte
        .blocking => termios.cc[os.system.V.MIN] = 1,

        // Don't wait
        .nonblocking => termios.cc[os.system.V.MIN] = 0,
    }

    // Wait 100 miliseconds at maximum.
    termios.cc[os.system.V.TIME] = 1;

    // apply changes
    try os.tcsetattr(handle, .FLUSH, termios);

    return RawTerm{
        .orig_termios = original_termios,
        .handle = handle,
    };
}

/// A raw terminal representation, you can enter terminal raw mode
/// using this struct. Raw mode is essential to create a TUI.
pub const RawTerm = struct {
    orig_termios: os.termios,

    /// The OS-specific file descriptor or file handle.
    handle: os.system.fd_t,

    const Self = @This();

    /// Returns to the previous terminal state
    pub fn disableRawMode(self: *Self) !void {
        try os.tcsetattr(self.handle, .FLUSH, self.orig_termios);
    }
};

/// Returned by `getSize()`
pub const TermSize = struct {
    width: u16,
    height: u16,
};

/// Get the terminal size, use `fd` equals to 0 use stdin
pub fn getSize(fd: std.os.fd_t) !TermSize {
    var ws: std.os.system.winsize = undefined;

    // https://github.com/ziglang/zig/blob/master/lib/std/os/linux/errno/generic.zig
    const err = std.c.ioctl(fd, os.system.T.IOCGWINSZ, @ptrToInt(&ws));
    if (std.os.errno(err) != .SUCCESS) {
        return error.IoctlError;
    }

    return TermSize{
        .width = ws.ws_col,
        .height = ws.ws_row,
    };
}

test "entering stdin raw mode" {
    const stdin = io.getStdIn();

    var term = try enableRawMode(stdin.handle, .blocking); // stdin.handle is the same as os.STDIN_FILENO
    defer term.disableRawMode() catch {};
}
