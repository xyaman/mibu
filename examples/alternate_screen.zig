const std = @import("std");
const builtin = @import("builtin");

const Io = std.Io;

const mibu = @import("mibu");
const term = mibu.term;
const color = mibu.color;
const cursor = mibu.cursor;

pub fn main() !void {
    var stdout_buffer: [1]u8 = undefined;

    var stdout_file = std.fs.File.stdout();
    var stdout_writer = stdout_file.writer(&stdout_buffer);

    const stdout = &stdout_writer.interface;

    // we have to make sure that exitAlternateScreen
    // and cursor.show are flushed when the program exits.
    defer stdout.flush() catch {};

    if (builtin.os.tag == .windows) {
        try mibu.enableWindowsVTS(stdout.handle);
    }

    try term.enterAlternateScreen(stdout);
    defer term.exitAlternateScreen(stdout) catch {};

    try cursor.hide(stdout);
    defer cursor.show(stdout) catch {};

    try cursor.goTo(stdout, 1, 1);
    try mibu.style.italic(stdout, true);
    try stdout.print("This is being shown in the alternate screen...", .{});
    try stdout.flush();

    std.Thread.sleep(std.time.ns_per_s * 2);
}
