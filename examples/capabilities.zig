const std = @import("std");
const Io = std.Io;

const mibu = @import("mibu");
const term = mibu.term;
const events = mibu.events;

pub fn main(init: std.process.Init) !void {
    var out_buffer: [1024]u8 = undefined;

    const stdin = Io.File.stdin();
    var out_file = Io.File.stdout();
    var out_writer = out_file.writer(init.io, &out_buffer);
    const out = &out_writer.interface;

    if (!try stdin.isTty(init.io)) {
        try out.print("stdin is not a terminal.\n", .{});
        return;
    }

    // DECRQM detection reads a reply, so raw mode is required.
    var raw_term = try term.enableRawMode(stdin.handle);
    defer raw_term.disableRawMode() catch {};

    const modes = [_]struct { n: u16, name: []const u8 }{
        .{ .n = 2026, .name = "synchronized output" },
        .{ .n = 2048, .name = "in-band resize" },
        .{ .n = 2004, .name = "bracketed paste" },
    };

    for (modes) |m| {
        const status = try events.queryModeWithTimeout(init.io, stdin, out, m.n, 200);
        const label = if (status.supported()) "supported" else "unsupported";
        try out.print("mode {d} ({s}): {s} [{s}]\n\r", .{ m.n, m.name, label, @tagName(status) });
    }
    try out.flush();
}
