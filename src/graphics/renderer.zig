// graphics/renderer.zig
const std = @import("std");
const c = @import("../c.zig");

const Shader = @import("shader.zig").Shader;
const VertexBuffer = @import("vertexBuffer.zig").VertexBuffer;
const Material = @import("material.zig").Material;
const PerspectiveCamera = @import("../core/camera.zig").PerspectiveCamera;

// We need these because Renderer uses them in its interface
const VertexLayout = @import("vertexBuffer.zig").VertexLayout;
const AttributeType = @import("vertexBuffer.zig").AttributeType;


pub const Renderer = struct {
    default_shader: Shader,
    active_camera: ?*PerspectiveCamera = null, // Keep track of active camera

    pub fn init(allocator: std.mem.Allocator) !Renderer {
        _ = allocator;
        // Initialize OpenGL
        c.glEnable(c.GL_DEPTH_TEST);

        // Create default shader
        var default_shader = try Shader.create(
            // Basic vertex shader
            \\#version 330 core
            \\layout (location = 0) in vec3 aPos;
            \\layout (location = 1) in vec2 aTexCoord;
            \\uniform mat4 model;
            \\uniform mat4 view;
            \\uniform mat4 projection;
            \\void main() {
            \\    gl_Position = projection * view * model * vec4(aPos, 1.0);
            \\}
        ,
            // Basic fragment shader
            \\#version 330 core
            \\uniform vec4 color;
            \\out vec4 FragColor;
            \\void main() {
            \\    FragColor = color;
            \\}
        );

        try default_shader.cacheUniform("model", .Mat4); // Cache MVP uniforms in default shader
        try default_shader.cacheUniform("view", .Mat4);
        try default_shader.cacheUniform("projection", .Mat4);
        try default_shader.cacheUniform("color", .Vec4); // Cache color uniform

        return Renderer{
            .default_shader = default_shader,
            .active_camera = null, // No active camera initially
        };
    }

    pub fn deinit(self: *Renderer) void {
        self.default_shader.deinit();
    }

    pub fn clear(self: *Renderer) void {
        _ = self;
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    }

    pub fn setClearColor(self: *Renderer, color: [4]f32) void {
        _ = self;
        c.glClearColor(color[0], color[1], color[2], color[3]);
    }

    pub fn setViewport(self: *Renderer, x: i32, y: i32, width: i32, height: i32) void {
        _ = self;
        c.glViewport(x, y, width, height);
    }

    pub fn useShader(self: *Renderer, shader: *Shader) void {
        _ = self;
        c.glUseProgram(shader.program); // Access program through the pointer
    }

    pub fn setActiveCamera(self: *Renderer, camera: *PerspectiveCamera) void { // Function to set active camera
        self.active_camera = camera;
    }

    pub fn draw(self: *Renderer, vertex_buffer: *VertexBuffer, material: *Material, model_matrix: *const [16]f32) !void {
        if (self.active_camera == null) {
            std.debug.print("Warning: No active camera set for rendering.\n", .{});
            return;
        }

        try material.use(self, model_matrix); // Use the material, which sets shader and material uniforms

        // Now Renderer sets the MVP uniforms
        if (material.shader.uniform_cache.contains("model")) {
            try material.shader.setUniformMat4("model", model_matrix);
            std.debug.print("Model Matrix: {any}\n", .{model_matrix});
        }
        if (material.shader.uniform_cache.contains("view")) {
            try material.shader.setUniformMat4("view", &self.active_camera.?.base.view_matrix);
            std.debug.print("View Matrix: {any}\n", .{self.active_camera.?.base.view_matrix});
        }
        if (material.shader.uniform_cache.contains("projection")) {
            try material.shader.setUniformMat4("projection", &self.active_camera.?.base.projection_matrix);
            std.debug.print("Projection Matrix: {any}\n", .{self.active_camera.?.base.projection_matrix});
        }

        vertex_buffer.bind();
        vertex_buffer.draw();
    }
};
