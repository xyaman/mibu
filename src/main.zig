const std = @import("std");

pub const clear = @import("clear.zig");
pub const color = @import("color.zig");
pub const cursor = @import("cursor.zig");
pub const style = @import("style.zig");
pub const utils = @import("utils.zig");
pub const term = @import("term.zig");
pub const events = @import("event.zig");

pub const initWindows = switch (@import("builtin").os.tag) {
    .windows => @import("utils.zig").initWindows,
    else => undefined,
};

test {
    std.testing.refAllDecls(@This());
}
