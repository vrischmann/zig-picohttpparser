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

    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("picohttpparser.zig"),
    });
    tests.addIncludePath(picohttpparser.path("."));
    tests.linkLibrary(picohttpparser.artifact("picohttpparser"));

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run the tests");
    test_step.dependOn(&run_tests.step);

    //
    // Example executables
    //

    addExample(b, mod, "parse_request", "example/parse_request.zig", target, optimize);
    addExample(b, mod, "parse_response", "example/parse_response.zig", target, optimize);
}

/// Helper function to add example binaries.
fn addExample(
    b: *std.Build,
    mod: *std.Build.Module,
    name: []const u8,
    path: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const example = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path(path),
        .target = target,
        .optimize = optimize,
    });

    example.root_module.addImport("picohttpparser", mod);

    const example_run_cmd = b.addRunArtifact(example);
    if (b.args) |args| {
        example_run_cmd.addArgs(args);
    }

    const example_run = b.step(name, b.fmt("Run {s} example", .{name}));
    example_run.dependOn(&example_run_cmd.step);
}
