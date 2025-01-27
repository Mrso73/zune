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
        .transparent = true,
        .decorated = false,
    });
    defer window.deinit();

    // create a renderer
    var renderer = try zune.graphics.Renderer.init(allocator);
    defer renderer.deinit();


    // create a camera
    var perspective_camera = zune.core.Camera.initPerspective(std.math.degreesToRadians(45.0), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
    perspective_camera.setPosition(.{0.0, 0.0, -7.0});
    perspective_camera.lookAt(.{0.0, 0.0, 0.0});


    window.centerWindow();
    renderer.setActiveCamera(&perspective_camera);
    renderer.setClearColor(.{ 0.1, 0.1, 0.1, 1.0 });


    // ==== Create a mesh and model ==== \\

    var material = try zune.graphics.Material.init(&renderer.default_shader,.{ 0.8, 0.1, 0.4, 1.0 });
    var cube_mesh = try zune.graphics.Mesh.createCube(); defer cube_mesh.deinit();

    var cube = try zune.graphics.Model.initEmpty(allocator, 1, 1);
    defer cube.deinit();
    try cube.addMesh(&cube_mesh);
    try cube.addMaterial(&material);
    
    
    // Set viewport
    const window_size = window.getSize();
    renderer.setViewport(0, 0, @intCast(window_size.width), @intCast(window_size.height));

    const i: f32 = 0.05;
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

        //cube.transform.translate(0.0, -i, 0.0);
        cube.transform.rotate(i, i / 2, 0.0);

        // ==== Drawing to the screen ==== \\

        // Clear the window
        renderer.clear();
        zune.err.gl.checkGLError("after clear");

        renderer.drawModel(&cube) catch |err| {
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
