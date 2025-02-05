const std = @import("std");
const zune = @import("zune");

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 900;

// --- Main Program --- //
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

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

    // Initialize ECS registry
    var registry = try zune.ecs.Registry.init(allocator);
    defer registry.deinit();

    // setup input manager
    var input = try zune.core.Input.init(allocator, window);
    defer input.deinit();





    // create a camera
    var perspective_camera = zune.graphics.Camera.initPerspective(std.math.degreesToRadians(45.0), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
    perspective_camera.setPosition(.{ .x = 0.0, .y = 0.0, .z = 75.0});
    perspective_camera.lookAt(.{ .x = 0.0, .y = 0.0, .z = 0.0});

    const initial_mouse_pos = input.getMousePosition();
    var camera_controller = zune.graphics.CameraMouseController.init(&perspective_camera,
    @as(f32, @floatCast(initial_mouse_pos.x)), @as(f32, @floatCast(initial_mouse_pos.y)));    


    window.centerWindow();
    window.setCursorMode(.disabled);
    renderer.setActiveCamera(&perspective_camera);




    // --- Create the model --- //
    
    var material = try zune.graphics.Material.init(&renderer.default_shader,.{ 0.8, 0.1, 0.4, 1.0 });
    var cube_mesh = try zune.graphics.Mesh.createCube();

    var cube_model = try zune.graphics.Model.initEmpty(allocator, 1, 1);
    defer cube_model.deinit();

    try cube_model.addMesh(&cube_mesh);
    try cube_model.addMaterial(&material);




    // --- Setup the ECS system --- //

    // Register components
    try registry.registerComponent(zune.ecs.components.TransformComponent);
    try registry.registerComponent(zune.ecs.components.ModelComponent);

    try registry.registerComponent(Velocity);
    try registry.registerComponent(Lifetime);



    // Create some particles
    var prng = std.rand.DefaultPrng.init(0);
    var random = prng.random();


    // Spawn 100 particles

    // Create entities and assign components
    //const entity1 = try registry.createEntity();
    //try registry.addComponent(entity1, zune.ecs.components.TransformComponent.identity());
    //try registry.addComponent(entity1, zune.ecs.components.ModelComponent.init(&cube_model));


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
            .x = (random.float(f32) - 0.5) * 0.5,
            .y = (random.float(f32) - 0.5) * 0.5,
        });
        
        // Random lifetime
        try registry.addComponent(entity, Lifetime{
            .remaining = random.float(f32) * 100.0,
        });

        // Set Model to render
        try registry.addComponent(entity, zune.ecs.components.ModelComponent.init(&cube_model));
    }



    // --- Main Loop --- //
    
    while (!window.shouldClose()) {
        try input.update();


        // ==== Process Input ==== \\     
        const mouse_pos = input.getMousePosition();   
        camera_controller.handleMouseMovement(@as(f32, @floatCast(mouse_pos.x)), @as(f32, @floatCast(mouse_pos.y)), 1.0 / 60.0);

        try updatePhysics(&registry);

        renderer.clear();
        
        try render(&registry, &renderer);

        window.pollEvents();
        window.swapBuffers();   
    }


}



const Velocity = struct {
    x: f32,
    y: f32,
};

const Lifetime = struct {
    remaining: f32,
};





fn updatePhysics(registry: *zune.ecs.Registry) !void {

    var query = try registry.query(struct {
        transform: *zune.ecs.components.TransformComponent,
        velocity: *Velocity,
        life: *Lifetime,
    });

    while (try query.next()) |components| {

        // Update position
        components.transform.position[0] += components.velocity.x;
        components.transform.position[1] += components.velocity.y;

        // Update lifetime
        components.life.remaining -= 1.0 / 60.0;

        // rotate model
        components.transform.rotate(0.01, 0.01, 0.0);
    }
}


pub fn render(registry: *zune.ecs.Registry, renderer: *zune.graphics.Renderer) !void {
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
        try renderer.drawModel(
            components.model.model,
            &components.transform.world_matrix,
        );
    }
}