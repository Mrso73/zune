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

    /// Initialize a new material.
    pub fn init(shader: *Shader, color: [4]f32, texture: ?*Texture) !Material {
        if (texture) |tex| {
            // Increase the reference count because the material is now using the texture.
            tex.addRef();
        }
        return Material{
            .shader = shader,
            .color = color,
            .texture = texture,
        };
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

    pub fn deinit(self: *Material) void {
    if (self.texture) |tex| {
        // Release our hold on the texture.
        tex.release();
    }
}
};