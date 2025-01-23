// graphics/Renderer.zig
const std = @import("std");
const c = @import("../c.zig");
const Shader = @import("shader.zig").Shader;
const VertexBuffer = @import("vertexBuffer.zig").VertexBuffer;

// We need these because Renderer uses them in its interface
const VertexLayout = @import("vertexBuffer.zig").VertexLayout;
const AttributeType = @import("vertexBuffer.zig").AttributeType;

pub const Renderer = struct {
    default_shader: Shader,

    pub fn init(allocator: std.mem.Allocator) !Renderer {
        _ = allocator;
        // Initialize OpenGL
        c.glEnable(c.GL_DEPTH_TEST);

        // Create default shader
        const default_shader = try Shader.create(
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

        return Renderer{
            .default_shader = default_shader,
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

    pub fn useShader(self: *Renderer, shader: Shader) void {
        _ = self;
        c.glUseProgram(shader.program);
    }
};
