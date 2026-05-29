const std = @import("std");
const Io = std.Io;
const builtin = @import("builtin");
const mibu = @import("mibu");

pub fn main(init: std.process.Init) !void {
    var stdout_buf: [256]u8 = undefined;
    const stdin = Io.File.stdin();
    var stdout_file = Io.File.stdout();
    var stdout_writer = stdout_file.writer(init.io, &stdout_buf);
    const out = &stdout_writer.interface;

    if (builtin.os.tag == .windows) {
        try mibu.enableWindowsVTS(stdout_file.handle);
    }

    var raw_term = try mibu.term.enableRawMode(stdin.handle);
    defer raw_term.disableRawMode() catch {};

    const rgb = mibu.termbg.detect(init.io, stdin, out) catch |err| switch (err) {
        error.NotSupported => {
            try out.print("This terminal is not compatible.\r\n", .{});
            const term = init.environ_map.get("TERM") orelse "unknown";
            try out.print("TERM={s}\r\n", .{term});
            try out.flush();
            return;
        },
        else => return err,
    };

    const t = mibu.termbg.theme(rgb);
    const rgb8 = rgb.to8();

    try out.print("rgb (16-bit): {f}\r\n", .{rgb});
    try out.print("rgb  (8-bit): {f}\r\n", .{rgb8});
    try out.print("theme: {s}\r\n", .{@tagName(t)});
    try out.flush();
}
