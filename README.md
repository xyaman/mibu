#  mibu

**mibu** is pure Zig library for low-level terminal manipulation.

> Tested with zig version `0.13.0`

## Features
- Allocation free.
- UTF-8 support.
- Style (bold, italic, underline, etc).
- Raw mode.
- 8-16 colors.
- True Color (24-bit RGB).
- Cursor controls.
- Clear(Erase) functions.
- Key events.

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

- Support mouse events
- Support more keys events
