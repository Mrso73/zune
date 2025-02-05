// graphics/renderer.zig
const std = @import("std");
const c = @import("../c.zig");
const err = @import("../err/gl.zig");

const Camera = @import("camera.zig").Camera;

const Shader = @import("shader.zig").Shader;
const Material = @import("material.zig").Material;

const Mesh = @import("mesh.zig").Mesh;
const Model = @import("model.zig").Model;


pub const Renderer = struct {
    default_shader: Shader,
    active_camera: ?*Camera = null,


    pub fn init(allocator: std.mem.Allocator) !Renderer {
        _ = allocator;
        // Initialize OpenGL
        c.glEnable(c.GL_DEPTH_TEST);


        // Create default shader
         var shader = try Shader.create(
            \\#version 330 core
            \\layout (location = 0) in vec3 aPos;
            \\uniform mat4 model;
            \\uniform mat4 view;
            \\uniform mat4 projection;
            \\void main() {
            \\    gl_Position = projection * view * model * vec4(aPos, 1.0);
            \\}
        ,
            \\#version 330 core
            \\uniform vec4 color;
            \\out vec4 FragColor;
            \\void main() {
            \\    FragColor = color;
            \\}
        );


        try shader.cacheUniform("model", .Mat4);
        try shader.cacheUniform("view", .Mat4);
        try shader.cacheUniform("projection", .Mat4);
        try shader.cacheUniform("color", .Vec4);


        return Renderer{
            .default_shader = shader,
            .active_camera = null,
        };
    }


    pub fn deinit(self: *Renderer) void {
        self.default_shader.deinit();
    }


    pub fn clear(self: *Renderer) void {
        _ = self;
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        err.checkGLError("glClear");
    }


    pub fn setClearColor(self: *Renderer, color: [4]f32) void {
        _ = self;
        c.glClearColor(color[0], color[1], color[2], color[3]);
        err.checkGLError("glClearColor");
    }


    pub fn setViewport(self: *Renderer, x: i32, y: i32, width: i32, height: i32) void {
        _ = self;
        c.glViewport(x, y, width, height);
        err.checkGLError("glViewport");
    }


    pub fn useShader(self: *Renderer, shader: *Shader) void {
        _ = self;
        c.glUseProgram(shader.program);
        err.checkGLError("glUseProgram");
    }


    pub fn setActiveCamera(self: *Renderer, camera: *Camera) void {
        self.active_camera = camera;
    }


    // Updated draw function to accept Mesh
    pub fn drawMesh(self: *Renderer, mesh: *Mesh, material: *Material, model_matrix: *const [16]f32) !void {
        if (self.active_camera == null) {
            std.debug.print("Warning: No active camera set for rendering mesh.\n", .{});
            return;
        }

        try material.use(self, model_matrix);

        // Now Renderer sets the MVP uniforms
        if (material.shader.uniform_cache.contains("model")) {
            try material.shader.setUniformMat4("model", model_matrix);
        }
        if (material.shader.uniform_cache.contains("view")) {
            try material.shader.setUniformMat4("view", &self.active_camera.?.view_matrix.data);
        }
        if (material.shader.uniform_cache.contains("projection")) {
            try material.shader.setUniformMat4("projection", &self.active_camera.?.projection_matrix.data);
        }

        mesh.bind(); // Bind Mesh

        const current_program_id: c.GLint = undefined;
        c.glGetIntegerv(c.GL_CURRENT_PROGRAM, current_program_id);
        err.checkGLError("glGetIntegerv");

        self.useShader(material.shader);

        mesh.draw(); // Draw Mesh
    }

    pub fn drawModel(self: *Renderer, model: *Model, transform_matrix: *const [16]f32) !void {

        // Iterate over each mesh-material pair
        for (model.meshes, model.materials) |mesh, material| {

            // Draw the mesh using the model's world matrix
            try self.drawMesh(
                mesh, 
                material, 
                transform_matrix,
            );
        }
    }
};