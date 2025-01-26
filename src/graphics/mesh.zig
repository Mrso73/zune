// graphics/mesh.zig

const std = @import("std");
const c = @import("../c.zig");
const err = @import("../err/gl.zig");

pub const Mesh = struct {
    data: MeshData,

    pub fn init(vertices: []const f32, indices: []const u32, layout: VertexLayout) !Mesh {
        return Mesh {
            .data = try MeshData.init(vertices, indices, layout),
        };
    }

    pub fn deinit(self: *Mesh) void {
        self.data.deinit();
    }

    pub fn bind(self: *Mesh) void {
        self.data.bind();
    }

    pub fn draw(self: *Mesh) void {
        self.data.draw();
    }
};


const MeshData = struct { // Renamed from VertexBuffer to MeshData to avoid confusion with the higher level Mesh
    vao: c.GLuint,
    vbo: c.GLuint,
    ebo: c.GLuint,
    index_count: usize,

    pub fn init(vertices: []const f32, indices: []const u32, layout: VertexLayout) !MeshData {
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
            c.glVertexAttribPointer(@intCast(i), size, desc.data_type, c.GL_FALSE, @as(c.GLint, @intCast(layout.stride)), @ptrFromInt(offset) ); 
            c.glEnableVertexAttribArray(@intCast(i));

            offset += @intCast(size * @sizeOf(f32));
        }

        c.glBindVertexArray(0); // Unbind VAO

        return MeshData{
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
            .index_count = indices.len,
        };
    }

    pub fn deinit(self: *MeshData) void {
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteBuffers(1, &self.vbo);
        c.glDeleteBuffers(1, &self.ebo);
    }

    pub fn bind(self: *MeshData) void {
        c.glBindVertexArray(self.vao);
        err.checkGLError("glBindVertexArray");
    }

    pub fn draw(self: *MeshData) void {
        c.glDrawElements(c.GL_TRIANGLES, @intCast(self.index_count), c.GL_UNSIGNED_INT, null);
        err.checkGLError("glDrawElements");
    }
};

pub const VertexLayout = struct {
    descriptors: []const VertexAttributeDescriptor,
    stride: usize, // Add stride to VertexLayout

    pub fn PosTex() VertexLayout {
        return VertexLayout {
            .descriptors = &[_]VertexAttributeDescriptor{
                VertexAttributeDescriptor{ .attribute_type = .Position, .data_type = c.GL_FLOAT },
                VertexAttributeDescriptor{ .attribute_type = .TexCoord, .data_type = c.GL_FLOAT },
            },
            .stride = 5 * @sizeOf(f32), // Assuming Position (3 floats) + TexCoord (2 floats)
        };
    }

    pub fn Pos() VertexLayout {
        return VertexLayout {
            .descriptors = &[_]VertexAttributeDescriptor{
                VertexAttributeDescriptor{ .attribute_type = .Position, .data_type = c.GL_FLOAT },
            },
            .stride = 3 * @sizeOf(f32), // Assuming Position (3 floats)
        };
    }
};

pub const VertexAttributeDescriptor = struct {
    attribute_type: AttributeType,
    data_type: c.GLenum,
};

pub const AttributeType = enum {
    Position,
    TexCoord,
};