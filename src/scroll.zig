const std = @import("std");
const Io = std.Io;

const utils = @import("main.zig").utils;

/// Scrolls the terminal up by `n` lines.
/// Lines that scroll off the top are discarded, and new lines appear at the bottom.
pub fn up(writer: *Io.Writer, n: anytype) !void {
    return writer.print(utils.csi ++ "{d}S", .{n});
}

/// Scrolls the terminal down by `n` lines.
/// Lines that scroll off the bottom are discarded, and new lines appear at the top.
pub fn down(writer: *Io.Writer, n: anytype) !void {
    return writer.print(utils.csi ++ "{d}T", .{n});
}
