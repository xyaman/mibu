const std = @import("std");
const Io = std.Io;
const builtin = @import("builtin");
const posix = std.posix;
const windows = std.os.windows;
const winapiGlue = @import("winapiGlue.zig");
const color = @import("color.zig");

/// 16-bit per-channel RGB as returned by OSC 11 (values 0–65535).
/// This is intentionally different from color.Rgb (u8 per channel).
pub const Rgb16 = struct {
    r: u16,
    g: u16,
    b: u16,

    /// Convert to 8-bit per channel for use with color.fgRGB / color.bgRGB.
    pub fn to8(self: Rgb16) color.Rgb {
        return .{
            .r = @intCast(self.r >> 8),
            .g = @intCast(self.g >> 8),
            .b = @intCast(self.b >> 8),
        };
    }

    pub fn format(this: @This(), writer: *Io.Writer) Io.Writer.Error!void {
        try writer.print("Rgb16{{ r: {d}, g: {d}, b: {d} }}", .{ this.r, this.g, this.b });
    }
};

pub const Theme = enum { dark, light };

/// Query the terminal background color via OSC 11 with a CSI 6n discriminator.
/// The terminal MUST already be in raw mode before calling this function.
/// Blocks until a response is received.
/// Returns error.NotSupported if the terminal ignores OSC 11.
pub fn detect(io: Io, input: Io.File, output: *Io.Writer) !Rgb16 {
    return detectImpl(io, input, output, -1);
}

/// Like detect, but returns error.Timeout if no response arrives within timeout_ms.
pub fn detectWithTimeout(io: Io, input: Io.File, output: *Io.Writer, timeout_ms: u32) !Rgb16 {
    return detectImpl(io, input, output, @intCast(timeout_ms));
}

fn detectImpl(io: Io, input: Io.File, output: *Io.Writer, timeout: i32) !Rgb16 {
    try output.writeAll("\x1b]11;?\x1b\\" ++ "\x1b[6n");
    try output.flush();

    var buf: [128]u8 = undefined;
    var n: usize = 0;

    switch (builtin.os.tag) {
        .linux, .macos => {
            var polls: [1]posix.pollfd = .{.{
                .fd = input.handle,
                .events = posix.POLL.IN,
                .revents = 0,
            }};
            if (try posix.poll(&polls, timeout) == 0) return error.Timeout;
            n = try posix.read(input.handle, buf[0..]);
            // If the first read didn't contain the OSC 11 response, keep
            // polling. This handles ConPTY (WSL) where the cursor position
            // report (CSI 6n) arrives before the OSC 11 response because
            // ConPTY answers CSI 6n itself without a terminal round-trip.
            while (std.mem.indexOf(u8, buf[0..n], "rgb:") == null) {
                if (n == buf.len) break;
                if (try posix.poll(&polls, 50) == 0) break;
                n += try posix.read(input.handle, buf[n..]);
            }
        },
        .windows => {
            const t: windows.DWORD = if (timeout < 0) winapiGlue.INFINITE else @intCast(timeout);
            if (winapiGlue.WaitForSingleObject(input.handle, t) == winapiGlue.WAIT_TIMEOUT_VAL) {
                return error.Timeout;
            }
            n = try input.readStreaming(io, &.{buf[0..]});
            if (n < buf.len and winapiGlue.WaitForSingleObject(input.handle, 50) == winapiGlue.WAIT_OBJECT_0) {
                n += try input.readStreaming(io, &.{buf[n..]});
            }
        },
        else => return error.UnsupportedPlatform,
    }

    return try parseOsc11(buf[0..n]);
}

/// Returns .dark or .light based on WCAG relative luminance of the background.
pub fn theme(rgb: Rgb16) Theme {
    const coeff = [3]f64{ 0.2126, 0.7152, 0.0722 };
    const channels = [3]f64{
        @as(f64, @floatFromInt(rgb.r)) / 65535.0,
        @as(f64, @floatFromInt(rgb.g)) / 65535.0,
        @as(f64, @floatFromInt(rgb.b)) / 65535.0,
    };
    var sum: f64 = 0;
    for (channels, coeff) |x, c| {
        sum += (if (x == 0) 0 else @exp(@log(x) * 2.2)) * c;
    }
    const lum = @round(sum * 1000.0) / 1000.0;
    return if (lum < 0.36) .dark else .light;
}

fn parseOsc11(buf: []const u8) !Rgb16 {
    const idx = std.mem.indexOf(u8, buf, "rgb:") orelse return error.NotSupported;
    const rest = buf[idx + 4 ..];

    const s1 = std.mem.indexOfScalar(u8, rest, '/') orelse return error.InvalidFormat;
    const r = parseHexChannel(rest[0..s1]) catch return error.InvalidFormat;

    const rest2 = rest[s1 + 1 ..];
    const s2 = std.mem.indexOfScalar(u8, rest2, '/') orelse return error.InvalidFormat;
    const g = parseHexChannel(rest2[0..s2]) catch return error.InvalidFormat;

    const rest3 = rest2[s2 + 1 ..];
    var b_end: usize = 0;
    while (b_end < rest3.len and b_end < 4) : (b_end += 1) {
        const c = rest3[b_end];
        // check if it's hex char
        if (!((c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F'))) break;
    }

    const b = parseHexChannel(rest3[0..b_end]) catch return error.InvalidFormat;

    return Rgb16{ .r = r, .g = g, .b = b };
}

/// Parse 1–4 hex digits and normalise to u16.
fn parseHexChannel(s: []const u8) !u16 {
    if (s.len == 0 or s.len > 4) return error.InvalidFormat;
    const val = try std.fmt.parseInt(u16, s, 16);
    return if (s.len <= 2) (val << 8) | val else val;
}

test "parseOsc11 black background (16-bit)" {
    const buf = "\x1b]11;rgb:0000/0000/0000\x07";
    const rgb = try parseOsc11(buf);
    try std.testing.expectEqual(@as(u16, 0x0000), rgb.r);
    try std.testing.expectEqual(@as(u16, 0x0000), rgb.g);
    try std.testing.expectEqual(@as(u16, 0x0000), rgb.b);
}

test "parseOsc11 white background (16-bit)" {
    const buf = "\x1b]11;rgb:ffff/ffff/ffff\x07";
    const rgb = try parseOsc11(buf);
    try std.testing.expectEqual(@as(u16, 0xffff), rgb.r);
    try std.testing.expectEqual(@as(u16, 0xffff), rgb.g);
    try std.testing.expectEqual(@as(u16, 0xffff), rgb.b);
}

test "parseOsc11 white background (8-bit legacy)" {
    const buf = "\x1b]11;rgb:ff/ff/ff\x07";
    const rgb = try parseOsc11(buf);
    try std.testing.expectEqual(@as(u16, 0xffff), rgb.r);
    try std.testing.expectEqual(@as(u16, 0xffff), rgb.g);
    try std.testing.expectEqual(@as(u16, 0xffff), rgb.b);
}

test "parseOsc11 typical dark background" {
    const buf = "\x1b]11;rgb:1e1e/1e1e/2e2e\x1b\\";
    const rgb = try parseOsc11(buf);
    try std.testing.expectEqual(@as(u16, 0x1e1e), rgb.r);
    try std.testing.expectEqual(@as(u16, 0x1e1e), rgb.g);
    try std.testing.expectEqual(@as(u16, 0x2e2e), rgb.b);
}

test "parseOsc11 with surrounding CSI 6n response" {
    const buf = "\x1b]11;rgb:ffff/ffff/ffff\x07\x1b[35;80R";
    const rgb = try parseOsc11(buf);
    try std.testing.expectEqual(@as(u16, 0xffff), rgb.r);
    try std.testing.expectEqual(@as(u16, 0xffff), rgb.g);
    try std.testing.expectEqual(@as(u16, 0xffff), rgb.b);
}

test "parseOsc11 not supported (only CSI 6n)" {
    const buf = "\x1b[35;80R";
    try std.testing.expectError(error.NotSupported, parseOsc11(buf));
}

test "parseHexChannel 8-bit to 16-bit expansion" {
    try std.testing.expectEqual(@as(u16, 0xffff), try parseHexChannel("ff"));
    try std.testing.expectEqual(@as(u16, 0x0000), try parseHexChannel("00"));
    try std.testing.expectEqual(@as(u16, 0x8080), try parseHexChannel("80"));
}

test "parseHexChannel 16-bit passthrough" {
    try std.testing.expectEqual(@as(u16, 0xffff), try parseHexChannel("ffff"));
    try std.testing.expectEqual(@as(u16, 0x0000), try parseHexChannel("0000"));
    try std.testing.expectEqual(@as(u16, 0x1e1e), try parseHexChannel("1e1e"));
}
