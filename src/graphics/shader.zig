/// graphics/Shader.zig
const std = @import("std");
const c = @import("../c.zig");

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
        const source_ptr: ?[*]const u8 = source.ptr;
        const source_len: ?*const c.GLint = @ptrCast(&@as(c.GLint, @intCast(source.len)));
        c.glShaderSource(shader, 1, &source_ptr, source_len);
        c.glCompileShader(shader);

        // Check for compilation errors
        var success: c.GLint = undefined;
        c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
        if (success == 0) {
            var info_log: [512]u8 = undefined;
            var length: c.GLsizei = undefined;
            c.glGetShaderInfoLog(shader, 512, &length, &info_log);
            std.debug.print("Shader compilation error: {s}\n", .{info_log[0..@intCast(length)]});
            return error.ShaderCompilationFailed;
        }

        return shader;
    }

    pub fn create(vertex_source: []const u8, fragment_source: []const u8) !Shader {
        const vertex_shader = try compileShader(vertex_source, c.GL_VERTEX_SHADER);
        const fragment_shader = try compileShader(fragment_source, c.GL_FRAGMENT_SHADER);

        const program = c.glCreateProgram();
        c.glAttachShader(program, vertex_shader);
        c.glAttachShader(program, fragment_shader);
        c.glLinkProgram(program);

        // Clean up
        c.glDeleteShader(vertex_shader);
        c.glDeleteShader(fragment_shader);

        return Shader{
            .program = program,
            .uniform_cache = std.StringHashMap(UniformInfo).init(std.heap.page_allocator),
        };
    }

    pub fn deinit(self: *Shader) void {
        c.glDeleteProgram(self.program);
        self.uniform_cache.deinit();
    }

    pub fn cacheUniform(self: *Shader, name: []const u8, uniform_type: UniformType) !void {
        const location = c.glGetUniformLocation(self.program, name.ptr);
        try self.uniform_cache.put(name, .{ .location = location, .type = uniform_type });
    }

    pub fn setUniformMat4(self: *Shader, name: []const u8, value: *const [16]f32) !void {
        const uniform = self.uniform_cache.get(name) orelse return error.UniformNotFound;
        c.glUniformMatrix4fv(uniform.location, 1, c.GL_FALSE, value);
    }

    pub fn setUniformVec4(self: *Shader, name: []const u8, value: [4]f32) !void {
        const uniform = self.uniform_cache.get(name) orelse return error.UniformNotFound;
        c.glUniform4fv(uniform.location, 1, &value[0]);
    }
};
