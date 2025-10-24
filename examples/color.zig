const std = @import("std");
const builtin = @import("builtin");

const Io = std.Io;

const mibu = @import("mibu");
const color = mibu.color;
const cursor = mibu.cursor;

pub fn main() !void {
    var stdout_buffer: [1]u8 = undefined;

    var stdout_file = std.fs.File.stdout();
    var stdout_writer = stdout_file.writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    if (builtin.os.tag == .windows) {
        try mibu.enableWindowsVTS(stdout_file.handle);
    }

    try stdout.print("{s}Warning text\n", .{color.print.fg(.red)});

    try color.fg256(stdout, .blue);
    try stdout.print("Blue text\n", .{});

    try color.fgRGB(stdout, 97, 37, 160);
    try stdout.print("Purple text\n", .{});

    try color.resetAll(stdout);
}
