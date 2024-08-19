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
