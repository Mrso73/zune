/// graphics/shader.zig
const std = @import("std");
const c = @import("../c.zig");
const err = @import("../err/gl.zig");

// We need StringHashMap for uniform caching
const StringHashMap = std.StringHashMap;

pub const Shader = struct {
    program: c.GLuint,
    uniform_cache: std.StringHashMap(UniformInfo),

    pub const UniformType = enum {
        Mat4,
        Vec4,
    };

    pub const UniformInfo = struct {
        location: c.GLint,
        type: UniformType,
    };

    // Function for shader compilation
    fn compileShader(source: []const u8, shader_type: c.GLenum) !c.GLuint {
        const shader = c.glCreateShader(shader_type);
        err.checkGLError("glCreateShader");

        const source_ptr: ?[*]const u8 = source.ptr;
        const source_len: ?*const c.GLint = @ptrCast(&@as(c.GLint, @intCast(source.len)));
        c.glShaderSource(shader, 1, &source_ptr, source_len);
        c.glCompileShader(shader);

        // Check for compilation errors
        var success: c.GLint = undefined;
        c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
        std.debug.print("Shader compilation status: {d}\n", .{success}); // Debug print for success

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

    pub fn create(vertex_source: []const u8, fragment_source: []const u8) !Shader {
        const vertex_shader = try compileShader(vertex_source, c.GL_VERTEX_SHADER);
        const fragment_shader = try compileShader(fragment_source, c.GL_FRAGMENT_SHADER);

        const program = c.glCreateProgram();
        err.checkGLError("glCreateProgram"); // Add error check

        c.glAttachShader(program, vertex_shader);
        err.checkGLError("glAttachShader (vertex)"); // Add error check

        c.glAttachShader(program, fragment_shader);
        err.checkGLError("glAttachShader (fragment)"); // Add error check

        c.glLinkProgram(program);
        err.checkGLError("glLinkProgram"); // Add error check

        // Clean up
        c.glDeleteShader(vertex_shader);
        err.checkGLError("glDeleteShader (vertex)"); // Add error check
        c.glDeleteShader(fragment_shader);
        err.checkGLError("glDeleteShader (fragment)"); // Add error check

        return Shader{
            .program = program,
            .uniform_cache = std.StringHashMap(UniformInfo).init(std.heap.page_allocator),
        };
    }

    pub fn deinit(self: *Shader) void {
        c.glDeleteProgram(self.program);
        err.checkGLError("glDeleteProgram"); // Add error check
        self.uniform_cache.deinit();
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
};