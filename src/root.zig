// root.zig - Main framework entry point
const std = @import("std");
pub const c = @import("c.zig");

// Core functionality
pub const core = struct {
    pub const Window = @import("core/window.zig").Window;
    pub const WindowConfig = @import("core/window.zig").WindowConfig;

    pub const Input = @import("core/input.zig").Input;

    pub const CameraMouseController = @import("core/camera.zig").CameraMouseController;
    pub const Camera = @import("core/camera.zig").Camera;
};

// Graphics functionality
pub const graphics = struct {
    pub const Material = @import("graphics/material.zig").Material;
    pub const Renderer = @import("graphics/renderer.zig").Renderer;
    pub const Shader = @import("graphics/shader.zig").Shader;

    pub const Model = @import("graphics/model.zig").Model;
    pub const Mesh = @import("graphics/mesh.zig").Mesh;
    pub const AttributeType = @import("graphics/mesh.zig").AttributeType;
    pub const VertexAttributeDescriptor = @import("graphics/mesh.zig").VertexAttributeDescriptor;
    pub const VertexLayout = @import("graphics/mesh.zig").VertexLayout;

    pub const Transform = @import("math/transform.zig").Transform;
};

// Math utilities
pub const math = struct {
    pub usingnamespace @import("math/math.zig");

    const Vec2 = @import("math/math.zig").Vec2;
    const Vec3 = @import("math/math.zig").Vec3;
    const Vec4 = @import("math/math.zig").Vec4;
    const Mat4 = @import("math/math.zig").Mat4;

    pub const constants = struct {
        pub const PI: f32 = 3.14159265359;
        pub const TAU: f32 = PI * 2.0;
        pub const EPSILON: f32 = 1e-6;
    };
};

// Utilities
pub const utils = struct {
    pub const Time = @import("utils/time.zig");
};

// Error handling
pub const err = struct {
    pub const gl = @import("err/gl.zig");
};

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
