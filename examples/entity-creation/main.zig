const std = @import("std");
const zune = @import("zune");

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 900;

pub fn main() !void {

    // --- Initialize Everything --- //

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

    // create a renderer
    var renderer = try zune.graphics.Renderer.create(allocator);
    defer renderer.release();

    // Initialize ECS registry
    var registry = try zune.ecs.Registry.create(allocator);
    defer registry.release();

    // setup input manager
    var input = try zune.core.Input.create(allocator, window);
    defer input.release();



    // --- Set Variables --- //

    // create a camera
    var perspective_camera = zune.graphics.Camera.initPerspective(renderer, std.math.degreesToRadians(45.0), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
    perspective_camera.setPosition(.{ .x = 0.0, .y = 0.0, .z = 75.0});
    perspective_camera.lookAt(.{ .x = 0.0, .y = 0.0, .z = 0.0});

    const initial_mouse_pos = input.getMousePosition();
    var camera_controller = zune.graphics.CameraMouseController.init(&perspective_camera,
    @as(f32, @floatCast(initial_mouse_pos.x)), @as(f32, @floatCast(initial_mouse_pos.y)));    


    window.centerWindow();
    window.setCursorMode(.disabled);


    // --- Create the model --- //
    
    var texture = try zune.graphics.Texture.createFromFile(allocator, "examples/entity-creation/txtr.png");
    defer texture.release();

    var material = try zune.graphics.Material.create(allocator, &renderer.textured_shader, .{ 1.0, 1.0, 1.0, 1.0 }, texture);
    defer material.release();

    var cube_mesh = try zune.graphics.Mesh.createCube(allocator);
    defer cube_mesh.release();

    var cube_model = try zune.graphics.Model.create(allocator);
    defer cube_model.release();

    try cube_model.addMeshMaterial(cube_mesh, material);



    // --- Setup the ECS system --- //

    // Register components
    try registry.registerComponent(zune.ecs.components.TransformComponent);
    try registry.registerComponent(zune.ecs.components.ModelComponent);

    try registry.registerComponent(Velocity);
    try registry.registerComponent(Lifetime);


    // Create random generater
    var prng = std.rand.DefaultPrng.init(0);
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



    // --- Main Loop --- //
    
    while (!window.shouldClose()) {
        try input.update();

        // ==== Process Input ==== \\     
        const mouse_pos = input.getMousePosition();   
        camera_controller.handleMouseMovement(@as(f32, @floatCast(mouse_pos.x)), @as(f32, @floatCast(mouse_pos.y)), 1.0 / 60.0);

        try updatePhysics(registry);

        renderer.clear();
        
        try render(perspective_camera, registry);

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


pub fn render(camera: zune.graphics.Camera, registry: *zune.ecs.Registry) !void {
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