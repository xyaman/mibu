const std = @import("std");
const io = std.io;

const mibu = @import("mibu");
const events = mibu.events;
const RawTerm = mibu.term.RawTerm;

pub fn main() !void {
    const stdin = io.getStdIn();
    const stdout = io.getStdOut();

    // Enable terminal raw mode, its very recommended when listening for events
    var raw_term = try RawTerm.enableRawMode(stdin.handle);
    defer raw_term.disableRawMode() catch {};

    try stdout.writer().print("Press q or Ctrl-C to exit...\n\r", .{});

    while (true) {
        switch (try events.next(stdin)) {
            .key => |k| switch (k) {
                // char can have more than 1 u8, because of unicode
                .char => |c| switch (c[0]) {
                    'q' => break,
                    else => try stdout.writer().print("Key char: {s}\n\r", .{c}),
                },

                .ctrl => |c| switch (c) {
                    'c' => break,
                    // ignore
                    else => {},
                },
                else => try stdout.writer().print("Key: {s}\n\r", .{k}),
            },
            // ex. mouse events not supported yet
            else => {},
        }
    }

    try stdout.writer().print("Bye bye\n\r", .{});
}
