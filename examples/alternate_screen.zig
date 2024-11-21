const std = @import("std");
const io = std.io;

const mibu = @import("mibu");
const term = mibu.term;
const color = mibu.color;
const cursor = mibu.cursor;

pub fn main() !void {
    const stdout = io.getStdOut().writer();

    try term.enterAlternateScreen(stdout);
    defer term.exitAlternateScreen(stdout) catch unreachable;

    try cursor.hide(stdout);
    defer cursor.show(stdout) catch unreachable;

    try cursor.goTo(stdout, 1, 1);
    try stdout.print("This is being shown in the alternate screen...", .{});

    std.time.sleep(std.time.ns_per_s * 2);
}
