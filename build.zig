const std = @import("std");

pub fn build(b: *std.Build) void {
    // Set target and optimization
    const target = b.standardTargetOptions(.{ .default_target = .{
        .cpu_arch = .x86_64,
        .os_tag = .windows,
        .abi = .gnu,
    } });
    const optimize = b.standardOptimizeOption(.{});

    // Create the zune module that will be shared across all examples
    const libzune = b.addModule("zune", .{
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .target = target,
    });
    libzune.addIncludePath(b.path("dependencies/include/"));
    libzune.addObjectFile(b.path("dependencies/lib/libglfw3.a"));
    libzune.addCSourceFile(.{ .file = b.path("dependencies/lib/glad.c") });

    // Define the examples
    const examples = .{
        "window-setup",
        "entity-creation",
        "camera-controller",
    };

    // create example executable
    inline for (examples) |example_name| {
        const exe = b.addExecutable(.{
            .name = example_name,
            .root_source_file = b.path("examples/" ++ example_name ++ "/main.zig"),
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

        // Create install step
        const install_step = b.addInstallArtifact(exe, .{});
        const install_example = b.step("install-" ++ example_name, "Install the " ++ example_name ++ " example");
        install_example.dependOn(&install_step.step);

        // Create run step
        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        // Create a specialized run step for this example
        const run_step = b.step("run-" ++ example_name, "Run the " ++ example_name ++ " example");
        run_step.dependOn(&install_step.step);
        run_step.dependOn(&run_cmd.step);
    }
}