// graphics/material.zig
const std = @import("std");
const c = @import("../bindings/c.zig");

const err = @import("../core/gl.zig");

const Shader = @import("shader.zig").Shader;
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
        errdefer allocator.destroy(material_ptr);

        shader.addRef();

        if (texture) |tex| tex.addRef();
        
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
    pub fn use(self: *Material) !void {
        c.glUseProgram(self.shader.program);
        err.checkGLError("glUseProgram");

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

    pub fn release(self: *Material) u32 {
        const prev = self.ref_count.fetchSub(1, .monotonic);

        if (prev == 0) {
            @panic("Double release of Material detected"); // already freed
            
        } else if (prev == 1) {
        
            _ = self.shader.release();
            if (self.texture) |tex| _ = tex.release();
            self.allocator.destroy(self);
        }
        return prev;
    }
};