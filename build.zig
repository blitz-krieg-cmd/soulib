const std = @import("std");

const Program = struct {
    name: []const u8,
    path: []const u8,
    desc: []const u8,
};

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

    const examples = [_]Program{
        .{
            .name = "read_dcx",
            .path = "examples/read_dcx.zig",
            .desc = "Reads a DCX file.",
        },
    };

    const examples_step = b.step("examples", "Builds all the examples");

    for (examples) |example| {
        const exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = b.path(example.path),
            .target = target,
            .optimize = optimize,
        });
        exe.linkLibrary(soulib);
        exe.root_module.addImport("soulib", soulib.root_module);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step(example.name, example.desc);

        run_step.dependOn(&run_cmd.step);
        examples_step.dependOn(&exe.step);
    }

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
