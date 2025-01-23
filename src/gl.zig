const std = @import("std");
const c = @import("c.zig");

pub const GLError = error{
    InitializationFailed,
    ShaderCompilationFailed,
    ShaderLinkFailed,
    InvalidOperation,
    OutOfMemory,
};

pub fn checkGLError(comptime label: []const u8) void {
    const err = c.glGetError();
    switch (err) {
        c.GL_NO_ERROR => {},
        c.GL_INVALID_ENUM => std.log.err("{s}: GL_INVALID_ENUM", .{label}),
        c.GL_INVALID_VALUE => std.log.err("{s}: GL_INVALID_VALUE", .{label}),
        c.GL_INVALID_OPERATION => std.log.err("{s}: GL_INVALID_OPERATION", .{label}),
        c.GL_INVALID_FRAMEBUFFER_OPERATION => std.log.err("{s}: GL_INVALID_FRAMEBUFFER_OPERATION", .{label}),
        c.GL_OUT_OF_MEMORY => std.log.err("{s}: GL_OUT_OF_MEMORY", .{label}),
        else => std.log.err("{s}: Unknown OpenGL error: 0x{x}", .{ label, err }),
    }
}
