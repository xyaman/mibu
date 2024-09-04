#  mibu

**mibu** is pure Zig library for low-level terminal manipulation.

> Tested with zig version `0.13.0`

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

First we add the library as a dependency in our `build.zig.zon` file.
```zig
.dependencies = .{
    .string = .{
        .url = "https://github.com/xyaman/mibu/archive/refs/heads/main.zip",
        //the correct hash will be suggested by the zig compiler, you can copy it from there
    }
}
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
