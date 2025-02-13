// graphics/renderer.zig
const std = @import("std");
const c = @import("../c.zig");
const err = @import("../err/gl.zig");

const Camera = @import("camera.zig").Camera;

const Shader = @import("shader.zig").Shader;
const Material = @import("material.zig").Material;

const Mesh = @import("mesh.zig").Mesh;
const Model = @import("model.zig").Model;

const Texture = @import("texture.zig").Texture;


pub const Renderer = struct {
    color_shader: Shader,
    textured_shader: Shader,
    active_camera: ?*Camera = null,
    allocator: std.mem.Allocator,


    pub fn init(allocator: std.mem.Allocator) !Renderer {

        // Initialize OpenGL
        c.glEnable(c.GL_DEPTH_TEST);


        // Color Shader (no texture)
        const color_vert = 
            \\#version 330 core
            \\layout (location=0) in vec3 aPos;
            \\uniform mat4 model;
            \\uniform mat4 view;
            \\uniform mat4 projection;
            \\void main() {
            \\    gl_Position = projection * view * model * vec4(aPos, 1.0);
            \\}
        ;
        const color_frag = 
            \\#version 330 core
            \\out vec4 FragColor;
            \\uniform vec4 color;
            \\void main() { FragColor = color; }
        ;
        var color_shader = try Shader.create(color_vert, color_frag);
        try color_shader.cacheUniforms(&.{ "model", "view", "projection", "color" });

        // Textured Shader
        const tex_vert = 
            \\#version 330 core
            \\layout (location=0) in vec3 aPos;
            \\layout (location=1) in vec2 aTexCoord;
            \\out vec2 TexCoord;
            \\uniform mat4 model; uniform mat4 view; uniform mat4 projection;
            \\void main() {
            \\    gl_Position = projection * view * model * vec4(aPos, 1.0);
            \\    TexCoord = aTexCoord;
            \\}
        ;
        const tex_frag = 
            \\#version 330 core
            \\in vec2 TexCoord;
            \\out vec4 FragColor;
            \\uniform vec4 color;
            \\uniform sampler2D texSampler;
            \\void main() {
            \\    FragColor = texture(texSampler, TexCoord) * color;
            \\}
        ;
        var textured_shader = try Shader.create(tex_vert, tex_frag);
        try textured_shader.cacheUniforms(&.{ "model", "view", "projection", "color", "texSampler" });

        return Renderer{
            .allocator = allocator,
            .color_shader = color_shader,
            .textured_shader = textured_shader,
            .active_camera = null,
        };
    }


    pub fn deinit(self: *Renderer) void {
        self.color_shader.deinit();
        self.textured_shader.deinit();
    }


    pub fn createColorMaterial(self: *Renderer, color: [4]f32) !*Material {
        return Material.create(self.allocator, &self.color_shader, color, null);
    }

    pub fn createTexturedMaterial(self: *Renderer, color: [4]f32, texture: *Texture) !*Material {
        return Material.create(self.allocator, &self.textured_shader, color, texture);
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

        try material.use(self);

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

        // (Optional) If you need to retrieve the current program, do it correctly:
        var current_program_id: c.GLint = 0;
        c.glGetIntegerv(c.GL_CURRENT_PROGRAM, &current_program_id);
        err.checkGLError("glGetIntegerv");

        self.useShader(material.shader);
        mesh.draw(); // Draw Mesh
    }

    pub fn drawModel(self: *Renderer, model: *Model, transform_matrix: *const [16]f32) !void {

        // Iterate over each mesh-material pair
        for (model.pairs.items) |pair| {

            // Draw the mesh using the model's world matrix
            try self.drawMesh(pair.mesh, pair.material, transform_matrix);
        }
    }
};