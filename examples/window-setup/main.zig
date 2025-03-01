const std = @import("std");
const zune = @import("zune"); // The engine

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 900;


pub fn main() !void {

    // ==== Initializing Everything ==== //

    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();


    // create a window
    var window = try zune.core.Window.create(allocator, .{
        .title = "zune window-example",
        .width = WINDOW_WIDTH,
        .height = WINDOW_HEIGHT,
    });
    defer window.release();

    const window_size = window.getSize();

    window.centerWindow();
    window.setCursorMode(.disabled);
    

    // create a Renderer
    var renderer = try zune.graphics.Renderer.create(allocator, .{
        .clear_color = .{ 0.1, 0.1, 0.1, 1.0 },
        .initial_viewport = .{
            .x = 0,
            .y = 0,
            .width = @intCast(window_size.width),
            .height = @intCast(window_size.height)
        }
    });
    defer renderer.release();



    // ==== Main Loop ==== //

    while (!window.shouldClose()) {
        
        // ==== Update Variables ==== //


        // ==== Drawing to the screen ==== //


        // ==== Update Program ==== //


        // ==== Drawing to the screen ==== //
        renderer.clear();

        try window.pollEvents();
        window.swapBuffers();
    }
}
