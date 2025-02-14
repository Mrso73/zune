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
    var time = zune.core.Time.init(.{
        .target_fps = 120,
        .fixed_timestep = 1.0 / 60.0,
    });


    // create a window
    var window = try zune.core.Window.create(allocator, .{
        .title = "zune camera-controller-example",
        .width = WINDOW_WIDTH,
        .height = WINDOW_HEIGHT,
        .transparent = false,
        .decorated = true,
    });
    defer window.release();


    // setup input manager
    var input = try zune.core.Input.create(allocator, window);
    defer input.release();


    // create a renderer
    var renderer = try zune.graphics.Renderer.create(allocator);
    defer renderer.release();


    const window_size = window.getSize();
    renderer.setViewport(0, 0, @intCast(window_size.width), @intCast(window_size.height));


    // create a camera
    var perspective_camera = zune.graphics.Camera.initPerspective(renderer, std.math.degreesToRadians(45.0), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
    perspective_camera.setPosition(.{ .x = 0.0, .y = 0.0, .z = 5.0});
    perspective_camera.lookAt(.{ .x = 0.0, .y = 0.0, .z = 0.0});


    const initial_mouse_pos = input.getMousePosition();
    var camera_controller = zune.graphics.CameraMouseController.init(&perspective_camera,
    @as(f32, @floatCast(initial_mouse_pos.x)), @as(f32, @floatCast(initial_mouse_pos.y)));
    

    window.centerWindow();
    window.setCursorMode(.disabled);
    //renderer.setClearColor(.{ 0.1, 0.1, 0.1, 1.0 });








    // ==== Create a mesh and model ==== \\
    var transform_1 = zune.ecs.components.TransformComponent.identity();
    var transform_2 = zune.ecs.components.TransformComponent.identity();

    var shader = try zune.graphics.Shader.createColorShader(allocator);
    defer shader.release();

    var material_1 = try zune.graphics.Material.create(allocator, shader, .{ 0.0, 0.1, 0.4, 1.0 }, null);
    var material_2 = try zune.graphics.Material.create(allocator, shader, .{ 0.5, 0.2, 0.3, 1.0 }, null);
    defer material_1.release();
    defer material_2.release();

    var cube_mesh = try zune.graphics.Mesh.createCube(allocator);
    defer cube_mesh.release();

    var cube_model_1 = try zune.graphics.Model.create(allocator);
    var cube_model_2 = try zune.graphics.Model.create(allocator);
    defer cube_model_1.release();
    defer cube_model_2.release();

    try cube_model_1.addMeshMaterial(cube_mesh, material_1);
    try cube_model_2.addMeshMaterial(cube_mesh, material_2);


    // set position
    transform_2.setPosition(0.0, 2, 0.0);
    

    // Set viewport
    const i: f32 = 0.05;
    while (!window.shouldClose()) {




        // ==== Update Variables ==== \\  
        time.update();
        try input.update();

        // Get delta time
        const dt = time.getDelta();




        // ==== Process Input ==== \\     
        const mouse_pos = input.getMousePosition();   
        camera_controller.handleMouseMovement(@as(f32, @floatCast(mouse_pos.x)), @as(f32, @floatCast(mouse_pos.y)), dt);

        // Check input states
        if (input.isKeyHeld(.KEY_SPACE)) {
            std.debug.print("press", .{});
        }




        // ==== Update Program ==== \\
        // Fixed updates (at fixed timestep intervals)
        while (time.shouldFixedUpdate()) {
            const fixed_dt = time.getFixedTimestep();
            _ = fixed_dt;
            // Update physics with fixed_dt...
        }

        transform_2.rotate(i, i / 2, 0.0);




        // ==== Drawing to the screen ==== \\
        // Clear the window
        renderer.clear();

        transform_1.updateMatrices();
        transform_2.updateMatrices();

        try perspective_camera.drawModel(cube_model_1, &transform_1.world_matrix);
        try perspective_camera.drawModel(cube_model_2, &transform_2.world_matrix);
    

        window.pollEvents();
        window.swapBuffers();
    }
}
