> [!WARNING]
> This library is a WIP and may have breaking changes and bugs.

#  mibu

**mibu** is pure Zig library for low-level terminal manipulation.

> Tested with zig version `2024.11.0-mach` (0.14.0-dev.2577+271452d22)

## Features
- Allocation free.
- UTF-8 support.
- Style (bold, italic, underline, etc).
- Termios / Raw mode.
- 8-16 colors.
- True Color (24-bit RGB).
- Cursor controls.
- Clear(Erase) functions.
- Key events.
- Partial Mouse events. (Click, Scroll, Release)

## How to use

First we add the library as a dependency in our `build.zig.zon` file with the 
following command.
```bash
zig fetch --save git+https://github.com/xyaman/mibu
```

And we add it to `build.zig` file.
```zig
const mibu_dep = b.dependency("mibu", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("mibu", mibu_dep.module("mibu"));
```

Now we can use the library in our code.
```zig
const std = @import("std");
const mibu = @import("mibu");
const color = mibu.color;

pub fn main() void {
    std.debug.print("{s}Hello World in purple!\n", .{color.print.bgRGB(97, 37, 160)});
}
```

## Getting Started

See the [examples directory](examples/)

You can run the examples with the following command:
```bash
# Prints text with different colors
zig build color

# Prints what key you pressed, until you press `q` or `ctrl+c`
zig build event

zig build alternate_screen
```

## TODO

- Mouse events
    - [x] Left, middle, right click
    - [x] Scroll up, down
    - [x] Release
    - [x] Modifiers (shift, ctrl, alt)
    - [x] Move 
    - [ ] Click and move (drag)
- Support all keys events

# Projects that use `mibu`
- [zigtris](https://github.com/ringtailsoftware/zigtris)
- [chip8 (wip)](https://github.com/xyaman/chip8)
