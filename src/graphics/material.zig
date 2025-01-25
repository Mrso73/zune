// graphics/material.zig

const std = @import("std");
const Shader = @import("shader.zig").Shader;
const Renderer = @import("renderer.zig").Renderer; // Needed for forward declaration? or to use renderer in material? No.
const c = @import("../c.zig");


pub const Material = struct {
    shader: *Shader,
    //shader: Shader,
    color: [4]f32, // Example material property

    pub fn init(shader: *Shader, color: [4]f32) !Material {
        return Material{
            .shader = shader,
            .color = color,
        };
    }

    pub fn deinit(self: *Material) void {
        _ = self.color;
        //self.shader.deinit(); // Should material own the shader? For now yes, maybe reconsider later.
        // self.shader.deinit(); // Material no longer owns the shader
    }

    pub fn use(self: *Material, renderer: *Renderer, model_matrix: *const [16]f32) !void {
        _ = model_matrix; // TODO: remove

        renderer.useShader(self.shader); // Tell renderer to use this material's shader
        
        // Set common uniforms (view, projection) - Renderer will handle this now.
        // Set model matrix - Renderer will handle this now.

        // Set material specific uniforms
        try self.shader.setUniformVec4("color", self.color); // Assuming "color" uniform exists in shader
    }
};