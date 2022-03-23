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

/// Sequence to reset color and style
pub const reset_all = "0m";

/// Sequence to clear from cursor until end of screen
pub const clear_screen_from_cursor = "0J";

/// Sequence to clear from beginning to cursor.
pub const clear_screen_to_cursor = "1J";

/// Sequence to clear all screen
pub const clear_all = "2J";

/// Clear from cursor to end of line
pub const clear_line_from_cursor = "0K";

/// Clear start of line to the cursor
pub const clear_line_to_cursor = "1K";

/// Clear entire line
pub const clear_line = "2K";

pub inline fn comptimeCsi(comptime fmt: []const u8, args: anytype) []const u8 {
    const str = "\x1b[" ++ fmt;
    return std.fmt.comptimePrint(str, args);
}
