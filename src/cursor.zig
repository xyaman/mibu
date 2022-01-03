const std = @import("std");
const fmt = std.fmt;

const lib = @import("main.zig");
const term = lib.term;
const utils = lib.utils;

/// Moves cursor to `x` column and `y` row
pub inline fn goTo(x: u16, y: u16) []const u8 {
    // i guess is ok with this size for now
    var buf: [30]u8 = undefined;
    return fmt.bufPrint(&buf, "\x1b[{d};{d}H", .{ y, x }) catch unreachable;
}

/// Moves cursor up `y` rows
pub inline fn goUp(y: u16) []const u8 {
    // i guess is ok with this size for now
    var buf: [30]u8 = undefined;
    return fmt.bufPrint(&buf, "\x1b[{d}A", .{y}) catch unreachable;
}

/// Moves cursor down `y` rows
pub inline fn goDown(y: u16) []const u8 {
    // i guess is ok with this size for now
    var buf: [30]u8 = undefined;
    return fmt.bufPrint(&buf, "\x1b[{d}A", .{y}) catch unreachable;
}

/// Moves cursor left `x` columns
pub inline fn goLeft(x: u16) []const u8 {
    // i guess is ok with this size for now
    var buf: [30]u8 = undefined;
    return fmt.bufPrint(&buf, "\x1b[{d}D", .{x}) catch unreachable;
}

/// Moves cursor right `x` columns
pub inline fn goRight(x: u16) []const u8 {
    // i guess is ok with this size for now
    var buf: [30]u8 = undefined;
    return fmt.bufPrint(&buf, "\x1b[{d}C", .{x}) catch unreachable;
}

/// Hide the cursor
pub inline fn hide() []const u8 {
    return utils.comptimeCsi("?25l", .{});
}

/// Show the cursor
pub inline fn show() []const u8 {
    return utils.comptimeCsi("?25h", .{});
}

/// Save cursor position
pub inline fn save() []const u8 {
    return utils.comptimeCsi("u", .{});
}

/// Restore cursor position
pub inline fn restore() []const u8 {
    return utils.comptimeCsi("s", .{});
}
