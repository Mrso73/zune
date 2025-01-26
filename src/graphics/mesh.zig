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
        // Cube vertices: 8 points with positions (x,y,z)
        const vertices = [_]f32{
            // Front
            -0.5, -0.5,  0.5, // 0
             0.5, -0.5,  0.5, // 1
             0.5,  0.5,  0.5, // 2
            -0.5,  0.5,  0.5, // 3
            // Back
            -0.5, -0.5, -0.5, // 4
             0.5, -0.5, -0.5, // 5
             0.5,  0.5, -0.5, // 6
            -0.5,  0.5, -0.5, // 7
        };
        const indices = [_]u32{
            // Front
            0, 1, 2, 0, 2, 3,
            // Right
            1, 5, 6, 1, 6, 2,
            // Back
            5, 4, 7, 5, 7, 6,
            // Left
            4, 0, 3, 4, 3, 7,
            // Top
            3, 2, 6, 3, 6, 7,
            // Bottom
            4, 5, 1, 4, 1, 0,
        };
        return Mesh.init(
            &vertices,
            &indices,
            VertexLayout.Pos()
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