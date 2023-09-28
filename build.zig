const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mibu_module = b.addModule("mibu", .{ .source_file = .{ .path = "src/main.zig" }});

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    // examples
    const color = b.addExecutable(.{
        .name = "color",
        .root_source_file = .{ .path = "examples/color.zig" },
        .target = target,
        .optimize = optimize,
    });
    color.addModule("mibu", mibu_module);
    const color_step = b.addRunArtifact(color);

    const run_color_step = b.step("color", "Run color example");
    run_color_step.dependOn(&color_step.step);

    const event = b.addExecutable(.{
        .name = "event",
        .root_source_file = .{ .path = "examples/event.zig" },
        .target = target,
        .optimize = optimize,
    });
    event.addModule("mibu", mibu_module);
    const event_step = b.addRunArtifact(event);

    const run_event_step = b.step("event", "Run event example");
    run_event_step.dependOn(&event_step.step);
}
