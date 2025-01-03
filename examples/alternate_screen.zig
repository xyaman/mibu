const std = @import("std");
const io = std.io;

const mibu = @import("mibu");
const term = mibu.term;
const color = mibu.color;
const cursor = mibu.cursor;

pub fn main() !void {
    const stdout = io.getStdOut();
    const stdout_wrt = stdout.writer();

    if (comptime @import("builtin").os.tag == .windows) {
        try mibu.term.ensureWindowsVTS(stdout.handle);
    }

    try term.enterAlternateScreen(stdout_wrt);
    defer term.exitAlternateScreen(stdout_wrt) catch unreachable;

    try cursor.hide(stdout_wrt);
    defer cursor.show(stdout_wrt) catch unreachable;

    try cursor.goTo(stdout_wrt, 1, 1);
    try stdout_wrt.print("This is being shown in the alternate screen...", .{});

    std.time.sleep(std.time.ns_per_s * 2);
}
