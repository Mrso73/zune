// root.zig - Main framework entry point
const std = @import("std");
pub const c = @import("c.zig");

// Core functionality
pub const core = struct {
    pub const Window = @import("core/window.zig").Window;
    pub const WindowConfig = @import("core/window.zig").WindowConfig;

    pub const Camera = @import("core/camera.zig").Camera;
    //pub const FirstPersonCamera = @import("core/camera.zig").FirstPersonCamera;
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
pub const math = @import("math/math.zig");

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
