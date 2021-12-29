const std = @import("std");

const Event = union(enum) {
    terminal_bell,
    backspace,
    horizontal_tab,
    new_line,
    vertical_tab,
    formfeed,
    carriage_return,
    escape,
    delete,

    fun: u8,
    char: u8,
    alt: u8,
    ctrl: u8,

    // pub fn from(reader:
};
