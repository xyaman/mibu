const std = @import("std");
const Io = std.Io;

const utils = @import("main.zig").utils;

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
pub fn reset(writer: *Io.Writer) !void {
    return writer.print(print.reset, .{});
}

/// Outputs the ANSI sequence to set/unset bold mode
pub fn bold(writer: *Io.Writer, v: bool) !void {
    return if (v) writer.print(print.bold, .{}) else writer.print(print.no_bold, .{});
}

/// Outputs the ANSI sequence to set/unset dim mode
pub fn dim(writer: *Io.Writer, v: bool) !void {
    return if (v) writer.print(print.dim, .{}) else writer.print(print.no_dim, .{});
}

/// Outputs the ANSI sequence to set/unset italic mode
pub fn italic(writer: *Io.Writer, v: bool) !void {
    return if (v) writer.print(print.italic, .{}) else writer.print(print.no_italic, .{});
}

/// Outputs the ANSI sequence to set/unset underline mode
pub fn underline(writer: *Io.Writer, v: bool) !void {
    return if (v) writer.print(print.underline, .{}) else writer.print(print.no_underline, .{});
}

/// Outputs the ANSI sequence to set/unset blinking mode
pub fn blinking(writer: *Io.Writer, v: bool) !void {
    return if (v) writer.print(print.blinking, .{}) else writer.print(print.no_blinking, .{});
}

/// Outputs the ANSI sequence to set/unset reverse mode
pub fn reverse(writer: *Io.Writer, v: bool) !void {
    return if (v) writer.print(print.reverse, .{}) else writer.print(print.no_reverse, .{});
}

/// Outputs the ANSI sequence to set/unset hidden/invisible mode
pub fn hidden(writer: *Io.Writer, v: bool) !void {
    return if (v) writer.print(print.invisible, .{}) else writer.print(print.no_invisible, .{});
}

/// Outputs the ANSI sequence to set/unset strikethrough mode
pub fn strikethrough(writer: *Io.Writer, v: bool) !void {
    return if (v) writer.print(print.strikethrough, .{}) else writer.print(print.no_strikethrough, .{});
}
