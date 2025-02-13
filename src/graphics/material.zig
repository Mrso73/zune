// graphics/material.zig
const std = @import("std");
const c = @import("../c.zig");

const Shader = @import("shader.zig").Shader;
const Renderer = @import("renderer.zig").Renderer; // Still needed
const Texture = @import("texture.zig").Texture;


pub const Material = struct {
    shader: *Shader,
    color: [4]f32,
    texture: ?*Texture,

    ref_count: std.atomic.Value(u32),
    allocator: std.mem.Allocator,


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    /// Create a new material pointer.
    pub fn create(allocator: std.mem.Allocator, shader: *Shader, color: [4]f32, texture: ?*Texture) !*Material {
        const material_ptr = try allocator.create(Material);

        if (texture) |tex| {
            tex.addRef();
        }
        
        material_ptr.* = .{
            .allocator = allocator,
            .ref_count = std.atomic.Value(u32).init(1),
            .shader = shader,
            .color = color,
            .texture = texture,
        };
        return material_ptr;
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    pub fn addRef(self: *Material) void {
        _ = self.ref_count.fetchAdd(1, .monotonic);
    }

    /// Uses the material for rendering.
    pub fn use(self: *Material, renderer: *Renderer) !void {
        renderer.useShader(self.shader);

        // Set material-specific uniforms
        try self.shader.setUniformVec4("color", self.color);

        // If a texture is provided, bind it and update the sampler uniform.
        if (self.texture) |tex| {
            tex.bind(0);
            try self.shader.setUniformInt("texSampler", 0);
        }
    }


    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    pub fn release(self: *Material) void {
        const prev = self.ref_count.fetchSub(1, .monotonic);
        if (prev == 1) {
            self.deinit(); // call private cleanup
            self.allocator.destroy(self);
        }
    }


    // ============================================================
    // Private Helper Functions
    // ============================================================

    fn deinit(self: *Material) void {
        if (self.texture) |tex| {
            // Release our hold on the texture.
            tex.release();
        }
    }
};