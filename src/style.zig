const utils = @import("main.zig").utils;
const std = @import("std");

pub const print = struct {

    /// Returns the ANSI sequence as a []const u8
    pub const reset = utils.comptimeCsi("0m", .{});

    /// Returns the ANSI sequence to set bold mode
    pub const bold = utils.comptimeCsi("1m", .{});
    pub const no_bold = utils.comptimeCsi("22m", .{});

    /// Returns the ANSI sequence to set dim mode
    pub const dim = utils.comptimeCsi("2m", .{});
    pub const no_dim = utils.comptimeCsi("22m", .{});

    /// Returns the ANSI sequence to set italic mode
    pub const italic = utils.comptimeCsi("3m", .{});
    pub const no_italic = utils.comptimeCsi("23m", .{});

    /// Returns the ANSI sequence to set underline mode
    pub const underline = utils.comptimeCsi("4m", .{});
    pub const no_underline = utils.comptimeCsi("24m", .{});

    /// Returns the ANSI sequence to set blinking mode
    pub const blinking = utils.comptimeCsi("5m", .{});
    pub const no_blinking = utils.comptimeCsi("25m", .{});

    /// Returns the ANSI sequence to set reverse mode
    pub const reverse = utils.comptimeCsi("7m", .{});
    pub const no_reverse = utils.comptimeCsi("27m", .{});

    /// Returns the ANSI sequence to set hidden/invisible mode
    pub const invisible = utils.comptimeCsi("8m", .{});
    pub const no_invisible = utils.comptimeCsi("28m", .{});

    /// Returns the ANSI sequence to set strikethrough mode
    pub const strikethrough = utils.comptimeCsi("9m", .{});
    pub const no_strikethrough = utils.comptimeCsi("29m", .{});
};

/// Returns the ANSI sequence as a []const u8
pub fn reset(writer: anytype) !void {
    return std.fmt.format(writer, utils.reset_all, .{});
}

/// Returns the ANSI sequence to set bold mode
pub fn bold(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_bold, .{});
}

/// Returns the ANSI sequence to unset bold mode
pub fn noBold(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_no_bold, .{});
}

/// Returns the ANSI sequence to set dim mode
pub fn dim(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_dim, .{});
}

/// Returns the ANSI sequence to unset dim mode
pub fn noDim(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_no_dim, .{});
}

/// Returns the ANSI sequence to set italic mode
pub fn italic(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_italic, .{});
}

/// Returns the ANSI sequence to unset italic mode
pub fn noItalic(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_no_italic, .{});
}

/// Returns the ANSI sequence to set underline mode
pub fn underline(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_underline, .{});
}

/// Returns the ANSI sequence to unset underline mode
pub fn noUnderline(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_no_underline, .{});
}

/// Returns the ANSI sequence to set blinking mode
pub fn blinking(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_blinking, .{});
}

/// Returns the ANSI sequence to unset blinking mode
pub fn noBlinking(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_no_blinking, .{});
}

/// Returns the ANSI sequence to set reverse mode
pub fn reverse(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_reverse, .{});
}

/// Returns the ANSI sequence to unset reverse mode
pub fn noReverse(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_no_reverse, .{});
}

/// Returns the ANSI sequence to set hidden/invisible mode
pub fn hidden(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_invisible, .{});
}

/// Returns the ANSI sequence to unset hidden/invisible mode
pub fn noHidden(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_no_invisible, .{});
}

/// Returns the ansi sequence to set strikethrough mode
pub fn strikethrough(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_strikethrough, .{});
}

/// Returns the ansi sequence to unset strikethrough mode
pub fn noStrikethrough(writer: anytype) !void {
    return std.fmt.format(writer, utils.style_no_strikethrough, .{});
}
