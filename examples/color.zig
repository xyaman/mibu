const std = @import("std");
const Io = std.Io;
const builtin = @import("builtin");

const mibu = @import("mibu");
const color = mibu.color;
const cursor = mibu.cursor;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [1]u8 = undefined;

    var stdout_file = Io.File.stdout();
    var stdout_writer = stdout_file.writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    if (builtin.os.tag == .windows) {
        mibu.enableWindowsVTS(stdout_file.handle) catch {};
    }

    try stdout.print("{s}Warning text\n", .{color.print.fg(.red)});

    try color.fg256(stdout, .blue);
    try stdout.print("Blue text\n", .{});

    try color.fgRGB(stdout, .{ .r = 97, .g = 37, .b = 160 });
    try stdout.print("Purple text\n", .{});
}
