// graphics/mesh.zig

const std = @import("std");
const c = @import("../c.zig");
const err = @import("../err/gl.zig");


pub const Mesh = struct {
    vao: c.GLuint,
    vbo: c.GLuint,
    ebo: c.GLuint,
    index_count: usize,

    pub fn init(vertices: []const f32, indices: []const u32, layout: VertexLayout) !Mesh {
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

        return Mesh{
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
            .index_count = indices.len,
        };
    }

    pub fn createQuad() !Mesh {
        // Quad vertices: 4 points with positions (x,y,z) and tex coords (u,v)
        const vertices = [_]f32{
            // Positions          // TexCoords
            -0.5, -0.5, 0.0,     0.0, 0.0, // Bottom-left
             0.5, -0.5, 0.0,     1.0, 0.0, // Bottom-right
             0.5,  0.5, 0.0,     1.0, 1.0, // Top-right
            -0.5,  0.5, 0.0,     0.0, 1.0, // Top-left
        };
        const indices = [_]u32{
            0, 1, 2, // First triangle
            2, 3, 0, // Second triangle
        };
        return Mesh.init(
            &vertices,
            &indices,
            VertexLayout.PosTex()
        );
    }

    pub fn createCube() !Mesh {
    const vertices = [_]f32{
        // Positions          // Texture coords
        // Front face
        -0.5, -0.5,  0.5,    0.0, 0.0, // Bottom-left
         0.5, -0.5,  0.5,    1.0, 0.0, // Bottom-right
         0.5,  0.5,  0.5,    1.0, 1.0, // Top-right
        -0.5,  0.5,  0.5,    0.0, 1.0, // Top-left
        // Back face
        -0.5, -0.5, -0.5,    1.0, 0.0, // Bottom-right
         0.5, -0.5, -0.5,    0.0, 0.0, // Bottom-left
         0.5,  0.5, -0.5,    0.0, 1.0, // Top-left
        -0.5,  0.5, -0.5,    1.0, 1.0, // Top-right
        // Top face
        -0.5,  0.5, -0.5,    0.0, 0.0, // Bottom-left
         0.5,  0.5, -0.5,    1.0, 0.0, // Bottom-right
         0.5,  0.5,  0.5,    1.0, 1.0, // Top-right
        -0.5,  0.5,  0.5,    0.0, 1.0, // Top-left
        // Bottom face
        -0.5, -0.5, -0.5,    0.0, 0.0, // Top-left
         0.5, -0.5, -0.5,    1.0, 0.0, // Top-right
         0.5, -0.5,  0.5,    1.0, 1.0, // Bottom-right
        -0.5, -0.5,  0.5,    0.0, 1.0, // Bottom-left
        // Right face
         0.5, -0.5, -0.5,    0.0, 0.0, // Bottom-left
         0.5,  0.5, -0.5,    1.0, 0.0, // Top-left
         0.5,  0.5,  0.5,    1.0, 1.0, // Top-right
         0.5, -0.5,  0.5,    0.0, 1.0, // Bottom-right
        // Left face
        -0.5, -0.5, -0.5,    1.0, 0.0, // Bottom-right
        -0.5,  0.5, -0.5,    1.0, 1.0, // Top-right
        -0.5,  0.5,  0.5,    0.0, 1.0, // Top-left
        -0.5, -0.5,  0.5,    0.0, 0.0  // Bottom-left
    };

    const indices = [_]u32{
        0,  1,  2,  2,  3,  0,  // Front
        4,  5,  6,  6,  7,  4,  // Back
        8,  9,  10, 10, 11, 8,  // Top
        12, 13, 14, 14, 15, 12, // Bottom
        16, 17, 18, 18, 19, 16, // Right
        20, 21, 22, 22, 23, 20  // Left
    };

    return Mesh.init(
        &vertices,
        &indices,
        VertexLayout.PosTex()
    );
}

    pub fn createTriangle() !Mesh {
        // Triangle vertices: 3 points with positions (x,y,z)
        const vertices = [_]f32{
             0.0,  0.5, 0.0, // Top
            -0.5, -0.5, 0.0, // Left
             0.5, -0.5, 0.0, // Right
        };
        const indices = [_]u32{0, 1, 2};
        return Mesh.init(
            &vertices,
            &indices,
            VertexLayout.Pos()
        );
    }

    pub fn deinit(self: *Mesh) void {
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteBuffers(1, &self.vbo);
        c.glDeleteBuffers(1, &self.ebo);
    }

    pub fn bind(self: *Mesh) void {
        c.glBindVertexArray(self.vao);
        err.checkGLError("glBindVertexArray");
    }

    pub fn draw(self: *Mesh) void {
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
