const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("mibu", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    // examples
    const color = b.addExecutable("color", "examples/color.zig");
    color.setTarget(target);
    color.addPackagePath("mibu", "src/main.zig");

    const color_step = b.step("color", "Run color example");
    color_step.dependOn(&color.run().step);

    const event = b.addExecutable("event", "examples/event.zig");
    event.setTarget(target);
    event.addPackagePath("mibu", "src/main.zig");

    const event_step = b.step("event", "Run event example");
    event_step.dependOn(&event.run().step);
}
