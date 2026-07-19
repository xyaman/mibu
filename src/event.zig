const std = @import("std");
const Io = std.Io;
const posix = std.posix;
const unicode = std.unicode;
const windows = std.os.windows;
const winapiGlue = @import("winapiGlue.zig");
const builtin = @import("builtin");

pub const Modifiers = packed struct {
    shift: bool = false,
    alt: bool = false,
    ctrl: bool = false,

    // Kitty-only; legacy paths leave these false.
    super: bool = false,
    hyper: bool = false,
    meta: bool = false,
};

/// Kitty reports these; legacy sequences are always `.press`.
pub const KeyEvent = enum { press, repeat, release };

pub const KeyCode = union(enum) {
    char: u21,
    enter,
    esc,
    backspace,
    tab,
    up,
    down,
    left,
    right,
    home,
    end,
    page_up,
    page_down,
    insert,
    delete,
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
};

pub const Key = struct {
    mods: Modifiers = .{},
    code: KeyCode,
    event: KeyEvent = .press,

    pub fn format(this: @This(), writer: *Io.Writer) Io.Writer.Error!void {
        try writer.writeAll("Key{ ");
        var first = true;

        if (@as(u6, @bitCast(this.mods)) != 0) {
            try writer.writeAll("mods: ");
            try writer.print("{{shift: {}, alt: {}, ctrl: {}, super: {}, hyper: {}, meta: {}}}", .{ this.mods.shift, this.mods.alt, this.mods.ctrl, this.mods.super, this.mods.hyper, this.mods.meta });
            first = false;
        }

        if (!first) try writer.writeAll(", ");

        switch (this.code) {
            KeyCode.char => try writer.print("char: {u}", .{this.code.char}),
            else => try writer.print("code: {s}", .{@tagName(this.code)}),
        }

        try writer.writeAll(" }");
    }
};

pub const Event = union(enum) {
    key: Key,
    mouse: Mouse,
    // Size changed (in-band mode-2048 report or SIGWINCH); read `term.getSize`.
    resize,
    // Bracketed paste boundaries (DECSET 2004); content between them arrives as normal events.
    paste_start,
    paste_end,
    invalid,
    timeout,
    none,

    pub fn matchesChar(self: @This(), char: u21, mods: Modifiers) bool {
        switch (self) {
            .key => |k| switch (k.code) {
                .char => |c| {
                    return c == char and std.meta.eql(k.mods, mods);
                },
                else => return false,
            },
            else => return false,
        }
    }
};

// https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Mouse-Tracking
pub const Mouse = struct {
    x: u16,
    y: u16,
    button: MouseButton,
    is_alt: bool,
    is_shift: bool,
    is_ctrl: bool,

    pub fn format(this: @This(), writer: *Io.Writer) Io.Writer.Error!void {
        try writer.writeAll("Mouse.");
        try writer.print("x: {d}, y: {d}, button: {any}, is_alt: {any}, is_shift: {any}, is_ctrl: {any}", .{ this.x, this.y, this.button, this.is_alt, this.is_shift, this.is_ctrl });
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

/// Returns the next event received. If no event is received within the timeout,
/// it returns `.timeout`. Timeout is in miliseconds
///
/// When used in canonical mode, the user needs to press Enter to receive the event.
/// When raw terminal mode is activated, the function waits up to the specified timeout
/// for at least one event before returning.
pub fn nextWithTimeout(io: Io, file: Io.File, timeout_ms: i32) !Event {
    if (!try pollReadable(file, timeout_ms)) return .timeout;

    var reader_buf: [1]u8 = undefined;
    var file_reader = file.reader(io, &reader_buf);
    const reader = &file_reader.interface;

    var buf: [64]u8 = undefined;
    var len: usize = 0;
    while (len < buf.len) {
        const b = (try readByteOrNull(reader)) orelse return flush(buf[0..len]);
        buf[len] = b;
        len += 1;
        switch (parse(buf[0..len])) {
            .event => |e| return e.event,
            // Lone ESC, nothing else waiting -> Escape key.
            .incomplete => if (len == 1 and buf[0] == 0x1b and !(try pollReadable(file, 0))) {
                return flush(buf[0..1]);
            },
        }
    }
    return .invalid;
}

/// Detect Kitty keyboard support. Call in raw mode, before
/// the event loop (it drains the replies). `timeout_ms` bounds an unresponsive
/// terminal.
pub fn supportsKittyKeyboard(io: Io, file: Io.File, writer: *Io.Writer, timeout_ms: i32) !bool {
    try writer.writeAll("\x1b[?u\x1b[c"); // query + DA1
    try writer.flush();

    var reader_buf: [1]u8 = undefined;
    var file_reader = file.reader(io, &reader_buf);
    const reader = &file_reader.interface;

    // Read up to the DA1 'c' terminator ('c' can't appear in the Kitty reply).
    var buf: [64]u8 = undefined;
    var len: usize = 0;
    while (len < buf.len) {
        if (!try pollReadable(file, timeout_ms)) break;
        const b = (try readByteOrNull(reader)) orelse break;
        buf[len] = b;
        len += 1;
        if (b == 'c') break;
    }
    return kittyReplyPresent(buf[0..len]);
}

/// True if `bytes` contains a Kitty flags reply `CSI ? <digits> u`.
fn kittyReplyPresent(bytes: []const u8) bool {
    var i: usize = 0;
    while (i + 3 < bytes.len) : (i += 1) {
        if (bytes[i] != 0x1b or bytes[i + 1] != '[' or bytes[i + 2] != '?') continue;
        var j = i + 3;
        while (j < bytes.len and bytes[j] != 'u' and bytes[j] != 'c') : (j += 1) {}
        if (j < bytes.len and bytes[j] == 'u') return kittyFlagsResponse(bytes[i .. j + 1]) != null;
    }
    return false;
}

/// DECRPM mode state reported for a DECRQM query.
pub const ModeStatus = enum {
    not_recognized, // 0: unsupported
    set, // 1
    reset, // 2
    permanently_set, // 3
    permanently_reset, // 4

    /// Usable: recognized and not permanently disabled (excludes 0 and 4).
    pub fn supported(self: ModeStatus) bool {
        return switch (self) {
            .set, .reset, .permanently_set => true,
            .not_recognized, .permanently_reset => false,
        };
    }
};

/// Blocking DECRQM probe for `mode` (see `parseModeReport`); blocks the thread like `nextWithTimeout`.
pub fn queryModeWithTimeout(io: Io, file: Io.File, writer: *Io.Writer, mode: u16, timeout_ms: i32) !ModeStatus {
    try writer.print("\x1b[?{d}$p\x1b[c", .{mode}); // DECRQM + DA1 sentinel
    try writer.flush();

    var reader_buf: [1]u8 = undefined;
    var file_reader = file.reader(io, &reader_buf);
    const reader = &file_reader.interface;

    // Read until the DA1 'c'; the DECRPM reply precedes it.
    var buf: [64]u8 = undefined;
    var len: usize = 0;
    while (len < buf.len) {
        if (!try pollReadable(file, timeout_ms)) break;
        const b = (try readByteOrNull(reader)) orelse break;
        buf[len] = b;
        len += 1;
        if (b == 'c') break;
    }
    return parseModeReport(buf[0..len], mode);
}

/// Parse a DECRPM reply `CSI ? <mode> ; <status> $ y` for `mode`; missing reply or status 0 -> `not_recognized`.
pub fn parseModeReport(bytes: []const u8, mode: u16) ModeStatus {
    var i: usize = 0;
    while (i + 3 < bytes.len) : (i += 1) {
        if (bytes[i] != 0x1b or bytes[i + 1] != '[' or bytes[i + 2] != '?') continue;
        var j = i + 3;
        var m: u32 = 0;
        var got_mode = false;
        while (j < bytes.len and bytes[j] >= '0' and bytes[j] <= '9') : (j += 1) {
            m = m *% 10 +% (bytes[j] - '0');
            got_mode = true;
        }
        if (!got_mode or m != mode or j >= bytes.len or bytes[j] != ';') continue;
        j += 1;
        var s: u32 = 0;
        var got_status = false;
        while (j < bytes.len and bytes[j] >= '0' and bytes[j] <= '9') : (j += 1) {
            s = s *% 10 +% (bytes[j] - '0');
            got_status = true;
        }
        if (!got_status or j + 1 >= bytes.len or bytes[j] != '$' or bytes[j + 1] != 'y') continue;
        return switch (s) {
            1 => .set,
            2 => .reset,
            3 => .permanently_set,
            4 => .permanently_reset,
            else => .not_recognized,
        };
    }
    return .not_recognized;
}

/// Poll `file` for readability (ms; 0 = non-blocking, <0 = forever).
pub fn pollReadable(file: Io.File, timeout_ms: i32) !bool {
    switch (builtin.os.tag) {
        .linux, .macos => {
            var polls: [1]posix.pollfd = .{.{
                .fd = file.handle,
                .events = posix.POLL.IN,
                .revents = 0,
            }};
            return (try posix.poll(&polls, timeout_ms)) > 0;
        },
        .windows => {
            const t: windows.DWORD = if (timeout_ms < 0) winapiGlue.INFINITE else @intCast(timeout_ms);
            return winapiGlue.WaitForSingleObject(file.handle, t) == winapiGlue.WAIT_OBJECT_0;
        },
        else => return error.UnsupportedPlatform,
    }
}

fn readByteOrNull(reader: *Io.Reader) !?u8 {
    return reader.takeByte() catch |err| switch (err) {
        error.EndOfStream => null,
        else => return err,
    };
}

/// Byte-at-a-time escape/CSI state machine (DEC/ANSI VT500 model; credit Paul
/// Williams, vt100.net/emu/dec_ansi_parser).
const Parser = struct {
    state: State = .ground,

    // CSI params: `;` separates groups, `:` sub-params. `subparam[i]` marks a
    // `:`-continuation of the prior param's group (Kitty `key:… ; mods:event`).
    params: [16]u16 = undefined,
    subparam: [16]bool = undefined,
    param_count: usize = 0,
    param_cur: u32 = 0,
    param_digits: bool = false,
    pending_subparam: bool = false, // param being accumulated followed a `:`
    private: u8 = 0, // '<' '=' '>' '?' seen before params, else 0

    // UTF-8 assembly
    utf8: [4]u8 = undefined,
    utf8_len: u3 = 0,
    utf8_need: u3 = 0,

    // X10 mouse: three bytes after `ESC [ M`
    mouse: [3]u8 = undefined,
    mouse_len: u2 = 0,

    const State = enum { ground, escape, csi, ss3, mouse, utf8 };

    /// Feed one byte: an `Event` when a sequence completes, else null.
    fn step(p: *Parser, b: u8) ?Event {
        return switch (p.state) {
            .ground => p.ground(b),
            .escape => p.escape(b),
            .csi => p.csi(b),
            .ss3 => p.finishSs3(b),
            .mouse => p.stepMouse(b),
            .utf8 => p.stepUtf8(b),
        };
    }

    /// Back to a fresh ground state.
    fn reset(p: *Parser) void {
        p.* = .{};
    }

    /// Ground state: control chars, ESC, or a UTF-8 lead byte.
    fn ground(p: *Parser, b: u8) ?Event {
        switch (b) {
            0x1b => {
                p.state = .escape;
                return null;
            },
            0x08, 0x7f => return key(.backspace),
            0x09 => return key(.tab),
            0x0a, 0x0d => return key(.enter),
            // Ctrl+A..Z (tab / enter / backspace handled above)
            0x01...0x07, 0x0b...0x0c, 0x0e...0x1a => return keyMods(
                .{ .char = b + 'a' - 0x01 },
                .{ .ctrl = true },
            ),
            else => {
                const need = unicode.utf8ByteSequenceLength(b) catch return .invalid;
                if (need == 1) return emitChar(b);
                p.utf8[0] = b;
                p.utf8_len = 1;
                p.utf8_need = need;
                p.state = .utf8;
                return null;
            },
        }
    }

    /// Accumulate UTF-8 continuation bytes, then emit the codepoint.
    fn stepUtf8(p: *Parser, b: u8) ?Event {
        p.utf8[p.utf8_len] = b;
        p.utf8_len += 1;
        if (p.utf8_len < p.utf8_need) return null;
        const cp = decodeUtf8(p.utf8[0..p.utf8_len]) catch {
            p.reset();
            return .invalid;
        };
        p.reset();
        return emitChar(cp);
    }

    /// After ESC: CSI (`[`), SS3 (`O`), or an Alt / Ctrl+Alt char.
    fn escape(p: *Parser, b: u8) ?Event {
        switch (b) {
            '[' => {
                p.state = .csi;
                return null;
            },
            'O' => {
                p.state = .ss3;
                return null;
            },
            // ESC + ctrl char = ctrl+alt
            0x01...0x0c, 0x0e...0x1a => {
                p.reset();
                return keyMods(.{ .char = b + 0x60 }, .{ .ctrl = true, .alt = true });
            },
            // ESC + char = alt
            else => {
                p.reset();
                return keyMods(.{ .char = b }, .{ .alt = true });
            },
        }
    }

    /// CSI body: private marker, params, intermediates, then the final byte.
    fn csi(p: *Parser, b: u8) ?Event {
        switch (b) {
            '0'...'9' => {
                p.param_cur = p.param_cur *% 10 +% (b - '0');
                p.param_digits = true;
                return null;
            },
            ';' => {
                p.pushParam();
                p.pending_subparam = false;
                return null;
            },
            ':' => {
                p.pushParam();
                p.pending_subparam = true;
                return null;
            },
            '<', '=', '>', '?' => {
                p.private = b;
                return null;
            },
            0x20...0x2f => return null, // intermediate byte: ignored (pragmatic)
            'M' => {
                // Bare `ESC [ M` is X10 mouse (three bytes follow). With params
                // it is not (SGR mouse etc. — unsupported for now).
                if (p.private == 0 and p.param_count == 0 and !p.param_digits) {
                    p.state = .mouse;
                    p.mouse_len = 0;
                    return null;
                }
                p.reset();
                return .invalid;
            },
            0x40...0x4c, 0x4e...0x7e => {
                if (p.param_digits or p.param_count > 0) p.pushParam();
                const ev = p.dispatchCsi(b);
                p.reset();
                return ev;
            },
            else => {
                p.reset();
                return .invalid;
            },
        }
    }

    /// X10 mouse: three bias-32 bytes -> a Mouse event.
    fn stepMouse(p: *Parser, b: u8) ?Event {
        p.mouse[p.mouse_len] = b;
        p.mouse_len += 1;
        if (p.mouse_len < 3) return null;
        var m = parseMouseAction(p.mouse[0]) catch {
            p.reset();
            return .invalid;
        };
        m.x = p.mouse[1] -| 32;
        m.y = p.mouse[2] -| 32;
        p.reset();
        return .{ .mouse = m };
    }

    /// SS3 final byte -> F1-F4 / home / end.
    fn finishSs3(p: *Parser, b: u8) ?Event {
        p.reset();
        return switch (b) {
            'P' => key(.f1),
            'Q' => key(.f2),
            'R' => key(.f3),
            'S' => key(.f4),
            'H' => key(.home),
            'F' => key(.end),
            else => .invalid,
        };
    }

    /// Commit the current numeric param (default 0), reset the accumulator.
    fn pushParam(p: *Parser) void {
        if (p.param_count < p.params.len) {
            p.params[p.param_count] = if (p.param_digits) @truncate(p.param_cur) else 0;
            p.subparam[p.param_count] = p.pending_subparam;
            p.param_count += 1;
        }
        p.param_cur = 0;
        p.param_digits = false;
    }

    /// Value of sub-param `si` in `;`-group `gi` (0-based), or null if absent.
    fn groupSub(p: *Parser, gi: usize, si: usize) ?u16 {
        var g: usize = 0;
        var s: usize = 0;
        for (0..p.param_count) |i| {
            if (i != 0) {
                if (p.subparam[i]) s += 1 else {
                    g += 1;
                    s = 0;
                }
            }
            if (g == gi and s == si) return p.params[i];
        }
        return null;
    }

    /// Map a completed CSI sequence (params + final byte) to a key event.
    fn dispatchCsi(p: *Parser, final: u8) Event {
        const mods = if (p.param_count >= 2) modsFromParam(p.params[1]) else Modifiers{};
        switch (final) {
            'A' => return keyMods(.up, mods),
            'B' => return keyMods(.down, mods),
            'C' => return keyMods(.right, mods),
            'D' => return keyMods(.left, mods),
            'H' => return keyMods(.home, mods),
            'F' => return keyMods(.end, mods),
            'Z' => return keyMods(.tab, .{ .shift = true }),
            '~' => {
                const n = if (p.param_count >= 1) p.params[0] else 0;
                if (n == 200) return .paste_start;
                if (n == 201) return .paste_end;
                const code = tildeCode(n) orelse return .invalid;
                return keyMods(code, mods);
            },
            'u' => return p.dispatchKitty(),
            // In-band resize report `CSI 48 … t` (DEC mode 2048).
            't' => return if (p.param_count >= 1 and p.params[0] == 48) .resize else .invalid,
            else => return .invalid,
        }
    }

    /// Kitty `CSI key:… ; mods:event ; text u`. The `?`-private query response
    /// is not a key — use `kittyFlagsResponse` for that.
    fn dispatchKitty(p: *Parser) Event {
        if (p.private == '?') return .invalid;
        const cp = p.groupSub(0, 0) orelse return .invalid;
        const code = kittyKeyCode(cp) orelse return .invalid;
        const mods = if (p.groupSub(1, 0)) |m| modsFromParam(m) else Modifiers{};
        const event: KeyEvent = switch (p.groupSub(1, 1) orelse 1) {
            2 => .repeat,
            3 => .release,
            else => .press,
        };
        return .{ .key = .{ .code = code, .mods = mods, .event = event } };
    }
};

/// Key event, no modifiers.
fn key(code: KeyCode) Event {
    return .{ .key = .{ .code = code } };
}

/// Key event with modifiers.
fn keyMods(code: KeyCode, mods: Modifiers) Event {
    return .{ .key = .{ .code = code, .mods = mods } };
}

/// Uppercase ASCII is reported as shift + lowercase (legacy mibu behavior).
fn emitChar(cp: u21) Event {
    if (cp >= 'A' and cp <= 'Z') return keyMods(.{ .char = cp + 32 }, .{ .shift = true });
    return key(.{ .char = cp });
}

/// xterm modifier encoding: 1 + bitmask. Kitty adds 8/16/32 (super/hyper/meta);
/// 64/128 caps/num-lock ignored.
fn modsFromParam(v: u16) Modifiers {
    const m = if (v > 0) v - 1 else 0;
    return .{
        .shift = m & 1 != 0,
        .alt = m & 2 != 0,
        .ctrl = m & 4 != 0,
        .super = m & 8 != 0,
        .hyper = m & 16 != 0,
        .meta = m & 32 != 0,
    };
}

/// Kitty `CSI codepoint u` -> KeyCode. C0-legacy keys keep their ASCII codes;
/// functional keys live in the Unicode PUA.
fn kittyKeyCode(cp: u21) ?KeyCode {
    switch (cp) {
        13 => return .enter,
        9 => return .tab,
        27 => return .esc,
        8, 127 => return .backspace,
        else => {},
    }
    if (functionalKey(cp)) |code| return code;
    return .{ .char = cp };
}

/// Kitty functional-key codepoints (PUA 57344+); unmapped ones yield null.
fn functionalKey(cp: u21) ?KeyCode {
    return switch (cp) {
        57344 => .esc,
        57345 => .enter,
        57346 => .tab,
        57347 => .backspace,
        57348 => .insert,
        57349 => .delete,
        57350 => .left,
        57351 => .right,
        57352 => .up,
        57353 => .down,
        57354 => .page_up,
        57355 => .page_down,
        57356 => .home,
        57357 => .end,
        57364 => .f1,
        57365 => .f2,
        57366 => .f3,
        57367 => .f4,
        57368 => .f5,
        57369 => .f6,
        57370 => .f7,
        57371 => .f8,
        57372 => .f9,
        57373 => .f10,
        57374 => .f11,
        57375 => .f12,
        else => null,
    };
}

/// Parse a Kitty query response `CSI ? flags u` -> the flags bitmask, else null.
pub fn kittyFlagsResponse(bytes: []const u8) ?u8 {
    if (bytes.len < 4) return null;
    if (bytes[0] != 0x1b or bytes[1] != '[' or bytes[2] != '?') return null;
    if (bytes[bytes.len - 1] != 'u') return null;
    var flags: u16 = 0;
    for (bytes[3 .. bytes.len - 1]) |b| {
        if (b < '0' or b > '9') return null;
        flags = flags *% 10 +% (b - '0');
    }
    return @truncate(flags);
}

/// First param of a `~`-terminated CSI -> named key (home/insert/…/f-keys).
fn tildeCode(n: u16) ?KeyCode {
    return switch (n) {
        1 => .home,
        2 => .insert,
        3 => .delete,
        4 => .end,
        5 => .page_up,
        6 => .page_down,
        11 => .f1,
        12 => .f2,
        13 => .f3,
        14 => .f4,
        15 => .f5,
        17 => .f6,
        18 => .f7,
        19 => .f8,
        20 => .f9,
        21 => .f10,
        23 => .f11,
        24 => .f12,
        else => null,
    };
}

/// Decode 1-4 collected UTF-8 bytes into a codepoint.
fn decodeUtf8(bytes: []const u8) !u21 {
    return switch (bytes.len) {
        1 => bytes[0],
        2 => try unicode.utf8Decode2(bytes[0..2].*),
        3 => try unicode.utf8Decode3(bytes[0..3].*),
        4 => try unicode.utf8Decode4(bytes[0..4].*),
        else => error.Utf8InvalidStartByte,
    };
}

/// Next event from `reader`, blocking. Use `nextWithTimeout` for immediate lone-ESC on a terminal.
pub fn next(reader: *Io.Reader) !Event {
    var buf: [64]u8 = undefined;
    var len: usize = 0;
    while (len < buf.len) {
        const b = (try readByteOrNull(reader)) orelse return flush(buf[0..len]);
        buf[len] = b;
        len += 1;
        switch (parse(buf[0..len])) {
            .event => |e| return e.event,
            .incomplete => {},
        }
    }
    return .invalid;
}

/// Outcome of `parse`: a completed event (with bytes consumed) or `.incomplete`.
pub const ParseResult = union(enum) {
    event: struct { event: Event, consumed: usize },
    incomplete,
};

/// Parse one event from the front of `bytes` (slice driver over `Parser.step`).
/// `.incomplete` means `bytes` is a prefix of a longer sequence; feed more, then
/// re-parse. A lone/trailing ESC is `.incomplete` — resolve it with `flush`.
pub fn parse(bytes: []const u8) ParseResult {
    var p: Parser = .{};
    for (bytes, 0..) |b, i| {
        if (p.step(b)) |ev| return .{ .event = .{ .event = ev, .consumed = i + 1 } };
    }
    return .incomplete;
}

/// Resolve a buffer that will get no more bytes (ESC-timeout / EOF): lone ESC ->
/// Escape key, empty -> `.none`, any other partial -> `.invalid`.
pub fn flush(bytes: []const u8) Event {
    if (bytes.len == 0) return .none;
    if (bytes.len == 1 and bytes[0] == 0x1b) return key(.esc);
    return switch (parse(bytes)) {
        .event => |e| e.event,
        .incomplete => .invalid,
    };
}

fn parseMouseAction(action: u8) !Mouse {
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

// -- tests -----------------------------------------------------------------

const testing = std.testing;

/// Drive a fresh parser byte-by-byte; return the first completed event (or null).
fn feed(bytes: []const u8) ?Event {
    var p: Parser = .{};
    for (bytes) |b| {
        if (p.step(b)) |ev| return ev;
    }
    return null;
}

test "machine: arrow keys" {
    try testing.expect(feed("\x1b[A").?.key.code == .up);
    try testing.expect(feed("\x1b[B").?.key.code == .down);
    try testing.expect(feed("\x1b[C").?.key.code == .right);
    try testing.expect(feed("\x1b[D").?.key.code == .left);
}

test "machine: ctrl+right modified arrow" {
    const e = feed("\x1b[1;5C").?;
    try testing.expect(e.key.code == .right);
    try testing.expect(e.key.mods.ctrl and !e.key.mods.shift and !e.key.mods.alt);
}

test "machine: shift+alt up" {
    const e = feed("\x1b[1;4A").?;
    try testing.expect(e.key.code == .up);
    try testing.expect(e.key.mods.shift and e.key.mods.alt and !e.key.mods.ctrl);
}

test "machine: insert (fixed) and other tilde keys" {
    try testing.expect(feed("\x1b[2~").?.key.code == .insert);
    try testing.expect(feed("\x1b[3~").?.key.code == .delete);
    try testing.expect(feed("\x1b[5~").?.key.code == .page_up);
    try testing.expect(feed("\x1b[15~").?.key.code == .f5);
    try testing.expect(feed("\x1b[24~").?.key.code == .f12);
}

test "machine: bracketed paste markers" {
    try testing.expect(feed("\x1b[200~").? == .paste_start);
    try testing.expect(feed("\x1b[201~").? == .paste_end);
}

test "machine: in-band resize report (mode 2048)" {
    try testing.expect(feed("\x1b[48;24;80;600;800t").? == .resize);
    // A CSI ... t not led by 48 is not a resize.
    try testing.expect(feed("\x1b[8;24;80t").? == .invalid);
}

test "decrpm: mode status from a DECRQM reply" {
    try testing.expect(parseModeReport("\x1b[?2048;1$y", 2048) == .set);
    try testing.expect(parseModeReport("\x1b[?2026;2$y", 2026) == .reset);
    try testing.expect(parseModeReport("\x1b[?2004;3$y", 2004) == .permanently_set);
    // Status 0 (not recognized) and 4 (permanently reset, e.g. GNOME Terminal) are unusable.
    try testing.expect(parseModeReport("\x1b[?2048;0$y", 2048).supported() == false);
    try testing.expect(parseModeReport("\x1b[?2048;4$y", 2048).supported() == false);
    // Status 3 (permanently set) is usable.
    try testing.expect(parseModeReport("\x1b[?2026;3$y", 2026).supported() == true);
    // A reply for a different mode is not a match.
    try testing.expect(parseModeReport("\x1b[?2026;1$y", 2048) == .not_recognized);
    // Only a DA1 reply (terminal ignored DECRQM) -> not recognized.
    try testing.expect(parseModeReport("\x1b[?64;1c", 2048) == .not_recognized);
}

test "machine: ss3 function keys and home/end" {
    try testing.expect(feed("\x1bOP").?.key.code == .f1);
    try testing.expect(feed("\x1bOS").?.key.code == .f4);
    try testing.expect(feed("\x1bOH").?.key.code == .home);
    try testing.expect(feed("\x1bOF").?.key.code == .end);
}

test "machine: shift-tab" {
    const e = feed("\x1b[Z").?;
    try testing.expect(e.key.code == .tab and e.key.mods.shift);
}

test "machine: control chars" {
    const c = feed("\x01").?;
    try testing.expect(c.key.mods.ctrl and c.key.code.char == 'a');
    try testing.expect(feed("\r").?.key.code == .enter);
    try testing.expect(feed("\t").?.key.code == .tab);
    try testing.expect(feed("\x7f").?.key.code == .backspace);
}

test "machine: ascii and utf-8" {
    try testing.expect(feed("a").?.matchesChar('a', .{}));
    // é = U+00E9 = 0xC3 0xA9
    try testing.expect(feed("\xc3\xa9").?.key.code.char == 0xE9);
}

test "machine: alt+char" {
    const e = feed("\x1bx").?;
    try testing.expect(e.key.code.char == 'x' and e.key.mods.alt);
}

test "machine: partial sequences yield no event" {
    try testing.expect(feed("\x1b[") == null);
    try testing.expect(feed("\x1b[1;5") == null);
    try testing.expect(feed("\xc3") == null);
}

test "machine: x10 mouse" {
    // ESC [ M <button+32> <x+32> <y+32>; left press, x=1, y=2
    const e = feed("\x1b[M\x20\x21\x22").?;
    try testing.expect(e == .mouse);
    try testing.expect(e.mouse.button == .left);
    try testing.expect(e.mouse.x == 1 and e.mouse.y == 2);
}

test "kitty: plain codepoint" {
    const e = feed("\x1b[97u").?;
    try testing.expect(e.key.code.char == 'a');
    try testing.expect(@as(u6, @bitCast(e.key.mods)) == 0);
    try testing.expect(e.key.event == .press);
}

test "kitty: ctrl+a via modifier group" {
    const e = feed("\x1b[97;5u").?;
    try testing.expect(e.key.code.char == 'a');
    try testing.expect(e.key.mods.ctrl and !e.key.mods.shift and !e.key.mods.alt);
}

test "kitty: super modifier" {
    const e = feed("\x1b[97;9u").?;
    try testing.expect(e.key.mods.super and !e.key.mods.ctrl);
}

test "kitty: functional keys map to named codes" {
    try testing.expect(feed("\x1b[57352u").?.key.code == .up);
    try testing.expect(feed("\x1b[57356u").?.key.code == .home);
    try testing.expect(feed("\x1b[57364u").?.key.code == .f1);
    try testing.expect(feed("\x1b[57375u").?.key.code == .f12);
}

test "kitty: legacy C0 keys keep their code" {
    try testing.expect(feed("\x1b[13u").?.key.code == .enter);
    try testing.expect(feed("\x1b[9u").?.key.code == .tab);
    try testing.expect(feed("\x1b[27u").?.key.code == .esc);
    try testing.expect(feed("\x1b[127u").?.key.code == .backspace);
}

test "kitty: event type from second sub-param" {
    try testing.expect(feed("\x1b[97;1:1u").?.key.event == .press);
    try testing.expect(feed("\x1b[97;1:2u").?.key.event == .repeat);
    try testing.expect(feed("\x1b[97;1:3u").?.key.event == .release);
}

test "kitty: shift via mods keeps lowercase codepoint" {
    const e = feed("\x1b[97;2u").?;
    try testing.expect(e.key.code.char == 'a' and e.key.mods.shift);
}

test "kitty: query response is not a key event" {
    try testing.expect(feed("\x1b[?1u").? == .invalid);
}

test "kitty: parse flags response" {
    try testing.expectEqual(@as(?u8, 1), kittyFlagsResponse("\x1b[?1u"));
    try testing.expectEqual(@as(?u8, 25), kittyFlagsResponse("\x1b[?25u"));
    try testing.expectEqual(@as(?u8, null), kittyFlagsResponse("\x1b[?1"));
    try testing.expectEqual(@as(?u8, null), kittyFlagsResponse("\x1b[1u"));
}

test "kitty: reply detected only when it precedes DA1" {
    // Kitty reply then DA1 -> supported.
    try testing.expect(kittyReplyPresent("\x1b[?1u\x1b[?64;1c"));
    // DA1 only -> unsupported (the `?...c` is not a `?...u`).
    try testing.expect(!kittyReplyPresent("\x1b[?64;1c"));
    try testing.expect(!kittyReplyPresent(""));
}

test "parse: single char, one byte consumed" {
    const r = parse("a");
    try testing.expect(r == .event);
    try testing.expectEqual(@as(usize, 1), r.event.consumed);
    try testing.expect(r.event.event.matchesChar('a', .{}));
}

test "parse: arrow up, three bytes consumed" {
    const r = parse("\x1b[A");
    try testing.expectEqual(@as(usize, 3), r.event.consumed);
    try testing.expect(r.event.event.key.code == .up);
}

test "parse: consumes only the event's bytes" {
    const r = parse("\x1b[Ax"); // trailing 'x' left for the next parse
    try testing.expectEqual(@as(usize, 3), r.event.consumed);
}

test "parse: incomplete on partial or empty input" {
    try testing.expect(parse("\x1b[") == .incomplete);
    try testing.expect(parse("\x1b") == .incomplete);
    try testing.expect(parse("") == .incomplete);
}

test "flush: lone ESC resolves to escape, empty to none" {
    try testing.expect(flush("\x1b").key.code == .esc);
    try testing.expect(flush("") == .none);
}

test "flush: truncated sequence is invalid, complete one parses" {
    try testing.expect(flush("\x1b[") == .invalid);
    try testing.expect(flush("\x1b[A").key.code == .up);
}

test "next: reads one event from a reader" {
    var r = std.Io.Reader.fixed("\x1b[A");
    try testing.expect((try next(&r)).key.code == .up);
}

test "next: empty reader -> none" {
    var r = std.Io.Reader.fixed("");
    try testing.expect(try next(&r) == .none);
}

test "next: lone ESC at EOF -> esc" {
    var r = std.Io.Reader.fixed("\x1b");
    try testing.expect((try next(&r)).key.code == .esc);
}
