const std = @import("std");
const os = std.os;
const io = std.io;

const winsize = std.os.linux.winsize;

const TIOCGWINSZ = 0x5413; // only for linux
pub const TermSize = struct {
    width: u16,
    height: u16,
};

/// A raw terminal representation, you can enter terminal raw mode
/// using this struct. Raw mode is essential to create a TUI.
pub const RawTerm = struct {
    orig_termios: os.termios,

    /// The OS-specific file descriptor or file handle.
    handle: os.system.fd_t,

    // in: io.Reader,
    // out: io.Writer,

    const Self = @This();

    /// Enters to Raw Mode, don't forget to run `disableRawMode`
    /// at the end, to return to the previous terminal state.
    pub fn enableRawMode(handle: os.system.fd_t) !Self {
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

        // Add timeout to input
        // I don't know if this will be compatible with other platforms
        // I couldn't find this constants on other place
        termios.cc[os.system.V.MIN] = 0;
        termios.cc[os.system.V.TIME] = 1;

        // apply changes
        try os.tcsetattr(handle, .FLUSH, termios);

        return Self{
            .orig_termios = original_termios,
            .handle = handle,
        };
    }

    pub fn disableRawMode(self: *Self) !void {
        try os.tcsetattr(self.handle, .FLUSH, self.orig_termios);
    }
};

pub fn getSize() !TermSize {
    var ws: winsize = undefined;

    // https://github.com/ziglang/zig/blob/master/lib/std/os/linux/errno/generic.zig
    const err = std.os.linux.ioctl(0, TIOCGWINSZ, @ptrToInt(&ws));
    if (std.os.errno(err) != .SUCCESS) {
        return error.IoctlError;
    }

    return TermSize{
        .width = ws.ws_col,
        .height = ws.ws_row,
    };
}

test "" {
    const stdin = io.getStdIn();
    // actually the same as os.STDIN_FILENO

    var term = try RawTerm.enableRawMode(stdin.handle);
    defer term.disableRawMode() catch unreachable;

    var stdin_reader = stdin.reader();
    var buf: [1]u8 = undefined;

    while ((try stdin_reader.read(&buf)) != 0) {
        std.debug.print("read: {s}\n\r", .{buf});
    }
}
