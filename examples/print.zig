const std = @import("std");
const io = std.io;

const mibu = @import("mibu");
const Color = mibu.Color;
const Cursor = mibu.Cursor;
const Clear = mibu.Clear;

pub fn main() !void {
    const stdout = io.getStdOut();

    try stdout.writer().print("{s}", .{Clear.all});
    try stdout.writer().print("{s}{s}{s}Hellooo{s} {s}<3\n{s}", .{ Cursor.goTo(1, 1), Color.bgRGB(155, 125, 212), Color.fg(.black), Color.clear, Color.fg(.red), Cursor.goTo(1, 2) });
}
