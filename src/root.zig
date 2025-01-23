// root.zig - Main framework entry point
const std = @import("std");
pub const c = @import("c.zig");

// Core functionality
pub const core = struct {
    pub const Window = @import("core/window.zig").Window;
    pub const WindowConfig = @import("core/window.zig").WindowConfig;

    pub const Input = @import("core/input.zig").Input;
    pub const KeyState = @import("core/input.zig").KeyState;
    pub const KeyMods = @import("core/input.zig").KeyMods;

    pub const OrthographicCamera = @import("core/camera.zig").OrthographicCamera;
    pub const PerspectiveCamera = @import("core/camera.zig").PerspectiveCamera;
    //pub const FirstPersonCamera = @import("core/camera.zig").FirstPersonCamera;
};

// Graphics functionality
pub const graphics = struct {
    pub const Renderer = @import("graphics/renderer.zig").Renderer;

    pub const Shader = @import("graphics/shader.zig").Shader;

    pub const VertexBuffer = @import("graphics/vertexBuffer.zig").VertexBuffer;
    pub const AttributeType = @import("graphics/vertexBuffer.zig").AttributeType;
    pub const VertexAttributeDescriptor = @import("graphics/vertexBuffer.zig").VertexAttributeDescriptor;
    pub const VertexLayout = @import("graphics/vertexBuffer.zig").VertexLayout;
};

// Math utilities
pub const math = struct {
    pub const Math = @import("math/math.zig");
};

// Utilities
pub const utils = struct {
    pub const Time = @import("utils/time.zig");
};

pub const err = struct {
    pub const gl = @import("gl.zig");
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
