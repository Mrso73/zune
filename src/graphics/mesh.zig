// graphics/mesh.zig

const std = @import("std");
const c = @import("../c.zig");
const err = @import("../err/gl.zig");


pub const Mesh = struct {
    vao: c.GLuint,
    vbo: c.GLuint,
    ebo: c.GLuint,
    index_count: usize,
    allocator: std.mem.Allocator,
    ref_count: std.atomic.Value(u32),


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    pub fn create(allocator: std.mem.Allocator, vertices: []const f32, indices: []const u32, layout: VertexLayout) !*Mesh {

        var mesh_ptr = try allocator.create(Mesh);

        try mesh_ptr.init(vertices, indices, layout);
        mesh_ptr.ref_count = std.atomic.Value(u32).init(1);
        mesh_ptr.allocator = allocator;
        return mesh_ptr;
    }


    /// Mesh creation helper function
    pub fn createQuad(allocator: std.mem.Allocator) !*Mesh {

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

        return Mesh.create(allocator, &vertices, &indices, VertexLayout.PosTex());
    }


    /// Mesh creation helper function
    pub fn createCube(allocator: std.mem.Allocator) !*Mesh {
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

        return Mesh.create(allocator, &vertices, &indices, VertexLayout.PosTex());
    }


    /// Mesh creation helper function
    pub fn createTriangle(allocator: std.mem.Allocator) !*Mesh {
        // Triangle vertices: 3 points with positions (x,y,z)
        const vertices = [_]f32{
             0.0,  0.5, 0.0, // Top
            -0.5, -0.5, 0.0, // Left
             0.5, -0.5, 0.0, // Right
        };
        const indices = [_]u32{0, 1, 2};

        return Mesh.create(allocator, &vertices, &indices, VertexLayout.PosTex());
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    pub fn addRef(self: *Mesh) void {
        _ = self.ref_count.fetchAdd(1, .monotonic);
    }


    pub fn bind(self: *Mesh) void {
        c.glBindVertexArray(self.vao);
        err.checkGLError("glBindVertexArray");
    }


    pub fn draw(self: *Mesh) void {
        c.glDrawElements(c.GL_TRIANGLES, @intCast(self.index_count), c.GL_UNSIGNED_INT, null);
        err.checkGLError("glDrawElements");
    }


    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    pub fn release(self: *Mesh) void {
        const prev = self.ref_count.fetchSub(1, .monotonic);
        if (prev == 1) {
            self.deinit();
            self.allocator.destroy(self);
        }
    }


    // ============================================================
    // Private Helper Functions
    // ============================================================

    fn init(self: *Mesh, vertices: []const f32, indices: []const u32, layout: VertexLayout) !void {
        var vao: c.GLuint = undefined;
        var vbo: c.GLuint = undefined;
        var ebo: c.GLuint = undefined;

        // Generate buffers
        c.glGenVertexArrays(1, &vao);
        err.checkGLError("glGenVertexArrays for vao");

        c.glGenBuffers(1, &vbo);
        err.checkGLError("glGenBuffers for vbo");

        c.glGenBuffers(1, &ebo);
        err.checkGLError("glGenBuffers for ebo");

        // Set up VAO
        c.glBindVertexArray(vao);

        // Vertex buffer
        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(vertices.len * @sizeOf(f32)), vertices.ptr, c.GL_STATIC_DRAW);
        err.checkGLError("glBufferData for vertices");

        // Element buffer
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @intCast(indices.len * @sizeOf(u32)), indices.ptr, c.GL_STATIC_DRAW);
        err.checkGLError("glBufferData for indices");

        // Set up vertex attributes based on layout
        var offset: usize = 0;
        for (layout.descriptors, 0..) |desc, i| {
            const size: c.GLint = switch (desc.attribute_type) {
                .Position => 3,
                .TexCoord => 2,
            };

            c.glVertexAttribPointer(@intCast(i), size, desc.data_type, c.GL_FALSE, @as(c.GLint, @intCast(layout.stride)), @ptrFromInt(offset) ); 
            err.checkGLError("glVertexAttribPointer");

            c.glEnableVertexAttribArray(@intCast(i));
            err.checkGLError("glEnableVertexAttribArray");

            offset += @intCast(size * @sizeOf(f32));
        }

        c.glBindVertexArray(0); // Unbind VAO

        // Save the generated buffer IDs and index count
        self.vao = vao;
        self.vbo = vbo;
        self.ebo = ebo;
        self.index_count = indices.len;
    }

    /// Cleanup OpenGL resources
    fn deinit(self: *Mesh) void {
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteBuffers(1, &self.vbo);
        c.glDeleteBuffers(1, &self.ebo);
    }
};


pub const VertexLayout = struct {
    descriptors: []const VertexAttributeDescriptor,
    stride: usize,

    pub fn init(descriptors: []const VertexAttributeDescriptor) VertexLayout {
        var stride: usize = 0;
        for (descriptors) |desc| {
            stride += switch (desc.attribute_type) {
                .Position => 3 * @sizeOf(f32),
                .TexCoord => 2 * @sizeOf(f32),
            };
        }
        return .{ .descriptors = descriptors, .stride = stride };
    }

    pub fn PosNormTex() VertexLayout {
        return init(&.{
            .{ .attribute_type = .Position, .data_type = c.GL_FLOAT },
            .{ .attribute_type = .Normal, .data_type = c.GL_FLOAT },
            .{ .attribute_type = .TexCoord, .data_type = c.GL_FLOAT },
        });
    }

    pub fn PosTex() VertexLayout {
        return VertexLayout.init(&[_]VertexAttributeDescriptor{
            .{ .attribute_type = .Position, .data_type = c.GL_FLOAT },
            .{ .attribute_type = .TexCoord, .data_type = c.GL_FLOAT },
        });
    }

    pub fn Pos() VertexLayout {
        return VertexLayout.init(&[_]VertexAttributeDescriptor{
            .{ .attribute_type = .Position, .data_type = c.GL_FLOAT },
        });
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
