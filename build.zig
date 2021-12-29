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
    const example = b.addExecutable("example", "examples/print.zig");
    example.setTarget(target);
    example.addPackagePath("mibu", "src/main.zig");

    const example_step = b.step("example1", "Run example 1");
    example_step.dependOn(&example.run().step);
}
