const std = @import("std");

pub const csi = "\x1b[";

/// Sequence to set foreground color using 256 colors table
pub const fg_256 = "38;5;";

/// Sequence to set foreground color using 256 colors table
pub const bg_256 = "48;5;";

/// Sequence to set foreground color using 256 colors table
pub const fg_rgb = "38;2;";

/// Sequence to set foreground color using 256 colors table
pub const bg_rgb = "48;2;";

pub inline fn comptimeCsi(comptime fmt: []const u8, args: anytype) []const u8 {
    const str = "\x1b[" ++ fmt;
    return std.fmt.comptimePrint(str, args);
}
