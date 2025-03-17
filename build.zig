const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const soulib = b.addLibrary(.{
        .linkage = .static,
        .name = "soulib",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(soulib);

    const test_step = b.step("test", "Run unit tests");
    const unit_test = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const lib_unit_test = b.addRunArtifact(unit_test);
    test_step.dependOn(&lib_unit_test.step);
}
