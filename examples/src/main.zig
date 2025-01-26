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


    //setup time utitilites
    var time = zune.utils.Time.Time.init(.{
        .target_fps = 60,
        .fixed_timestep = 1.0 / 60.0,
    });


    // TODO: setup input manager


    // create a window
    const window = try zune.core.Window.init(allocator, .{
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


    // create a camera
    var camera = zune.core.PerspectiveCamera.init(std.math.degreesToRadians(45.0), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
    camera.setPosition(0.0, 0.0, 5.0);
    camera.lookAt(0.0, 0.0, 0.0); // z maybe -1

    renderer.setActiveCamera(&camera); 

    window.centerWindow();
    renderer.setClearColor(.{ 0.1, 0.1, 0.1, 1.0 });


    // ==== Create a mesh ==== \\

    // Create a simple triangle mesh
    const vertices = [_]f32{
        0.0,  0.5, 0.0,   0.5, 1.0, // top
        -0.5, -0.5, 0.0,   0.0, 0.0, // left
        0.5, -0.5, 0.0,   1.0, 0.0, // right
    };
    const indices = [_]u32{ 0, 1, 2 };

    
    // Create triangle mesh using vertices and indices
    var triangle_mesh = try zune.graphics.Mesh.init(&vertices, &indices, zune.graphics.VertexLayout.PosTex());
    var material = try zune.graphics.Material.init(&renderer.default_shader,.{ 0.8, 0.1, 0.4, 1.0 });
    defer triangle_mesh.deinit();


    // Set viewport
    const window_size = window.getSize();
    renderer.setViewport(0, 0, @intCast(window_size.width), @intCast(window_size.height));


    // Simple model matrix (identity)
    const model_matrix = [16]f32{
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    };
    

    while (!window.shouldClose()) {

        // ==== Set Time variables ==== \\
        time.update();

        // Get delta time
        //const dt = time.getDelta();


        // ==== Process Input ==== \\



        // ==== Update Program ==== \\
        // Fixed updates (at fixed timestep intervals)
        while (time.shouldFixedUpdate()) {
            const fixed_dt = time.getFixedTimestep();
            _ = fixed_dt;
            // Update physics with fixed_dt...
        }


        // ==== Drawing to the screen ==== \\

        // Clear the window
        renderer.clear();
        zune.err.gl.checkGLError("after clear");
 
        // Draw the triangle mesh
        renderer.drawMesh(&triangle_mesh, &material, &model_matrix) catch |err| {
            std.debug.print("Error during rendering: {any}\n", .{err});
        };
        zune.err.gl.checkGLError("After draw");


        // ==== Print Game Info ==== \\
        
        // Print FPS every second
        if (time.fps.timer >= 1.0) {
            std.debug.print("FPS: {d:.2}\n", .{time.getFPS()});
        }

        window.pollEvents();
        window.swapBuffers();
    }
}
