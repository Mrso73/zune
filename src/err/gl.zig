// err/gl.zig
const std = @import("std");
const c = @import("../c.zig");

pub fn checkGLError(context: []const u8) void {
    const error_code = c.glGetError();
    if (error_code != c.GL_NO_ERROR) {
        const error_str = errorString(error_code);
        std.debug.print("OpenGL Error ({s}) after {s}: {}\n", .{ error_str, context, error_code });
        std.debug.panic("OpenGL error occurred", .{}); // Or handle error in a different way, like returning an error.
    }
}

fn errorString(error_code: c.GLenum) []const u8 {
    return switch (error_code) {
        c.GL_NO_ERROR => "GL_NO_ERROR",
        c.GL_INVALID_ENUM => "GL_INVALID_ENUM",
        c.GL_INVALID_VALUE => "GL_INVALID_VALUE",
        c.GL_INVALID_OPERATION => "GL_INVALID_OPERATION",
        //c.GL_STACK_OVERFLOW => "GL_STACK_OVERFLOW",
        //c.GL_STACK_UNDERFLOW => "GL_STACK_UNDERFLOW",
        c.GL_OUT_OF_MEMORY => "GL_OUT_OF_MEMORY",
        c.GL_INVALID_FRAMEBUFFER_OPERATION => "GL_INVALID_FRAMEBUFFER_OPERATION",
        else => "UNKNOWN_ERROR",
    };
}