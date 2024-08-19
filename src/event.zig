const std = @import("std");
const io = std.io;

const cursor = @import("cursor.zig");

const Key = union(enum) {
    // unicode character
    char: u21,
    ctrl: u21,
    alt: u21,
    ctrl_alt: u21,
    fun: u8,

    // arrow keys
    up: void,
    down: void,
    left: void,
    right: void,

    // shift + arrow keys
    shift_up: void,
    shift_down: void,
    shift_left: void,
    shift_right: void,

    // ctrl + arrow keys
    ctrl_up: void,
    ctrl_down: void,
    ctrl_left: void,
    ctrl_right: void,

    // ctrl + shift + arrow keys
    ctrl_shift_up: void,
    ctrl_shift_down: void,
    ctrl_shift_left: void,
    ctrl_shift_right: void,

    // ctrl + alt + arrow keys
    ctrl_alt_up: void,
    ctrl_alt_down: void,
    ctrl_alt_left: void,
    ctrl_alt_right: void,

    // special keys
    esc: void,
    backspace: void,
    delete: void,
    insert: void,
    enter: void,
    page_up: void,
    page_down: void,
    home: void,
    end: void,

    __non_exhaustive: void,

    pub fn format(
        value: Key,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = fmt;
        try writer.writeAll("Key.");

        switch (value) {
            .ctrl => |c| try std.fmt.format(writer, "ctrl({u})", .{c}),
            .alt => |c| try std.fmt.format(writer, "alt({u})", .{c}),
            .ctrl_alt => |c| try std.fmt.format(writer, "ctrl_alt({u})", .{c}),
            .char => |c| try std.fmt.format(writer, "char({u})", .{c}),
            .fun => |d| try std.fmt.format(writer, "fun({d})", .{d}),

            // arrow keys
            .up => try std.fmt.format(writer, "up", .{}),
            .down => try std.fmt.format(writer, "down", .{}),
            .left => try std.fmt.format(writer, "left", .{}),
            .right => try std.fmt.format(writer, "right", .{}),

            // shift + arrow keys
            .shift_up => try std.fmt.format(writer, "shift_up", .{}),
            .shift_down => try std.fmt.format(writer, "shift_down", .{}),
            .shift_left => try std.fmt.format(writer, "shift_left", .{}),
            .shift_right => try std.fmt.format(writer, "shift_right", .{}),

            // ctrl + arrow keys
            .ctrl_up => try std.fmt.format(writer, "ctrl_up", .{}),
            .ctrl_down => try std.fmt.format(writer, "ctrl_down", .{}),
            .ctrl_left => try std.fmt.format(writer, "ctrl_left", .{}),
            .ctrl_right => try std.fmt.format(writer, "ctrl_right", .{}),

            // ctrl + shift + arrow keys
            .ctrl_shift_up => try std.fmt.format(writer, "ctrl_shift_up", .{}),
            .ctrl_shift_down => try std.fmt.format(writer, "ctrl_shift_down", .{}),
            .ctrl_shift_left => try std.fmt.format(writer, "ctrl_shift_left", .{}),
            .ctrl_shift_right => try std.fmt.format(writer, "ctrl_shift_right", .{}),

            // ctrl + alt + arrow keys
            .ctrl_alt_up => try std.fmt.format(writer, "ctrl_alt_up", .{}),
            .ctrl_alt_down => try std.fmt.format(writer, "ctrl_alt_down", .{}),
            .ctrl_alt_left => try std.fmt.format(writer, "ctrl_alt_left", .{}),
            .ctrl_alt_right => try std.fmt.format(writer, "ctrl_alt_right", .{}),

            // special keys
            .esc => try std.fmt.format(writer, "esc", .{}),
            .enter => try std.fmt.format(writer, "enter", .{}),
            .backspace => try std.fmt.format(writer, "backspace", .{}),
            .delete => try std.fmt.format(writer, "delete", .{}),
            .insert => try std.fmt.format(writer, "insert", .{}),
            .page_up => try std.fmt.format(writer, "page_up", .{}),
            .page_down => try std.fmt.format(writer, "page_down", .{}),
            .home => try std.fmt.format(writer, "home", .{}),
            .end => try std.fmt.format(writer, "end", .{}),

            else => try std.fmt.format(writer, "Not available yet", .{}),
        }
    }
};

pub const MouseButton = enum {
    left,
    middle,
    right,
    release,
    scroll_up,
    scroll_down,

    move,
    move_rightclick,

    __non_exhaustive,
};

pub const Mouse = struct {
    x: u16,
    y: u16,
    button: MouseButton,
    is_alt: bool,
    is_shift: bool,
    is_ctrl: bool,

    pub fn format(
        value: Mouse,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = fmt;
        try writer.writeAll("Mouse.");

        try writer.print("x: {d}, y: {d}, button: {any}, is_alt: {any}, is_shift: {any}, is_ctrl: {any}", .{ value.x, value.y, value.button, value.is_alt, value.is_shift, value.is_ctrl });
    }
};

/// Returns the next event received.
/// When used with canonical mode, the user needs to press enter to receive the event.
/// When raw term is `.blocking` it will block until read at least one event.
/// otherwise it will return `.none` if it didnt read any event
///
/// `in`: needs to be reader
pub fn next(in: anytype) !Event {
    // TODO: Check buffer size
    var buf: [20]u8 = undefined;
    const c = try in.read(&buf);
    if (c == 0) {
        return .none;
    }

    // const view = try std.unicode.Utf8View.init(buf[0..c]);

    // This is hacky to make mouse code work
    // utf8 view failes to parse mouse events, dont know why, need to check it later
    // TODO: check why utf8 view fails to parse mouse events
    // It's related with the value, if its greater than 127, it fails
    const view = std.unicode.Utf8View.init(buf[0..c]) catch {
        return parse_csi(buf[2..c]);
    };

    var iter = view.iterator();
    const event: Event = .none;

    // std.debug.print("\n\r{any}\n", .{view});

    // TODO: Find a better way to iterate buffer
    if (iter.nextCodepoint()) |c0| switch (c0) {
        '\x1b' => {
            if (iter.nextCodepoint()) |c1| switch (c1) {
                // fn (1 - 4)
                // O - 0x6f - 111
                '\x4f' => {
                    return Event{ .key = Key{ .fun = (1 + buf[2] - '\x50') } };
                },

                // csi
                '[' => {
                    return try parse_csi(buf[2..c]);
                },

                '\x01'...'\x0C', '\x0E'...'\x1A' => return Event{ .key = Key{ .ctrl_alt = c1 + '\x60' } },

                // alt key
                else => {
                    return Event{ .key = Key{ .alt = c1 } };
                },
            } else {
                return Event{ .key = .esc };
            }
        },

        // tab is equal to ctrl-i

        // ctrl keys (avoids ctrl-m)
        '\x01'...'\x0C', '\x0E'...'\x1A' => return Event{ .key = Key{ .ctrl = c0 + '\x60' } },

        // special chars
        '\x7f' => return Event{ .key = .backspace },
        '\x0D' => return Event{ .key = .enter },

        // chars and shift + chars
        else => return Event{ .key = Key{ .char = c0 } },
    };

    return event;
}

fn parse_csi(buf: []const u8) !Event {
    switch (buf[0]) {
        // keys
        'A' => return Event{ .key = .up },
        'B' => return Event{ .key = .down },
        'C' => return Event{ .key = .right },
        'D' => return Event{ .key = .left },

        '1' => {
            switch (buf[1]) {
                '5' => return Event{ .key = Key{ .fun = 5 } },
                '7' => return Event{ .key = Key{ .fun = 6 } },
                '8' => return Event{ .key = Key{ .fun = 7 } },
                '9' => return Event{ .key = Key{ .fun = 8 } },
                '~' => return Event{ .key = .home },
                // shift + arrow keys
                ';' => {
                    switch (buf[2]) {
                        '2' => {
                            switch (buf[3]) {
                                'A' => return Event{ .key = .shift_up },
                                'B' => return Event{ .key = .shift_down },
                                'C' => return Event{ .key = .shift_right },
                                'D' => return Event{ .key = .shift_left },
                                else => {},
                            }
                        },
                        '5' => {
                            switch (buf[3]) {
                                'A' => return Event{ .key = .ctrl_up },
                                'B' => return Event{ .key = .ctrl_down },
                                'C' => return Event{ .key = .ctrl_right },
                                'D' => return Event{ .key = .ctrl_left },
                                else => {},
                            }
                        },
                        '6' => {
                            switch (buf[3]) {
                                'A' => return Event{ .key = .ctrl_shift_up },
                                'B' => return Event{ .key = .ctrl_shift_down },
                                'C' => return Event{ .key = .ctrl_shift_right },
                                'D' => return Event{ .key = .ctrl_shift_left },
                                else => {},
                            }
                        },

                        '7' => {
                            switch (buf[3]) {
                                'A' => return Event{ .key = .ctrl_alt_up },
                                'B' => return Event{ .key = .ctrl_alt_down },
                                'C' => return Event{ .key = .ctrl_alt_right },
                                'D' => return Event{ .key = .ctrl_alt_left },
                                else => {},
                            }
                        },

                        else => {},
                    }
                },
                else => {},
            }
        },

        '2' => {
            switch (buf[1]) {
                '0' => return Event{ .key = Key{ .fun = 9 } },
                '1' => return Event{ .key = Key{ .fun = 10 } },
                '3' => return Event{ .key = Key{ .fun = 11 } },
                '4' => return Event{ .key = Key{ .fun = 12 } },
                '~' => return Event{ .key = .insert },
                else => {},
            }
        },

        '3' => return Event{ .key = .delete },
        '4' => return Event{ .key = .end },
        '5' => return Event{ .key = .page_up },
        '6' => return Event{ .key = .page_down },

        // Mouse Events
        // On button press, xterm sends CSI MCbCxCy (6 characters) = "\x1b[MbCxCy"
        // -   Cb is button-1, where button is 1, 2 or 3.
        // -   Cx and Cy are the x and y coordinates of the mouse when the button
        //     was pressed.
        'M' => {
            const x = buf[2];
            const y = buf[3];

            var mouse_event = parse_mouse_action(buf[1]) catch {
                return .not_supported;
            };
            // x and y are 1-based
            mouse_event.x = x - 1;
            mouse_event.y = y - 1;

            return Event{ .mouse = mouse_event };
        },

        else => {},
    }

    return .not_supported;
}

fn parse_mouse_action(action: u8) !Mouse {
    // Normal tracking mode sends an escape sequence on both button press and
    // release.  Modifier key (shift, ctrl, meta) information is also sent.  It
    // is enabled by specifying parameter 1000 to DECSET.  On button press or
    // release, xterm sends CSI M CbCxCy.
    //
    // o   The low two bits of Cb encode button information:
    //
    //               0=MB1 pressed,
    //               1=MB2 pressed,
    //               2=MB3 pressed, and
    //               3=release.
    //
    // o   The next three bits encode the modifiers which were down when the
    //     button was pressed and are added together:
    //
    //               4=Shift,
    //               8=Meta, and
    //               16=Control.

    var mouse_event = Mouse{
        .x = 0,
        .y = 0,
        .button = MouseButton.left,
        .is_alt = false,
        .is_shift = false,
        .is_ctrl = false,
    };

    // modifiers
    mouse_event.is_shift = action & 0b0000_01000 != 0;
    mouse_event.is_alt = action & 0b0000_1000 != 0;
    mouse_event.is_ctrl = action & 0b0001_0000 != 0;

    if (action & 0b0100_0000 != 0) {
        // Click and move mouse results into the following events:
        // 1. Left/Middle/Right click
        // 2. Scroll up/down (where left click is scroll up and middle/right click is scroll down)
        //
        // So to get the "drag" event, it needs to be handled in the frontend
        // or the main application.

        // EDIT: ok, so right click and move has an own event
        // TODO: check mouse

        switch (action & 0b0000_0011) {
            0 => mouse_event.button = MouseButton.scroll_up,
            1 => mouse_event.button = MouseButton.scroll_down,
            2 => mouse_event.button = MouseButton.move_rightclick,
            3 => mouse_event.button = MouseButton.move,
            else => return error.InvalidMouseButton,
        }

        return mouse_event;
    }

    // button clicks
    mouse_event.button = switch (action & 0b0000_0011) {
        0 => MouseButton.left,
        1 => MouseButton.middle,
        2 => MouseButton.right,
        3 => MouseButton.release,

        else => return error.InvalidMouseButton,
    };

    return mouse_event;
}

pub const Event = union(enum) {
    key: Key,

    // TODO: Signal = SIGWINCH
    // Probably, we will need a separate thread to handle signals
    resize,
    not_supported,

    // mouse: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Mouse-Tracking
    mouse: Mouse,

    none,
};

test "next" {
    const term = @import("main.zig").term;

    const tty = (try std.fs.cwd().openFile("/dev/tty", .{})).reader();

    var raw = try term.enableRawMode(tty.context.handle, .blocking);
    defer raw.disableRawMode() catch {};

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        const key = try next(tty);
        std.debug.print("\n\r{any}\n", .{key});
    }
}
