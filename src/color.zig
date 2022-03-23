const std = @import("std");
const fmt = std.fmt;

const utils = @import("main.zig").utils;

/// 256 colors
pub const Color = enum(u8) {
    black = 0,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    default,
};

pub const print = struct {

    /// Returns a string to change text foreground using 256 colors
    pub inline fn fg(comptime color: Color) []const u8 {
        return utils.comptimeCsi("38;5;{d}m", .{@enumToInt(color)});
    }

    /// Returns a string to change text background using 256 colors
    pub inline fn bg(comptime color: Color) []const u8 {
        return utils.comptimeCsi("48;5;{d}m", .{@enumToInt(color)});
    }

    /// Returns a string to change text foreground using rgb colors
    /// Uses a buffer.
    pub inline fn fgRGB(r: u8, g: u8, b: u8) []const u8 {
        var buf: [22]u8 = undefined;
        return fmt.bufPrint(&buf, "\x1b[38;2;{d};{d};{d}m", .{ r, g, b }) catch unreachable;
    }

    /// Returns a string to change text background using rgb colors
    /// Uses a buffer.
    pub inline fn bgRGB(r: u8, g: u8, b: u8) []const u8 {
        var buf: [22]u8 = undefined;
        return fmt.bufPrint(&buf, "\x1b[48;2;{d};{d};{d}m", .{ r, g, b }) catch unreachable;
    }

    pub const reset = utils.comptimeCsi("0m", .{});
};

/// Writes the escape sequence code to change foreground to `color` (using 256 colors)
pub fn fg256(writer: anytype, color: Color) !void {
    return std.fmt.format(writer, utils.csi ++ utils.fg_256 ++ "{d}m", .{@enumToInt(color)});
}

/// Writes the escape sequence code to change background to `color` (using 256 colors)
pub fn bg256(writer: anytype, color: Color) !void {
    return std.fmt.format(writer, utils.csi ++ utils.bg_256 ++ "{d}m", .{@enumToInt(color)});
}

/// Writes the escape sequence code to change foreground to rgb color
pub fn fgRGB(writer: anytype, r: u8, g: u8, b: u8) !void {
    return std.fmt.format(writer, utils.csi ++ utils.fg_rgb ++ "{d};{d};{d}m", .{ r, g, b });
}

/// Writes the escape sequence code to change background to rgb color
pub fn bgRGB(writer: anytype, r: u8, g: u8, b: u8) !void {
    return std.fmt.format(writer, utils.csi ++ utils.bg_rgb ++ "{d};{d};{d}m", .{ r, g, b });
}

/// Writes the escape code to reset style and color
pub fn resetAll(writer: anytype) !void {
    return std.fmt.format(writer, utils.csi ++ utils.reset_all, .{});
}
