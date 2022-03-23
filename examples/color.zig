const std = @import("std");
const io = std.io;

const mibu = @import("mibu");

const color = mibu.color;
const cursor = mibu.cursor;

pub fn main() !void {
    const stdout = io.getStdOut();

    try stdout.writer().print("{s}Warning text\n", .{color.print.fg(.red)});

    try color.writeFg256(stdout.writer(), .blue);
    try stdout.writer().print("Blue text\n", .{});

    try color.writeFgRGB(stdout.writer(), 97, 37, 160);
    try stdout.writer().print("Purple text\n", .{});
}
