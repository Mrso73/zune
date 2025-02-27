const std = @import("std");
const zune = @import("zune"); // The engine

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 900;


pub fn main() !void {

    // ==== Initializing Everything ==== \\
    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();


    // create a window
    var window = try zune.core.Window.create(allocator, .{
        .title = "zune window-example",
        .width = WINDOW_WIDTH,
        .height = WINDOW_HEIGHT,
    });
    defer window.release();
    

    // create a renderer
    var renderer = try zune.graphics.Renderer.create(allocator);
    defer renderer.release();


    // Set values
    const window_size = window.getSize();
    renderer.setViewport(0, 0, @intCast(window_size.width), @intCast(window_size.height));
    renderer.setClearColor(.{ 0.1, 0.1, 0.1, 1.0 });

    window.centerWindow();


    // Main loop
    while (!window.shouldClose()) {

        // Clear the window
        renderer.clear();

        try window.pollEvents();
        window.swapBuffers();
    }
}
