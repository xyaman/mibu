const std = @import("std");
const io = std.io;

const mibu = @import("mibu");
const events = mibu.events;
const term = mibu.term;
const utils = mibu.utils;

pub fn main() !void {
    const stdin = io.getStdIn();
    const stdout = io.getStdOut();

    // Enable terminal raw mode, its very recommended when listening for events
    var raw_term = try term.enableRawMode(stdin.handle, .blocking);
    defer raw_term.disableRawMode() catch {};

    try stdout.writer().print("{s}", .{utils.enable_mouse_tracking});
    defer stdout.writer().print("{s}", .{utils.disable_mouse_tracking}) catch {};

    try stdout.writer().print("Press q or Ctrl-C to exit...\n\r", .{});

    while (true) {
        const next = try events.next(stdin);
        switch (next) {
            .key => |k| switch (k) {
                // char can have more than 1 u8, because of unicode
                .char => |c| switch (c) {
                    'q' => break,
                    else => try stdout.writer().print("Key char: {u}\n\r", .{c}),
                },
                .ctrl => |c| switch (c) {
                    'c' => break,
                    else => try stdout.writer().print("Key: {s}\n\r", .{k}),
                },
                else => try stdout.writer().print("Key: {s}\n\r", .{k}),
            },
            // ex. mouse events not supported yet
            .mouse => |m| try stdout.writer().print("Mouse: {s}\n\r", .{m}),
            else => try stdout.writer().print("Event: {any}\n\r", .{next}),
        }
    }

    try stdout.writer().print("Bye bye\n\r", .{});
}
