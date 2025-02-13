// ecs/systems/render_system.zig
const Renderer = @import("../../renderer/renderer.zig").Renderer;
const Registry = @import("../ecs.zig").Registry;

const TransformComponent = @import("../components/transform_component.zigg").TransformComponent;
const ModelComponent = @import("../components/model_component.zig").ModelComponent;

const EcsError = @import("../ecs.zig").EcsError;

pub const RenderSystem = struct {
    registry: *Registry,
    renderer: *Renderer,

    pub fn init(registry: *Registry, renderer: *Renderer) RenderSystem {
        return .{
            .registry = registry,
            .renderer = renderer,
        };
    }

    pub fn update(self: *RenderSystem) !void {
        // Query for entities with all required components
        var query = try self.registry.query(struct {
            transform: *TransformComponent,
            model: *ModelComponent,
        });
        defer query.deinit();

        while (try query.next()) |components| {
            // Skip if not visible
            if (!components.model.visible) continue;

            // Update transform matrices
            components.transform.updateMatrix();
            //const model = components.model.model;

            // Draw the model using current transform
            try self.renderer.drawModel(
                components.model.model, 
                &components.transform.world_matrix,
            );
        }
    }
};
