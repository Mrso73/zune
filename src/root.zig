// root.zig - Main framework entry point
const std = @import("std");
pub const c = @import("c.zig");

pub const config = struct {
    
};


// Core functionality
pub const core = struct {
    pub const Window = @import("core/window.zig").Window;
    pub const WindowConfig = @import("core/window.zig").WindowConfig;

    pub const Time = @import("core/time.zig");
    pub const Input = @import("core/input.zig").Input;
    
};


// Graphics functionality
pub const graphics = struct {
    pub const CameraMouseController = @import("graphics/camera.zig").CameraMouseController;
    pub const Camera = @import("graphics/camera.zig").Camera;

    pub const Renderer = @import("graphics/renderer.zig").Renderer;
    pub const Material = @import("graphics/material.zig").Material;
    pub const Shader = @import("graphics/shader.zig").Shader;
    pub const Texture = @import("graphics/texture.zig").Texture;

    pub const Model = @import("graphics/model.zig").Model;
    pub const Mesh = @import("graphics/mesh.zig").Mesh;

    pub const AttributeType = @import("graphics/mesh.zig").AttributeType;
    pub const VertexAttributeDescriptor = @import("graphics/mesh.zig").VertexAttributeDescriptor;
    pub const VertexLayout = @import("graphics/mesh.zig").VertexLayout;
};


// Scene
pub const ecs = struct {
    pub const EntityID = @import("ecs/ecs.zig").EntityId;
    pub const ComponentStorage = @import("ecs/ecs.zig").ComponentStorage;
    pub const Query = @import("ecs/ecs.zig").Query;
    pub const Registry = @import("ecs/ecs.zig").Registry;

    pub const components = struct {
        pub const TransformComponent = @import("ecs/components/transformComponent.zig").TransformComponent;
        pub const ModelComponent = @import("ecs/components/modelComponent.zig").ModelComponent;
    };

    pub const systems = struct {
        usingnamespace @import("ecs/systems//renderSystem.zig");
    };
};


// Math utilities
pub const math = struct {
    pub usingnamespace @import("math/common.zig");

    const Vec2 = @import("math/vector.zig").Vec2;
    const Vec3 = @import("math/vector.zig").Vec3;
    const Mat4 = @import("math/matrix.zig").Mat4;
    pub const constants = struct {
        pub const PI: f32 = 3.14159265359;
        pub const TAU: f32 = PI * 2.0;
        pub const EPSILON: f32 = 1e-6;
    };
};


// Error handling
pub const err = struct {
    pub const gl = @import("err/gl.zig");
};


//pub const resources = struct {
//    pub const Handle = @import("resources/handle.zig").Handle;
//    pub const ResourceManager = @import("resources/manager.zig").ResourceManager;
//};


//pub const system = struct {
//    // System-level functionality
//    pub const Error = @import("system/error.zig").Error;
//    pub const Logger = @import("system/logger.zig").Logger;
//    pub const Memory = @import("system/memory.zig").Memory;
//};


// Framework version info
pub const Version = struct {
    pub const major = 0;
    pub const minor = 1;
    pub const patch = 0;

    pub fn toString() []const u8 {
        return std.fmt.allocPrint(
            std.heap.page_allocator,
            "{d}.{d}.{d}",
            .{ major, minor, patch },
        ) catch "0.0.0";
    }
};
