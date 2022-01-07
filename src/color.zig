const std = @import("std");
const fmt = std.fmt;

const utils = @import("main.zig").utils;

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

/// Change text foreground
pub inline fn fg(comptime color: Color) []const u8 {
    return utils.comptimeCsi("38;5;{d}m", .{@enumToInt(color)});
}

/// Change text background
pub inline fn bg(comptime color: Color) []const u8 {
    return utils.comptimeCsi("48;5;{d}m", .{@enumToInt(color)});
}

/// Change text foreground using rgb
pub inline fn fgRGB(r: u8, g: u8, b: u8) []const u8 {
    var buf: [22]u8 = undefined;
    return fmt.bufPrint(&buf, "\x1b[38;2;{d};{d};{d}m", .{ r, g, b }) catch unreachable;
}

/// Change text background using rgb
pub inline fn bgRGB(r: u8, g: u8, b: u8) []const u8 {
    var buf: [22]u8 = undefined;
    return fmt.bufPrint(&buf, "\x1b[48;2;{d};{d};{d}m", .{ r, g, b }) catch unreachable;
}

pub const reset = utils.comptimeCsi("0m", .{});
