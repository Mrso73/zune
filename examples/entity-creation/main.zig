const std = @import("std");
const zune = @import("zune");

// --- Component Definitions --- //
const Position = struct { x: f32 = 0, y: f32 = 0 };
const Velocity = struct { dx: f32 = 0, dy: f32 = 0 };
const Renderable = struct { color: [4]f32 };

// --- Systems --- //
fn movementSystem(registry: *zune.scene.ecs.Registry) !void {
    // Get component storages
    const pos_storage = try registry.getComponentStorage(Position);
    const vel_storage = try registry.getComponentStorage(Velocity);

    // Update positions based on velocities
    for (vel_storage.iter()) |vel_data| {
        const entity = vel_data.entity;
        const vel = &vel_data.component;
        if (pos_storage.get(entity)) |pos| {
            pos.x += vel.dx;
            pos.y += vel.dy;
            std.debug.print(
                "Movement: Updated entity {d} to Position{{x: {d:.1}, y: {d:.1}}}\n",
                .{ entity.index, pos.x, pos.y },
            );
        }
    }
}

fn renderSystem(registry: *zune.scene.ecs.Registry) !void {
    const pos_storage = try registry.getComponentStorage(Position);
    const render_storage = try registry.getComponentStorage(Renderable);

    // Print renderable entities' states
    for (render_storage.iter()) |render_data| {
        const entity = render_data.entity;
        const render = &render_data.component;
        if (pos_storage.get(entity)) |pos| {
            std.debug.print(
                "Rendering: Entity {d} at Position{{x: {d:.1}, y: {d:.1}}} with color {any}\n",
                .{ entity.index, pos.x, pos.y, render.color },
            );
        }
    }
}

// --- Main Program --- //
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Initialize ECS registry
    var registry = try zune.scene.ecs.Registry.init(allocator);
    defer registry.deinit();

    // Register components
    try registry.registerComponent(Position);
    try registry.registerComponent(Velocity);
    try registry.registerComponent(Renderable);

    // Create entities and assign components
    const entity1 = try registry.entity_manager.createEntity();
    const entity2 = try registry.entity_manager.createEntity();

    // Assign components to entity1 (has Position, Velocity, Renderable)
    try (try registry.getComponentStorage(Position)).add(entity1, .{ .x = 0, .y = 0 });
    try (try registry.getComponentStorage(Velocity)).add(entity1, .{ .dx = 1.5, .dy = 0.5 });
    try (try registry.getComponentStorage(Renderable)).add(entity1, .{ .color = [4]f32{ 1, 0, 0, 1 } });

    // Assign components to entity2 (has Position, Renderable)
    try (try registry.getComponentStorage(Position)).add(entity2, .{ .x = 10, .y = 5 });
    try (try registry.getComponentStorage(Renderable)).add(entity2, .{ .color = [4]f32{ 0, 0.8, 0, 1 } });

    // Set up systems with dependencies
    var system_manager = zune.scene.ecs.SystemManager.init(allocator);
    defer system_manager.deinit();

    try system_manager.registerSystem(.{
        .name = "movement",
        .run = movementSystem,
        .dependencies = &[_][]const u8{}, // No dependencies
    });

    try system_manager.registerSystem(.{
        .name = "render",
        .run = renderSystem,
        .dependencies = &[_][]const u8{"movement"}, // Depends on movement
    });

    // Simulate game loop for 3 frames
    std.debug.print("\n--- Starting Simulation ---\n", .{});
    for (0..3) |_| {
        try system_manager.update(&registry);
        std.debug.print("----------------------------\n", .{});
    }
}