// graphics/shader.zig
const std = @import("std");
const c = @import("../bindings/c.zig");
const err = @import("../core/gl.zig");

// We need StringHashMap for uniform caching
const StringHashMap = std.StringHashMap;

pub const Shader = struct {
    program: c.GLuint,
    uniform_cache: std.StringHashMap(UniformInfo),

    ref_count: std.atomic.Value(u32),
    allocator: std.mem.Allocator,

    pub const UniformType = enum { Mat4, Vec4, Texture2D };
    pub const UniformInfo = struct { location: c.GLint, type: UniformType };


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    pub fn create(allocator: std.mem.Allocator, vertex_source: []const u8, fragment_source: []const u8) !*Shader {
        const vertex_shader = try compileShader(vertex_source, c.GL_VERTEX_SHADER);
        errdefer c.glDeleteShader(vertex_shader);
        
        const fragment_shader = try compileShader(fragment_source, c.GL_FRAGMENT_SHADER);
        errdefer c.glDeleteShader(fragment_shader);

        const program = c.glCreateProgram();
        if (program == 0) {
            return error.ShaderProgramCreationFailed;
        }
        errdefer c.glDeleteProgram(program);

        c.glAttachShader(program, vertex_shader);
        c.glAttachShader(program, fragment_shader);

        defer {
            c.glDetachShader(program, vertex_shader);
            c.glDetachShader(program, fragment_shader);
            c.glDeleteShader(vertex_shader);
            c.glDeleteShader(fragment_shader);
        }

        c.glLinkProgram(program);

        var link_status: c.GLint = undefined;
        c.glGetProgramiv(program, c.GL_LINK_STATUS, &link_status);
        if (link_status == c.GL_FALSE) {
            var info_log: [512]u8 = undefined;
            var length: c.GLsizei = undefined;
            c.glGetProgramInfoLog(program, 512, &length, &info_log);
            if (length > 0) {
                const usize_length: usize = @intCast(length);
                std.debug.print("[Error] Shader program linking error: {s}\n", .{info_log[0..usize_length]});
            }
            return error.ShaderProgramLinkFailed;
        }

        // Add validation
        c.glValidateProgram(program);
        var validate_status: c.GLint = undefined;
        c.glGetProgramiv(program, c.GL_VALIDATE_STATUS, &validate_status);
        if (validate_status == c.GL_FALSE) {
            return error.ShaderProgramValidationFailed;
        }

        const shader_ptr = try allocator.create(Shader);
        errdefer allocator.destroy(shader_ptr);

        shader_ptr.* = .{
            .program = program,
            .uniform_cache = std.StringHashMap(UniformInfo).init(allocator),
            .ref_count = std.atomic.Value(u32).init(1),
            .allocator = allocator,
        };

        return shader_ptr;
    }


    /// Create a color shader to use
    pub fn createColorShader(allocator: std.mem.Allocator) !*Shader {

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
        var color_shader = try Shader.create(allocator, color_vert, color_frag);
        errdefer _ = color_shader.release(); 

        try color_shader.cacheUniforms(&.{ "model", "view", "projection", "color" });

        return color_shader;
    }


    /// Create texture shader to use
    pub fn createTextureShader(allocator: std.mem.Allocator) !*Shader {

        // Textured Shader
        const txtr_vert = 
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
        const txtr_frag = 
            \\#version 330 core
            \\in vec2 TexCoord;
            \\out vec4 FragColor;
            \\uniform vec4 color;
            \\uniform sampler2D texSampler;
            \\void main() {
            \\    FragColor = texture(texSampler, TexCoord) * color;
            \\}
        ;
        var textured_shader = try Shader.create(allocator, txtr_vert, txtr_frag);
        errdefer _ = textured_shader.release(); 

        try textured_shader.cacheUniforms(&.{ "model", "view", "projection", "color", "texSampler" });

        return textured_shader;
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    pub fn addRef(self: *Shader) void {
        _ = self.ref_count.fetchAdd(1, .monotonic);
    }

    pub fn cacheUniforms(self: *Shader, names: []const []const u8) !void {
        for (names) |name| {
            const t: UniformType = if (std.mem.eql(u8, name, "texSampler")) .Texture2D else .Mat4;
            try self.cacheUniform(name, t);
        }
    }


    /// Sets an integer uniform (for sampler uniforms, etc.)
    pub fn setUniformInt(self: *Shader, name: []const u8, value: i32) !void {
        const uniform = self.uniform_cache.get(name) orelse return error.UniformNotFound;
        c.glUniform1i(uniform.location, value);
        err.checkGLError("glUniform1i");
    }


    pub fn cacheUniform(self: *Shader, name: []const u8, uniform_type: UniformType) !void {
        const location = c.glGetUniformLocation(self.program, name.ptr);
        err.checkGLError("glGetUniformLocation"); // Add error check
        try self.uniform_cache.put(name, .{ .location = location, .type = uniform_type });
    }


    pub fn setUniformMat4(self: *Shader, name: []const u8, value: *const [16]f32) !void {
        const uniform = self.uniform_cache.get(name) orelse return error.UniformNotFound;
        c.glUniformMatrix4fv(uniform.location, 1, c.GL_FALSE, value);
        err.checkGLError("glUniformMatrix4fv"); // Add error check
    }


    pub fn setUniformVec4(self: *Shader, name: []const u8, value: [4]f32) !void {
        const uniform = self.uniform_cache.get(name) orelse return error.UniformNotFound;
        c.glUniform4fv(uniform.location, 1, &value[0]);
        err.checkGLError("glUniform4fv"); // Add error check
    }

    
    // ============================================================
    // Public API: Destruction Function
    // ============================================================
    

    pub fn release(self: *Shader) u32 {
        const prev = self.ref_count.fetchSub(1, .monotonic);

        if (prev == 0) {
            @panic("Double release of Shader detected"); // already freed

        } else if (prev == 1) {
            c.glDeleteProgram(self.program);
            err.checkGLError("glDeleteProgram");

            self.uniform_cache.deinit();
            self.allocator.destroy(self);
        }
        return prev;
    }


    // ============================================================
    // Private Helper Functions
    // ============================================================

    // Function for shader compilation
    fn compileShader(source: []const u8, shader_type: c.GLenum) !c.GLuint {
        const shader = c.glCreateShader(shader_type);
        err.checkGLError("glCreateShader");

        const source_ptr: ?[*]const u8 = source.ptr;
        const source_len: ?*const c.GLint = @ptrCast(&@as(c.GLint, @intCast(source.len)));
        c.glShaderSource(shader, 1, &source_ptr, source_len);
        c.glCompileShader(shader);
        err.checkGLError("glCompileShader");

        // Check for compilation errors
        var success: c.GLint = undefined;
        c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);

        if (success == c.GL_FALSE) {
            var info_log: [512]u8 = undefined;
            var length: c.GLsizei = undefined;

            c.glGetShaderInfoLog(shader, 512, &length, &info_log);
            std.debug.print("Shader compilation status: {d}\n", .{success}); // Debug print for success
            std.debug.print("Shader compilation error, length: {d}\n", .{length}); // Debug print for length

            // Check if length is greater than 0 before slicing
            if (length > 0) {
                    const usize_length: usize = @intCast(length); // Cast to usize here
                    std.debug.print("Shader compilation error: {s}\n", .{info_log[0..usize_length]});
            } else {
                std.debug.print("Shader compilation failed, but no error message was provided by OpenGL driver.\n", .{});
            }

            return error.ShaderCompilationFailed;
        }

        return shader;
    }
};