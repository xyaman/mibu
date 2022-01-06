const utils = @import("main.zig").utils;

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
