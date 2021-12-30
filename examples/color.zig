const std = @import("std");
const io = std.io;

const mibu = @import("mibu");

const Color = mibu.Color;
const Cursor = mibu.Cursor;

pub fn main() !void {
    const stdout = io.getStdOut();

    try stdout.writer().print("{s}Warning text{s}\n", .{ Color.fg(.red), Color.clear });
    try stdout.writer().print("{s}Purple background\n", .{Color.bgRGB(97, 37, 160)});
}
