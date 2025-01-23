// err/gl.zig
const std = @import("std");
const c = @import("../c.zig");

pub fn checkGLError(location: []const u8) void {
    const err = c.glGetError();
    if (err != c.GL_NO_ERROR) {
        std.debug.print("OpenGL error at {s}: {d}\n", .{ location, err });
    }
}
