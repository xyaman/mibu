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

/// Returns the ANSI sequence as a []const u8
pub const reset = "0m";

/// Returns the ANSI sequence to set bold mode
pub const style_bold = "1m";
pub const style_no_bold = "22m";

/// Returnstyle_s the ANSI sequence to set dim mode
pub const style_dim = "2m";
pub const style_no_dim = "22m";

/// Returnstyle_s the ANSI sequence to set italic mode
pub const style_italic = "3m";
pub const style_no_italic = "23m";

/// Returnstyle_s the ANSI sequence to set underline mode
pub const style_underline = "4m";
pub const style_no_underline = "24m";

/// Returnstyle_s the ANSI sequence to set blinking mode
pub const style_blinking = "5m";
pub const style_no_blinking = "25m";

/// Returnstyle_s the ANSI sequence to set reverse mode
pub const style_reverse = "7m";
pub const style_no_reverse = "27m";

/// Returnstyle_s the ANSI sequence to set hidden/invisible mode
pub const style_invisible = "8m";
pub const style_no_invisible = "28m";

/// Returnstyle_s the ANSI sequence to set strikethrough mode
pub const style_strikethrough = "9m";
pub const style_no_strikethrough = "29m";

pub inline fn comptimeCsi(comptime fmt: []const u8, args: anytype) []const u8 {
    const str = "\x1b[" ++ fmt;
    return std.fmt.comptimePrint(str, args);
}
