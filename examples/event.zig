const std = @import("std");
const Io = std.Io;
const builtin = @import("builtin");

const mibu = @import("mibu");
const events = mibu.events;
const term = mibu.term;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [1024]u8 = undefined;

    const stdin = Io.File.stdin();
    var stdout_file = Io.File.stdout();
    var stdout_writer = stdout_file.writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    if (!try stdin.isTty(init.io)) {
        try stdout.print("The current file descriptor is not a referring to a terminal.\n", .{});
        return;
    }

    if (builtin.os.tag == .windows) {
        try mibu.enableWindowsVTS(stdout_file.handle);
    }

    // Enable terminal raw mode, its very recommended when listening for events
    var raw_term = try term.enableRawMode(stdin.handle);
    defer raw_term.disableRawMode() catch {};

    // Flush must run after disable_mouse_tracking is written but before raw mode is restored.
    defer stdout.flush() catch {};

    // To listen mouse events, we need to enable mouse tracking
    try stdout.print("{s}", .{mibu.utils.enable_mouse_tracking});
    defer stdout.print("{s}", .{mibu.utils.disable_mouse_tracking}) catch {};

    // Opt into the Kitty keyboard protocol if the terminal supports it, so we
    // get press/repeat/release and unambiguous modifiers. Legacy path otherwise.
    const supports_kitty = try events.supportsKittyKeyboardWithTimeout(init.io, stdin, stdout, 1000);
    if (supports_kitty) try term.pushKittyKeyboard(stdout, .{ .disambiguate = true, .report_events = true });
    defer if (supports_kitty) term.popKittyKeyboard(stdout) catch {};

    try stdout.print("Press Ctrl-C to exit...\n\r", .{});
    try stdout.flush();

    while (true) {
        const next = try events.nextWithTimeout(init.io, stdin, 1000);
        switch (next) {
            .key => |k| switch (k.code) {
                .char => |char| {
                    if (k.mods.ctrl and char == 'c') {
                        break;
                    }
                    try stdout.print("Pressed: {f} [{s}]\n\r", .{ k, @tagName(k.event) });
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
