const utils = @import("main.zig").utils;
const std = @import("std");

pub const print = struct {
    /// Returns the ANSI sequence as a []const u8
    pub const reset = utils.comptimeCsi(utils.reset, .{});

    /// Returns the ANSI sequence to set bold mode
    pub const bold = utils.comptimeCsi(utils.style_bold, .{});
    pub const no_bold = utils.comptimeCsi(utils.style_no_bold, .{});

    /// Returns the ANSI sequence to set dim mode
    pub const dim = utils.comptimeCsi(utils.style_dim, .{});
    pub const no_dim = utils.comptimeCsi(utils.style_no_dim, .{});

    /// Returns the ANSI sequence to set italic mode
    pub const italic = utils.comptimeCsi(utils.style_italic, .{});
    pub const no_italic = utils.comptimeCsi(utils.style_no_italic, .{});

    /// Returns the ANSI sequence to set underline mode
    pub const underline = utils.comptimeCsi(utils.style_underline, .{});
    pub const no_underline = utils.comptimeCsi(utils.style_no_underline, .{});

    /// Returns the ANSI sequence to set blinking mode
    pub const blinking = utils.comptimeCsi(utils.style_blinking, .{});
    pub const no_blinking = utils.comptimeCsi(utils.style_no_blinking, .{});

    /// Returns the ANSI sequence to set reverse mode
    pub const reverse = utils.comptimeCsi(utils.style_reverse, .{});
    pub const no_reverse = utils.comptimeCsi(utils.style_no_reverse, .{});

    /// Returns the ANSI sequence to set hidden/invisible mode
    pub const invisible = utils.comptimeCsi(utils.style_invisible, .{});
    pub const no_invisible = utils.comptimeCsi(utils.style_no_invisible, .{});

    /// Returns the ANSI sequence to set strikethrough mode
    pub const strikethrough = utils.comptimeCsi(utils.style_strikethrough, .{});
    pub const no_strikethrough = utils.comptimeCsi(utils.style_no_strikethrough, .{});
};

/// Returns the ANSI sequence as a []const u8
pub fn reset(writer: anytype) !void {
    return std.fmt.format(writer, print.reset, .{});
}

/// Returns the ANSI sequence to set bold mode
pub fn bold(writer: anytype) !void {
    return std.fmt.format(writer, print.bold, .{});
}

/// Returns the ANSI sequence to unset bold mode
pub fn noBold(writer: anytype) !void {
    return std.fmt.format(writer, print.no_bold, .{});
}

/// Returns the ANSI sequence to set dim mode
pub fn dim(writer: anytype) !void {
    return std.fmt.format(writer, print.dim, .{});
}

/// Returns the ANSI sequence to unset dim mode
pub fn noDim(writer: anytype) !void {
    return std.fmt.format(writer, print.no_dim, .{});
}

/// Returns the ANSI sequence to set italic mode
pub fn italic(writer: anytype) !void {
    return std.fmt.format(writer, print.italic, .{});
}

/// Returns the ANSI sequence to unset italic mode
pub fn noItalic(writer: anytype) !void {
    return std.fmt.format(writer, print.no_italic, .{});
}

/// Returns the ANSI sequence to set underline mode
pub fn underline(writer: anytype) !void {
    return std.fmt.format(writer, print.underline, .{});
}

/// Returns the ANSI sequence to unset underline mode
pub fn noUnderline(writer: anytype) !void {
    return std.fmt.format(writer, print.no_underline, .{});
}

/// Returns the ANSI sequence to set blinking mode
pub fn blinking(writer: anytype) !void {
    return std.fmt.format(writer, print.blinking, .{});
}

/// Returns the ANSI sequence to unset blinking mode
pub fn noBlinking(writer: anytype) !void {
    return std.fmt.format(writer, print.no_blinking, .{});
}

/// Returns the ANSI sequence to set reverse mode
pub fn reverse(writer: anytype) !void {
    return std.fmt.format(writer, print.reverse, .{});
}

/// Returns the ANSI sequence to unset reverse mode
pub fn noReverse(writer: anytype) !void {
    return std.fmt.format(writer, print.no_reverse, .{});
}

/// Returns the ANSI sequence to set hidden/invisible mode
pub fn hidden(writer: anytype) !void {
    return std.fmt.format(writer, print.invisible, .{});
}

/// Returns the ANSI sequence to unset hidden/invisible mode
pub fn noHidden(writer: anytype) !void {
    return std.fmt.format(writer, print.no_invisible, .{});
}

/// Returns the ansi sequence to set strikethrough mode
pub fn strikethrough(writer: anytype) !void {
    return std.fmt.format(writer, print.strikethrough, .{});
}

/// Returns the ansi sequence to unset strikethrough mode
pub fn noStrikethrough(writer: anytype) !void {
    return std.fmt.format(writer, print.no_strikethrough, .{});
}
