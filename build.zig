const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // NOTE(vincent): the upstream module containing the actual C library is also named picohttpparser.

    const picohttpparser = b.dependency("picohttpparser", .{
        .target = target,
        .optimize = optimize,
    });

    //
    // Main module
    //

    const mod = b.addModule("picohttpparser", .{
        .root_source_file = b.path("picohttpparser.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addIncludePath(picohttpparser.path("."));
    mod.linkLibrary(picohttpparser.artifact("picohttpparser"));

    //
    // Tests
    //

    const tests_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("picohttpparser.zig"),
    });
    tests_mod.addIncludePath(picohttpparser.path("."));
    tests_mod.linkLibrary(picohttpparser.artifact("picohttpparser"));

    const tests = b.addTest(.{
        .root_module = tests_mod,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run the tests");
    test_step.dependOn(&run_tests.step);

    //
    // Example module and binary
    //

    const example_mod = b.createModule(.{
        .root_source_file = b.path("example/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const example = b.addExecutable(.{
        .name = "example",
        .root_module = example_mod,
    });

    example.root_module.addImport("picohttpparser", mod);

    const example_run_cmd = b.addRunArtifact(example);
    if (b.args) |args| {
        example_run_cmd.addArgs(args);
    }

    const example_run = b.step("example", "Run the example");
    example_run.dependOn(&example_run_cmd.step);
}
