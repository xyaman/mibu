const std = @import("std");
const builtin = @import("builtin");

const Io = std.Io;

const mibu = @import("mibu");
const events = mibu.events;
const term = mibu.term;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;

    const stdin = std.fs.File.stdin();
    var stdout_file = std.fs.File.stdout();
    var stdout_writer = stdout_file.writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    if (!std.posix.isatty(stdin.handle)) {
        try stdout.print("The current file descriptor is not a referring to a terminal.\n", .{});
        return;
    }

    if (builtin.os.tag == .windows) {
        try mibu.enableWindowsVTS(stdout.handle);
    }

    // Enable terminal raw mode, its very recommended when listening for events
    var raw_term = try term.enableRawMode(stdin.handle);
    defer raw_term.disableRawMode() catch {};

    // To listen mouse events, we need to enable mouse tracking
    try stdout.print("{s}", .{mibu.utils.enable_mouse_tracking});
    defer stdout.print("{s}", .{mibu.utils.disable_mouse_tracking}) catch {};

    try stdout.print("Press q or Ctrl-C to exit...\n\r", .{});

    while (true) {
        const next = try events.nextWithTimeout(stdin, 1000);
        switch (next) {
            .key => |k| switch (k.code) {
                .char => |char| {
                    if (k.mods.ctrl and char == 'c') {
                        break;
                    }
                    try stdout.print("Pressed: {f}\n\r", .{k});
                },
                else => {},
            },
            .mouse => |m| try stdout.print("Mouse: {f}\n\r", .{m}),
            .timeout => try stdout.print("Timeout.\n\r", .{}),

            // ex. mouse events not supported yet
            else => try stdout.print("Event: {any}\n\r", .{next}),
        }

        try stdout.flush();
    }

    try stdout.print("Bye bye\n\r", .{});
}
