const std = @import("std");

pub inline fn comptimeCsi(comptime fmt: []const u8, args: anytype) []const u8 {
    const str = "\x1b[" ++ fmt;
    return std.fmt.comptimePrint(str, args);
}
