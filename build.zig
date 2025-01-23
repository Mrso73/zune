const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{
        .cpu_arch = .x86_64,
        .os_tag = .windows,
        .abi = .gnu,
    } });
    const optimize = b.standardOptimizeOption(.{});

    const libzune = b.addModule("zune", .{
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .target = target,
    });
    libzune.addIncludePath(b.path("dependencies/include/"));
    libzune.addObjectFile(b.path("dependencies/lib/libglfw3.a"));
    libzune.addCSourceFile(.{ .file = b.path("dependencies/lib/glad.c") });

    const exe = b.addExecutable(.{
        .name = "example-01",
        .root_source_file = b.path("examples/src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zune", libzune);

    exe.linkLibC();

    // Windows-specific libraries
    exe.linkSystemLibrary("gdi32");
    exe.linkSystemLibrary("user32");
    exe.linkSystemLibrary("kernel32");
    exe.linkSystemLibrary("opengl32");

    b.installArtifact(exe);

    // -----------------------------

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
