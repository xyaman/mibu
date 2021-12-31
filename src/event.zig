const std = @import("std");
const io = std.io;

/// Returns the next event received.
/// If raw term is `.blocking` or term is canonical it will block until read at least one event.
/// otherwise it will return `.none` if it didnt read any event
pub fn next(in: anytype) !Event {
    var buf: [6]u8 = undefined;
    const c = try in.read(&buf);
    if (c == 0) {
        return .none;
    }

    // check if it is an special character
    // its on a different switch because its included on ctrl arm
    switch (buf[0]) {
        '\x7F' => return Event{ .key = .backspace },
        '\t' => return Event{ .key = .horizontal_tab },
        '\n' => return Event{ .key = .new_line },
        '\r' => return Event{ .key = .enter },
        else => {},
    }

    const key = switch (buf[0]) {
        '\x1b' => {
            switch (buf[1]) {
                // can be fn (1 - 4)
                'O' => {
                    return Event{ .key = Key{ .fun = (1 + buf[2] - 'P') } };
                },

                // csi
                '[' => {
                    // std.debug.print("\n\r{s}", .{buf[1..]});
                    return try parse_csi(&buf);
                },

                else => {
                    return Event{ .key = .escape };
                },
            }
        },
        // ctrl arm
        '\x01'...'\x1A' => Event{ .key = Key{ .ctrl = buf[0] - 0x1 + 'a' } },
        '\x1C'...'\x1F' => Event{ .key = Key{ .ctrl = buf[0] - 0x1C + '4' } },
        // chars
        else => Event{ .key = Key{ .char = buf[0..c] } },
    };

    return key;
}

fn parse_csi(buf: []const u8) !Event {

    // so we skip the first 2 chars (\x1b[)
    switch (buf[2]) {
        // keys
        'A' => return Event{ .key = .up },
        'B' => return Event{ .key = .down },
        'C' => return Event{ .key = .right },
        'D' => return Event{ .key = .left },

        '1'...'2' => {
            switch (buf[3]) {
                '5' => return Event{ .key = Key{ .fun = 5 } },
                '7' => return Event{ .key = Key{ .fun = 6 } },
                '8' => return Event{ .key = Key{ .fun = 7 } },
                '9' => return Event{ .key = Key{ .fun = 8 } },
                '0' => return Event{ .key = Key{ .fun = 9 } },
                '1' => return Event{ .key = Key{ .fun = 10 } },
                '3' => return Event{ .key = Key{ .fun = 11 } },
                '4' => return Event{ .key = Key{ .fun = 12 } },
                else => {},
            }
        },
        // fn (kinda weird, not easy to make a range)
        // '15' => return Event{ .key = Key{.fun = buf[2] + 1 - 'A'}},

        else => {},
    }

    return .not_supported;
}

fn read_until(buf: []const u8, del: u8) !usize {
    var offset: usize = 0;

    while (offset < buf.len) {
        offset += 1;

        if (buf[offset] == del) {
            return offset;
        }
    }

    return error.CantReadEvent;
}

pub const Event = union(enum) {
    key: Key,
    mouse,
    not_supported,
    none,
};

pub const Key = union(enum) {
    terminal_bell,
    backspace,
    horizontal_tab,
    new_line,
    enter,
    escape,
    delete,

    up,
    down,
    right,
    left,

    /// char is an array because it can contain utf-8 chars
    /// it will ALWAYS contains at least one char
    // TODO: Unicode compatiblUnicode compatible
    char: []u8,
    fun: u8,
    alt: u8,
    ctrl: u8,
};

test "next" {
    const term = @import("main.zig").term;
    const stdin = io.getStdIn();

    var raw = try term.RawTerm.enableRawMode(stdin.handle, .blocking);
    defer raw.disableRawMode() catch {};

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        const key = try next(stdin.reader());
        std.debug.print("\n\r{s}\n", .{key});
    }
}
