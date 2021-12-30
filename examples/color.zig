const std = @import("std");
const io = std.io;

const mibu = @import("mibu");
const keys = mibu.keys;
const RawTerm = mibu.term.RawTerm;

pub fn main() !void {
    const stdin = io.getStdIn();
    const stdout = io.getStdOut();

    // Enable terminal raw mode, its very recommended when listening for events
    var raw_term = RawTerm.enableRawMode(stdin.handle);
    defer raw_term.disableRawTerm catch {};

    while (true) {
        switch (try keys.read(stdin)) {
            .key => |k| switch(k) {
                'q' => break,
                else => try stdout.writer().print("Key: {s}", .{k});
            },
            // mouse events not supported yet
            .mouse => {},
        }
    }
}
