const std = @import("std");
const io = std.io;

const mibu = @import("mibu");

const color = mibu.color;
const cursor = mibu.cursor;

pub fn main() !void {
    const stdout = io.getStdOut();

    if (@import("builtin").os.tag == .windows) {
        try mibu.enableWindowsVTS(stdout.handle);
    }

    try stdout.writer().print("{s}Warning text\n", .{color.print.fg(.red)});

    try color.fg256(stdout.writer(), .blue);
    try stdout.writer().print("Blue text\n", .{});

    try color.fgRGB(stdout.writer(), 97, 37, 160);
    try stdout.writer().print("Purple text\n", .{});
}
