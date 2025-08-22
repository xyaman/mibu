#  mibu

**mibu** is a pure Zig library for low-level terminal manipulation.

**Status:** This library is in beta. Breaking changes may occur.

> Tested with zig version `0.15.1` (release)

## Features
- Zero heap allocations.
- UTF-8 character support.
- Terminal raw mode support.
- Text styling: bold, italic, underline.
- Color output: supports 8, 16, and true color (24-bit).
- Cursor movement and positioning functions.
- Screen clearing and erasing utilities.
- Key event handling: codepoints, modifiers, and special keys.
- Mouse event handling: click, scroll, and release actions.

## How to use

Add the library as a dependency in your `build.zig.zon` file:
```bash
zig fetch --save git+https://github.com/xyaman/mibu
```

Import the dependency in your `build.zig` file:
```zig
const mibu_dep = b.dependency("mibu", .{});
exe.root_module.addImport("mibu", mibu_dep.module("mibu"));
```

Use the library in your Zig code:
```zig
const std = @import("std");
const mibu = @import("mibu");
const color = mibu.color;

pub fn main() void {
    std.debug.print("{s}Hello World in purple!\n", .{color.print.bgRGB(97, 37, 160)});
}
```

## Getting Started

See the [examples directory](examples/).

You can run the examples with the following command:
```bash
# Prints text with different colors
zig build color

# Prints what key you pressed, until you press `q` or `ctrl+c`
zig build event

zig build alternate_screen
```

## TODO

- [ ] Mouse: Click and move (drag)

## Projects that use `mibu`
- [zigtris](https://github.com/ringtailsoftware/zigtris)
- [chip8 emulator (wip)](https://github.com/xyaman/chip8)
