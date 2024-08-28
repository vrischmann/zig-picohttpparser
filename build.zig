const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "picohttpparser",
        .target = target,
        .optimize = optimize,
    });
    lib.addIncludePath(b.path("."));
    lib.linkLibC();
    lib.addCSourceFiles(.{
        .files = &lib_sources,
    });
    lib.installHeader(b.path("picohttpparser.h"), "picohttpparser.h");

    b.installArtifact(lib);

    // Zig specific module

    const mod = b.addModule("picohttpparser", .{
        .root_source_file = b.path("picohttpparser.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.addIncludePath(b.path("."));
    mod.linkLibrary(lib);

    // Tests

    const tests = b.addTest(.{
        .root_source_file = b.path("picohttpparser.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.linkLibrary(lib);
    tests.addIncludePath(b.path("."));

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run the tests");
    test_step.dependOn(&run_tests.step);

    // C tests

    const c_tests = b.addExecutable(.{
        .name = "c_test",
        .target = target,
        .optimize = optimize,
    });
    c_tests.linkLibrary(lib);
    c_tests.addIncludePath(b.path("."));
    c_tests.addIncludePath(b.path("picotest"));
    c_tests.addCSourceFiles(.{
        .files = &c_test_sources,
    });

    const run_c_tests = b.addRunArtifact(c_tests);
    const c_test_step = b.step("c-test", "Run the C tests");
    c_test_step.dependOn(&run_c_tests.step);

    //

}

const lib_sources = [_][]const u8{
    "picohttpparser.c",
};

const c_test_sources = [_][]const u8{
    "picotest/picotest.c",
    "test.c",
};
