const std = @import("std");
const builtin = @import("builtin");

const Io = std.Io;

const mibu = @import("mibu");
const term = mibu.term;
const color = mibu.color;
const cursor = mibu.cursor;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1]u8 = undefined;
    var stdout_file = Io.File.stdout();
    var stdout_writer = stdout_file.writer(io, &stdout_buffer);

    const stdout = &stdout_writer.interface;

    // we have to make sure that exitAlternateScreen
    // and cursor.show are flushed when the program exits.
    defer stdout.flush() catch {};

    if (!try stdout_file.isTty(io)) {
        try stdout.print("The current file descriptor is not referring to a terminal.\n", .{});
        return;
    }

    if (builtin.os.tag == .windows) {
        try mibu.enableWindowsVTS(stdout_file.handle);
    }

    try term.enterAlternateScreen(stdout);
    defer term.exitAlternateScreen(stdout) catch {};

    try cursor.hide(stdout);
    defer cursor.show(stdout) catch {};

    try cursor.goTo(stdout, 1, 1);
    try mibu.style.italic(stdout, true);
    try stdout.print("This is being shown in the alternate screen...", .{});
    try stdout.flush();

    try io.sleep(.fromSeconds(2), .real);
}
