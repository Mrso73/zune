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
    var window = try zune.core.Window.init(allocator, .{
        .title = "zune example-1",
        .width = WINDOW_WIDTH,
        .height = WINDOW_HEIGHT,
        .transparent = false,
        .decorated = true,
    });
    defer window.deinit();
    


    // create a renderer
    var renderer = try zune.graphics.Renderer.init(allocator);
    defer renderer.deinit();


    
    // Set values
    const window_size = window.getSize();
    renderer.setViewport(0, 0, @intCast(window_size.width), @intCast(window_size.height));

    window.centerWindow();
    renderer.setClearColor(.{ 0.1, 0.1, 0.1, 1.0 });





    while (!window.shouldClose()) {

        // Clear the window
        renderer.clear();
        zune.err.gl.checkGLError("after clear");

        window.pollEvents();
        window.swapBuffers();
    }
}
