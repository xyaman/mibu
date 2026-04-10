const std = @import("std");
const builtin = @import("builtin");
const mibu = @import("mibu");

pub fn main() !void {
    var stdout_buf: [256]u8 = undefined;
    const stdin = std.fs.File.stdin();
    var stdout_file = std.fs.File.stdout();
    var stdout_writer = stdout_file.writer(&stdout_buf);
    const out = &stdout_writer.interface;

    if (builtin.os.tag == .windows) {
        try mibu.enableWindowsVTS(stdout_file.handle);
    }

    var raw_term = try mibu.term.enableRawMode(stdin.handle);
    defer raw_term.disableRawMode() catch {};

    const rgb = try mibu.termbg.detect(stdin, stdout_file);

    const t = mibu.termbg.theme(rgb);
    const rgb8 = rgb.to8();

    try out.print("rgb (16-bit): {}\r\n", .{rgb});
    try out.print("rgb  (8-bit): {}\r\n", .{rgb8});
    try out.print("theme: {s}\r\n", .{@tagName(t)});
    try out.flush();
}
