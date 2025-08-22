const std = @import("std");
const fmt = std.fmt;

const lib = @import("main.zig");
const utils = lib.utils;

pub const print = struct {
    /// Moves cursor to `x` column and `y` row
    pub inline fn goTo(x: anytype, y: anytype) []const u8 {
        // i guess is ok with this size for now
        var buf: [30]u8 = undefined;
        return fmt.bufPrint(&buf, "\x1b[{d};{d}H", .{ y, x }) catch unreachable;
    }

    /// Moves cursor up `y` rows
    pub inline fn goUp(y: anytype) []const u8 {
        // i guess is ok with this size for now
        var buf: [30]u8 = undefined;
        return fmt.bufPrint(&buf, "\x1b[{d}A", .{y}) catch unreachable;
    }

    /// Moves cursor down `y` rows
    pub inline fn goDown(y: anytype) []const u8 {
        // i guess is ok with this size for now
        var buf: [30]u8 = undefined;
        return fmt.bufPrint(&buf, "\x1b[{d}A", .{y}) catch unreachable;
    }

    /// Moves cursor left `x` columns
    pub inline fn goLeft(x: anytype) []const u8 {
        // i guess is ok with this size for now
        var buf: [30]u8 = undefined;
        return fmt.bufPrint(&buf, "\x1b[{d}D", .{x}) catch unreachable;
    }

    /// Moves cursor right `x` columns
    pub inline fn goRight(x: anytype) []const u8 {
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
};

/// Moves cursor to `x` column and `y` row
pub fn goTo(writer: *std.Io.Writer, x: anytype, y: anytype) !void {
    return writer.print(utils.csi ++ "{d};{d}H", .{ y, x });
}

/// Moves cursor up `y` rows
pub fn goUp(writer: *std.Io.Writer, y: anytype) !void {
    return writer.print(utils.csi ++ "{d}A", .{y});
}

/// Moves cursor down `y` rows
pub fn goDown(writer: *std.Io.Writer, y: anytype) !void {
    return writer.print(utils.csi ++ "{d}B", .{y});
}

/// Moves cursor left `x` columns
pub fn goLeft(writer: *std.Io.Writer, x: anytype) !void {
    return writer.print(utils.csi ++ "{d}D", .{x});
}

/// Moves cursor right `x` columns
pub fn goRight(writer: *std.Io.Writer, x: anytype) !void {
    return writer.print(utils.csi ++ "{d}C", .{x});
}

/// Hide the cursor
pub fn hide(writer: *std.Io.Writer) !void {
    return writer.print(utils.csi ++ "?25l", .{});
}

/// Show the cursor
pub fn show(writer: *std.Io.Writer) !void {
    return writer.print(utils.csi ++ "?25h", .{});
}

/// Save cursor position
pub fn save(writer: *std.Io.Writer) !void {
    return writer.print(utils.csi ++ "u", .{});
}

/// Restore cursor position
pub fn restore(writer: *std.Io.Writer) !void {
    return writer.print(utils.csi ++ "s", .{});
}
