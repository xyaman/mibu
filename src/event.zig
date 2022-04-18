const std = @import("std");
const io = std.io;

const cursor = @import("cursor.zig");

const Key = union(enum) {
    // unicode character
    char: u21,
    ctrl: u21,
    alt: u21,
    fun: u8,

    // arrow keys
    up: void,
    down: void,
    left: void,
    right: void,

    esc: void,
    delete: void,
    enter: void,

    __non_exhaustive: void,

    pub fn format(
        value: Key,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        if (fmt.len == 1 and fmt[0] == 's') {
            try writer.writeAll("Key.");

            switch (value) {
                .ctrl => |c| try std.fmt.format(writer, "ctrl({u})", .{c}),
                .alt => |c| try std.fmt.format(writer, "alt({u})", .{c}),
                .char => |c| try std.fmt.format(writer, "char({u})", .{c}),
                .fun => |d| try std.fmt.format(writer, "fun({d})", .{d}),

                // arrow keys
                .up => try std.fmt.format(writer, "up", .{}),
                .down => try std.fmt.format(writer, "down", .{}),
                .left => try std.fmt.format(writer, "left", .{}),
                .right => try std.fmt.format(writer, "right", .{}),

                // special keys
                .esc => try std.fmt.format(writer, "esc", .{}),
                .enter => try std.fmt.format(writer, "enter", .{}),
                .delete => try std.fmt.format(writer, "delete", .{}),

                else => try std.fmt.format(writer, "Not available yet", .{}),
            }
        }
    }
};

/// Returns the next event received.
/// If raw term is `.blocking` or term is canonical it will block until read at least one event.
/// otherwise it will return `.none` if it didnt read any event
///
/// `in`: needs to be reader
pub fn next(in: anytype) !Event {
    // TODO: Check buffer size
    var buf: [20]u8 = undefined;
    const c = try in.read(&buf);
    if (c == 0) {
        return .none;
    }

    const view = try std.unicode.Utf8View.init(buf[0..c]);
    var iter = view.iterator();
    var event: Event = .none;

    // TODO: Find a better way to iterate buffer
    if (iter.nextCodepoint()) |c0| switch (c0) {
        '\x1b' => {
            if (iter.nextCodepoint()) |c1| switch (c1) {
                // fn (1 - 4)
                // O - 0x6f - 111
                '\x4f' => {
                    return Event{ .key = Key{ .fun = (1 + buf[2] - '\x50') } };
                },

                // csi
                '[' => {
                    return try parse_csi(buf[2..c]);
                },

                // alt key
                else => {
                    return Event{ .key = Key{ .alt = c1 } };
                },
            } else {
                return Event{ .key = .esc };
            }
        },
        // ctrl keys (avoids ctrl-m)
        '\x01'...'\x0C', '\x0E'...'\x1A' => return Event{ .key = Key{ .ctrl = c0 + '\x60' } },

        // special chars
        '\x7f' => return Event{ .key = .delete },
        '\x0D' => return Event{ .key = .enter },

        // chars and shift + chars
        else => return Event{ .key = Key{ .char = c0 } },
    };

    return event;
}

fn parse_csi(buf: []const u8) !Event {
    switch (buf[0]) {
        // keys
        'A' => return Event{ .key = .up },
        'B' => return Event{ .key = .down },
        'C' => return Event{ .key = .right },
        'D' => return Event{ .key = .left },

        '1'...'2' => {
            switch (buf[1]) {
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
        else => {},
    }

    return .not_supported;
}

pub const Event = union(enum) {
    key: Key,
    not_supported,
    none,
};

test "next" {
    const term = @import("main.zig").term;
    const stdin = io.getStdIn();

    var raw = try term.enableRawMode(stdin.handle, .blocking);
    defer raw.disableRawMode() catch {};

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        const key = try next(stdin.reader());
        std.debug.print("\n\r{s}\n", .{key});
    }
}
