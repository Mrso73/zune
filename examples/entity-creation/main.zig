const std = @import("std");
const zune = @import("zune");

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
        .title = "zune ecs-example",
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


    // Initialize ECS registry
    var registry = try zune.ecs.Registry.create(allocator);
    defer registry.release();



    // ==== Set Variables ==== //

    // create a camera
    var perspective_camera = zune.graphics.Camera.initPerspective(renderer, std.math.degreesToRadians(45.0), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
    perspective_camera.setPosition(.{ .x = 0.0, .y = 0.0, .z = 75});
    perspective_camera.lookAt(.{ .x = 0.0, .y = 0.0, .z = 0.0});

    const initial_mouse_pos = window.input.?.getMousePosition();
    var camera_controller = zune.graphics.CameraMouseController.init(&perspective_camera,
    @as(f32, @floatCast(initial_mouse_pos.x)), @as(f32, @floatCast(initial_mouse_pos.y)));    


    // Create the model
    var txtr_shader = try zune.graphics.Shader.createTextureShader(allocator);
    defer _ = txtr_shader.release();
    var texture = try zune.graphics.Texture.createFromFile(allocator, "examples/entity-creation/txtr.png");
    defer _ = texture.release();
    var material = try zune.graphics.Material.create(allocator, txtr_shader, .{ 1.0, 1.0, 1.0, 1.0 }, texture);
    defer _ = material.release();
    var cube_mesh = try zune.graphics.Mesh.createCube(allocator);
    defer _ = cube_mesh.release();
    var cube_model = try zune.graphics.Model.create(allocator);
    defer _ = cube_model.release();

    try cube_model.addMeshMaterial(cube_mesh, material);


    // Triangle vertices (x, y, z)
    const triangle_pos_data = [_]f32{
        -0.5, -0.5, 0.0,  // Vertex 0: bottom left
        0.5, -0.5, 0.0,  // Vertex 1: bottom right
        0.0,  0.5, 0.0,  // Vertex 2: top center
    };

    // Triangle indices (counter-clockwise winding)
    const triangle_indices = [_]u32{
        0, 1, 2
    };

    var clr_shader = try zune.graphics.Shader.createColorShader(allocator);
    defer _ = clr_shader.release();
    const dynamic_material = try zune.graphics.Material.create(allocator, clr_shader, .{ 1.0, 1.0, 1.0, 1.0 }, null);
    defer _ = dynamic_material.release();
    const dynamic_mesh = try zune.graphics.Mesh.create(allocator, &triangle_pos_data, &triangle_indices, 3);
    defer _ = dynamic_mesh.release();
    var dynamic_model = try zune.graphics.Model.create(allocator);
    defer _ = dynamic_model.release();

    try dynamic_model.addMeshMaterial(dynamic_mesh, dynamic_material);

    // Square vertices (x, y, z)
    const square_pos_data = [_]f32{
        -0.5, -0.5, 0.0,  // Vertex 0: bottom left
        0.5, -0.5, 0.0,  // Vertex 1: bottom right
        0.5,  0.5, 0.0,  // Vertex 2: top right
        -0.5,  0.5, 0.0,  // Vertex 3: top left
    };

    // Square indices (two triangles, counter-clockwise winding)
    const square_indices = [_]u32{
        0, 1, 2,  // First triangle
        0, 2, 3   // Second triangle
    };



    // ==== Setup ECS ==== //

    // Register components
    try registry.registerComponent(zune.ecs.components.TransformComponent);
    try registry.registerComponent(zune.ecs.components.ModelComponent);

    try registry.registerComponent(Velocity);
    //try registry.registerComponent(Lifetime);
    try registry.registerDeferedComponent(Lifetime, "customCleanup");


    // Create random generater
    var prng = std.Random.DefaultPrng.init(0);
    var random = prng.random();


    // Spawn 100 particle entities
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const entity = try registry.createEntity();

        var transform = zune.ecs.components.TransformComponent.identity();
        transform.setPosition(
            random.float(f32),
            random.float(f32),
            0.0,
        );

        // Random position
        try registry.addComponent(entity, transform);

        // Random velocity
        try registry.addComponent(entity, Velocity{
            .x = (random.float(f32) - 0.5) * 0.2,
            .y = (random.float(f32) - 0.5) * 0.2,
        });
        
        // Random lifetime
        try registry.addComponent(entity, Lifetime{
            .remaining = random.float(f32) * 10.0,
        });

        // Set Model to render
        try registry.addComponent(entity, zune.ecs.components.ModelComponent.init(cube_model));
    }

    const dynamic = try registry.createEntity();
    try registry.addComponent(dynamic, zune.ecs.components.ModelComponent.init(dynamic_model));

    var transform = zune.ecs.components.TransformComponent.identity();
    transform.setPosition(
            3,
            0.0,
            0.0,
    );
    try registry.addComponent(dynamic, transform);





    // ==== Main Loop ==== //
    
    while (!window.shouldClose()) {

        // ==== Update Variables ==== //


        // ==== Process Input ==== //  
        const mouse_pos = window.input.?.getMousePosition();   
        camera_controller.handleMouseMovement(@as(f32, @floatCast(mouse_pos.x)), @as(f32, @floatCast(mouse_pos.y)), 1.0 / 60.0);


        // ==== Update Program ==== //
        try updatePhysics(registry);

        if (window.input.?.isKeyPressed(.KEY_SPACE)) try dynamic_mesh.updateMesh(&square_pos_data, &square_indices, 3);
        if (window.input.?.isKeyReleased(.KEY_SPACE)) try dynamic_mesh.updateMesh(&triangle_pos_data, &triangle_indices, 3);


        // ==== Drawing to the screen ==== //
        renderer.clear();
        try render(&perspective_camera, registry);

        try window.pollEvents();
        window.swapBuffers();   
    }


}



const Velocity = struct {
    x: f32,
    y: f32,
};

const Lifetime = struct {
    remaining: f32,

    pub fn customCleanup(self: *Lifetime) void {
        std.debug.print("Deinit: {any}\n", .{self});
    }
};





fn updatePhysics(registry: *zune.ecs.Registry) !void {

    var query = try registry.query(struct {
        transform: *zune.ecs.components.TransformComponent,
        velocity: *Velocity,
        life: *Lifetime,
    });

    while (try query.next()) |components| {

        // Update position
        components.transform.position.x += components.velocity.x;
        components.transform.position.y += components.velocity.y;

        // Update lifetime
        components.life.remaining -= 1.0 / 60.0;

        // rotate model
        components.transform.rotate(0.01, 0.01, 0.0);
    }
}


pub fn render(camera: *zune.graphics.Camera, registry: *zune.ecs.Registry) !void {
    // Query for entities with all required components
    var query = try registry.query(struct {
        transform: *zune.ecs.components.TransformComponent,
        model: *zune.ecs.components.ModelComponent,
    });

    while (try query.next()) |components| {
        // Skip if not visible
        if (!components.model.visible) continue;

        // Update transform matrices
        components.transform.updateMatrices();

        // Draw the model using current transform
        try camera.drawModel(
            components.model.model,
            &components.transform.world_matrix,
        );
    }
}