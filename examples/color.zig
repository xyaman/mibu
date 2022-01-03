const std = @import("std");
const io = std.io;

const mibu = @import("mibu");

const color = mibu.color;
const cursor = mibu.cursor;

pub fn main() !void {
    const stdout = io.getStdOut();

    try stdout.writer().print("{s}Warning text{s}\n", .{ color.fg(.red), color.clear });
    try stdout.writer().print("{s}Purple background\n", .{color.bgRGB(97, 37, 160)});
}
