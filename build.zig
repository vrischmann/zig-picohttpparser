const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // NOTE(vincent): the upstream module containing the actual C library is also named picohttpparser.

    const picohttpparser = b.dependency("picohttpparser", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("picohttpparser", .{
        .root_source_file = b.path("picohttpparser.zig"),
        .target = target,
        .optimize = optimize,
        // .link_libc = true,
    });
    mod.addIncludePath(picohttpparser.path("."));
    mod.linkLibrary(picohttpparser.artifact("picohttpparser"));

    const tests = b.addTest(.{
        .root_source_file = b.path("picohttpparser.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.addIncludePath(picohttpparser.path("."));
    tests.linkLibrary(picohttpparser.artifact("picohttpparser"));

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run the tests");
    test_step.dependOn(&run_tests.step);
}
