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
        .title = "zune camera-controller-example",
        .width = WINDOW_WIDTH,
        .height = WINDOW_HEIGHT,
        .transparent = false,
        .decorated = true,
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


    // create a Resource Manager
    var resource_manager = try zune.graphics.ResourceManager.create(allocator, .{.enabled = true});
    defer resource_manager.releaseAll() catch {};


    //setup time utitilites
    //var time = zune.core.Time.init(.{
    //    .target_fps = 120,
    //    .fixed_timestep = 1.0 / 60.0,
    //});



    // ==== Set Variables ==== //

    // create a camera
    var perspective_camera = zune.graphics.Camera.initPerspective(renderer, std.math.degreesToRadians(45.0), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
    perspective_camera.setPosition(.{ .x = 0.0, .y = 0.0, .z = 5.0});
    perspective_camera.lookAt(.{ .x = 0.0, .y = 0.0, .z = 0.0});

    const initial_mouse_pos = window.input.?.getMousePosition();
    var camera_controller = zune.graphics.CameraMouseController.init(&perspective_camera,
    @as(f32, @floatCast(initial_mouse_pos.x)), @as(f32, @floatCast(initial_mouse_pos.y)));
    

    // Create the model
    var main_cube_transform = zune.ecs.components.TransformComponent.identity();
    const main_cube_shader = try resource_manager.createColorShader("main_cube_shader");
    const main_cube_material = try resource_manager.autoCreateMaterial("autogen_material", main_cube_shader, .{ 0.5, 0.2, 0.3, 1.0 }, null);
    const main_cube_mesh = try resource_manager.createCubeMesh("main_cube_mesh");
    var main_cube_model = try resource_manager.createModel("main_cube_model");
    
    try main_cube_model.addMeshMaterial(main_cube_mesh, main_cube_material);

    

    // ==== Main Loop ==== //

    const i: f32 = 0.025;
    while (!window.shouldClose()) {

        // ==== Update Variables ==== //
        // Get delta time
        //try time.update();
        //const dt = time.getDelta();


        // ==== Process Input ==== //    
        const mouse_pos = window.input.?.getMousePosition();   
        camera_controller.handleMouseMovement(@as(f32, @floatCast(mouse_pos.x)), @as(f32, @floatCast(mouse_pos.y)), 1 / 60);

        // Check input states
        if (window.input.?.isKeyPressed(.KEY_ESCAPE)) {
            window.setCursorMode(.normal);
        }


        // ==== Update Program ==== //
        // Fixed updates (at fixed timestep intervals)
        //while (time.shouldFixedUpdate()) {
        //    const fixed_dt = time.getFixedTimestep();
        //    _ = fixed_dt;
            // Update physics with fixed_dt...
        //}

        main_cube_transform.rotate(i, i / 2, 0.0);


        // ==== Drawing to the screen ==== //
        // Clear the window
        renderer.clear();

        main_cube_transform.updateMatrices();

        try perspective_camera.drawModel(main_cube_model, &main_cube_transform.world_matrix);
    
        try window.pollEvents();
        window.swapBuffers();
    }
            

                
    //try resource_manager.releaseModel("main_cube_model");
    //try resource_manager.models.releaseResourceByPtr(main_cube_model);
    
    //try resource_manager.releaseMesh("standard_cube_mesh");
    //try resource_manager.meshes.releaseResourceByPtr(main_cube_mesh);

    //try resource_manager.releaseMaterial("main_cube_material");
    //try resource_manager.materials.releaseResourceByPtr(main_cube_material);

    //try resource_manager.releaseShader("color_shader");
    //try resource_manager.shaders.releaseResourceByPtr(main_cube_shader);
}