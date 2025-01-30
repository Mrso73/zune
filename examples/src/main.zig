const std = @import("std");
const zune = @import("zune"); // The engine
const c = @import("zune").c;

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
        .target_fps = 120,
        .fixed_timestep = 1.0 / 60.0,
    });

    // TODO: setup input manager

    // create a window
    const window = try zune.core.Window.init(allocator, .{
        .title = "zune example-1",
        .width = WINDOW_WIDTH,
        .height = WINDOW_HEIGHT,
        .transparent = true,
        .decorated = true,
    });
    defer window.deinit();

    // create a renderer
    var renderer = try zune.graphics.Renderer.init(allocator);
    defer renderer.deinit();

    const window_size = window.getSize();
    renderer.setViewport(0, 0, @intCast(window_size.width), @intCast(window_size.height));

    // create a camera
    var perspective_camera = zune.core.Camera.initPerspective(std.math.degreesToRadians(45.0), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
    perspective_camera.setPosition(.{0.0, 0.0, -7.0});
    perspective_camera.lookAt(.{0.0, 0.0, 0.0});


    const initial_mouse_pos = window.getCursorPos();
    var camera_controller = zune.core.CameraMouseController.init(&perspective_camera,
    @as(f32, @floatCast(initial_mouse_pos.x)), @as(f32, @floatCast(initial_mouse_pos.y)));
    




    window.centerWindow();
    window.setCursorMode(.disabled);
    renderer.setActiveCamera(&perspective_camera);
    renderer.setClearColor(.{ 0.1, 0.1, 0.1, 1.0 });


    // ==== Create a mesh and model ==== \\

    var material_1 = try zune.graphics.Material.init(&renderer.default_shader,.{ 0.8, 0.1, 0.4, 1.0 });
    var material_2 = try zune.graphics.Material.init(&renderer.default_shader,.{ 0.8, 0.1, 0.4, 1.0 });

    var cube_mesh = try zune.graphics.Mesh.createCube();
    defer cube_mesh.deinit();

    var cube_model_1 = try zune.graphics.Model.initEmpty(allocator, 1, 1);
    var cube_model_2 = try zune.graphics.Model.initEmpty(allocator, 1, 1);
    defer cube_model_1.deinit();
    defer cube_model_2.deinit();

    try cube_model_1.addMesh(&cube_mesh);
    try cube_model_2.addMesh(&cube_mesh);

    try cube_model_1.addMaterial(&material_1);
    try cube_model_2.addMaterial(&material_2);

    cube_model_2.transform.setPosition(0.0, 1, 0.0);
    
    
    // Set viewport
    
    const i: f32 = 0.05;
    while (!window.shouldClose()) {

        // ==== Update Variables ==== \\  
        const mouse_pos = window.getCursorPos();
        time.update();

        // Get delta time
        const dt = time.getDelta();


        // ==== Process Input ==== \\        
        camera_controller.handleMouseMovement(@as(f32, @floatCast(mouse_pos.x)), @as(f32, @floatCast(mouse_pos.y)), dt);


        // ==== Update Program ==== \\
        // Fixed updates (at fixed timestep intervals)
        while (time.shouldFixedUpdate()) {
            const fixed_dt = time.getFixedTimestep();
            _ = fixed_dt;
            // Update physics with fixed_dt...
        }

        cube_model_1.transform.rotate(i, i / 2, 0.0);


        // ==== Drawing to the screen ==== \\

        // Clear the window
        renderer.clear();
        zune.err.gl.checkGLError("after clear");

        try renderer.drawModel(&cube_model_1);
        try renderer.drawModel(&cube_model_2);
    

        window.pollEvents();
        window.swapBuffers();
    }
}
