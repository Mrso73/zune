// graphics/vertexBuffer.zig
const std = @import("std");
const c = @import("../c.zig");

pub const VertexBuffer = struct {
    vao: c.GLuint,
    vbo: c.GLuint,
    ebo: c.GLuint,
    index_count: usize,

    pub fn init(vertices: []const f32, indices: []const u32, layout: VertexLayout) !VertexBuffer {
        var vao: c.GLuint = undefined;
        var vbo: c.GLuint = undefined;
        var ebo: c.GLuint = undefined;

        c.glGenVertexArrays(1, &vao);
        c.glGenBuffers(1, &vbo);
        c.glGenBuffers(1, &ebo);

        c.glBindVertexArray(vao);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(vertices.len * @sizeOf(f32)), vertices.ptr, c.GL_STATIC_DRAW);

        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @intCast(indices.len * @sizeOf(u32)), indices.ptr, c.GL_STATIC_DRAW);

        // Set up vertex attributes based on layout
        var offset: usize = 0;
        for (layout.descriptors, 0..) |desc, i| {
            const size: c.GLint = switch (desc.attribute_type) {
                .Position => 3,
                .TexCoord => 2,
            };
            c.glVertexAttribPointer(@intCast(i), size, desc.data_type, c.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(offset));
            c.glEnableVertexAttribArray(@intCast(i));

            std.debug.print("Attribute: {}, Offset: {}\n", .{ i, offset }); 
            offset += @intCast(size * @sizeOf(f32));
        }

        return VertexBuffer{
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
            .index_count = indices.len,
        };
    }

    pub fn deinit(self: *VertexBuffer) void {
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteBuffers(1, &self.vbo);
        c.glDeleteBuffers(1, &self.ebo);
    }

    pub fn bind(self: *VertexBuffer) void {
        c.glBindVertexArray(self.vao);
    }

    pub fn draw(self: *VertexBuffer) void {
        std.debug.print("Drawing with: mode={}; count={}; type={}; offset=null\n", .{c.GL_TRIANGLES, self.index_count, c.GL_UNSIGNED_INT});
        c.glDrawElements(c.GL_TRIANGLES, @intCast(self.index_count), c.GL_UNSIGNED_INT, null);
    }
};

pub const VertexLayout = struct {
    descriptors: []const VertexAttributeDescriptor,
};

pub const VertexAttributeDescriptor = struct {
    attribute_type: AttributeType,
    data_type: c.GLenum,
};

pub const AttributeType = enum {
    Position,
    TexCoord,
};
