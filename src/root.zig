// root.zig - Main framework entry point
const std = @import("std");
pub const c = @import("bindings/c.zig");



/// Core engine functionality for window management, input, and timing
pub const core = struct {
    pub usingnamespace @import("core/window.zig");
    pub usingnamespace @import("core/time.zig");
    pub usingnamespace @import("core/input.zig");
    
};


// Graphics functionality
pub const graphics = struct {
    pub usingnamespace @import("renderer/camera.zig");

    pub usingnamespace @import("renderer/renderer.zig");
    pub usingnamespace @import("renderer/material.zig");
    pub usingnamespace @import("renderer/shader.zig");
    pub usingnamespace @import("renderer/texture.zig");

    pub usingnamespace @import("renderer/model.zig");
    pub usingnamespace @import("renderer/mesh.zig");
};


// Scene
pub const ecs = struct {
    pub usingnamespace @import("ecs/ecs.zig");

    pub const components = struct {
        pub usingnamespace @import("ecs/components/transform_component.zig");
        pub usingnamespace @import("ecs/components/model_component.zig");
    };

    pub const systems = struct {
        usingnamespace @import("ecs/systems/render_system.zig");
    };
};


// Math utilities
pub const math = struct {
    pub usingnamespace @import("math/common.zig");

    pub usingnamespace @import("math/vector.zig");
    pub usingnamespace @import("math/vector.zig");
    pub usingnamespace @import("math/matrix.zig");

    pub const constants = struct {
        pub const PI: f32 = 3.14159265359;
        pub const TAU: f32 = PI * 2.0;
        pub const EPSILON: f32 = 1e-6;
    };
};


// Error handling
pub const err = struct {
    pub usingnamespace @import("core/gl.zig");
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
