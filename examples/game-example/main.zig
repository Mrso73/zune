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

    window.centerWindow();
    window.setCursorMode(.disabled);


    // create a Renderer
    var renderer = try zune.graphics.Renderer.create(allocator, .{});
    defer renderer.release();


    // create a Resource Manager
    var resource_manager = try zune.graphics.ResourceManager.create(allocator, .{});
    defer resource_manager.releaseAll() catch {};


    // Initialize ECS registry
    var registry = try zune.ecs.Registry.create(allocator);
    defer registry.release();    


    //setup time utitilites
    //var time = zune.core.Time.init(.{
    //    .target_fps = 120,
    //    .fixed_timestep = 1.0 / 60.0,
    //});



    // ==== Set Variables ==== //

    // create a camera
    var perspective_camera = zune.graphics.Camera.initPerspective(renderer, std.math.degreesToRadians(45.0), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
    perspective_camera.setPosition(.{ .x = 0.0, .y = 3.0, .z = 15.0 });
    perspective_camera.lookAt(.{ .x = 0.0, .y = 0.0, .z = 0.0 });


    // Create the model
    var txtr_shader = try zune.graphics.Shader.createTextureShader(allocator);
    defer _ = txtr_shader.release();
    var texture = try zune.graphics.Texture.createFromFile(allocator, "examples/game-example/txtr.png");
    defer _ = texture.release();
    var material = try zune.graphics.Material.create(allocator, txtr_shader, .{ 1.0, 1.0, 1.0, 1.0 }, texture);
    defer _ = material.release();
    var cube_mesh = try zune.graphics.Mesh.createCube(allocator);
    defer _ = cube_mesh.release();
    var cube_model = try zune.graphics.Model.create(allocator);
    defer _ = cube_model.release();

    try cube_model.addMeshMaterial(cube_mesh, material);



    // ==== Setup ECS ==== //

    // Register components
    try registry.registerComponent(zune.ecs.components.TransformComponent);
    try registry.registerComponent(zune.ecs.components.ModelComponent);
    try registry.registerComponent(Velocity);

    // Spawn 1 entity
    const entity = try registry.createEntity();

    const transform = zune.ecs.components.TransformComponent.identity();

    // Random position
    try registry.addComponent(entity, transform);

    // Random velocity
    try registry.addComponent(entity, Velocity{
        .x = 0,
        .y = 0,
        .z = 0,
    });

    // Set Model to render
    try registry.addComponent(entity, zune.ecs.components.ModelComponent.init(cube_model));



    // ==== Main Loop ==== //

    while (!window.shouldClose()) {      

        // ==== Update Variables ==== //
        //try time.update();  


        // ==== Process Input ==== //
        //const mouse_pos = window.input.?.getMousePosition();  
        if (window.input.?.isKeyPressed(.KEY_ESCAPE)) window.setTitle("miauw");
        if (window.input.?.isKeyReleased(.KEY_ESCAPE)) break;


        // ==== Update Program ==== //
        try playerMovementSystem(registry, window.input.?);


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
    z: f32,
};


fn playerMovementSystem(registry: *zune.ecs.Registry, input: *zune.core.Input) !void {
    var query = try registry.query(struct {
        transform: *zune.ecs.components.TransformComponent,
        velocity: *Velocity,
    });

    while (try query.next()) |components| {

        // Update position
        if (input.isKeyHeld(.KEY_W)) {
            components.velocity.z = -0.05;
            components.transform.position.z += components.velocity.z;
        }

        if (input.isKeyHeld(.KEY_S)) {
            components.velocity.z = 0.05;
            components.transform.position.z += components.velocity.z;
        }

        if (input.isKeyHeld(.KEY_D)) {
            components.velocity.x = 0.05;
            components.transform.position.x += components.velocity.x;
        }

        if (input.isKeyHeld(.KEY_A)) {
            components.velocity.x = -0.05;
            components.transform.position.x += components.velocity.x;
        }

        if (input.wasKeyJustPressed(.KEY_K, 60)) {
            std.debug.print("K +++\n", .{});
        }

        if (input.wasKeyJustReleased(.KEY_K, 60)) {
            std.debug.print("K ---\n", .{});
        }
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
