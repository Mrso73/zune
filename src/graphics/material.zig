// graphics/material.zig
const std = @import("std");
const Shader = @import("shader.zig").Shader;
const Renderer = @import("renderer.zig").Renderer; // Still needed
const c = @import("../c.zig");


pub const Material = struct {
    shader: *Shader,
    color: [4]f32,

    pub fn init(shader: *Shader, color: [4]f32) !Material {
        return Material{
            .shader = shader,
            .color = color,
        };
    }

    pub fn use(self: *Material, renderer: *Renderer, model_matrix: *const [16]f32) !void {
        _ = model_matrix;

        renderer.useShader(self.shader);

        // Renderer handles MVP uniforms now.
        // Material just sets its own uniforms.

        // Set material specific uniforms
        try self.shader.setUniformVec4("color", self.color);

    }
};