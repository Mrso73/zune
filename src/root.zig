// root.zig - Main framework entry point
const std = @import("std");
pub const c = @import("c.zig");


// Core functionality
pub const core = struct {
    pub const Window = @import("core/window.zig").Window;
    pub const WindowConfig = @import("core/window.zig").WindowConfig;

    pub const Time = @import("core/time.zig");
    pub const Input = @import("core/input.zig").Input;
    pub const Config = @import("core/config.zig");
};


// Graphics functionality
pub const graphics = struct {
    pub const Renderer = @import("graphics/renderer.zig").Renderer;
    pub const Material = @import("graphics/material.zig").Material;
    pub const Shader = @import("graphics/shader.zig").Shader;

    pub const Model = @import("graphics/model.zig").Model;
    pub const Mesh = @import("graphics/mesh.zig").Mesh;

    pub const AttributeType = @import("graphics/mesh.zig").AttributeType;
    pub const VertexAttributeDescriptor = @import("graphics/mesh.zig").VertexAttributeDescriptor;
    pub const VertexLayout = @import("graphics/mesh.zig").VertexLayout;
};


// Scene
pub const scene = struct {
    pub const CameraMouseController = @import("scene/camera.zig").CameraMouseController;
    pub const Camera = @import("scene/camera.zig").Camera;

    pub const Transform = @import("scene/transform.zig").Transform;
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
