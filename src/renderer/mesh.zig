// graphics/mesh.zig

const std = @import("std");
const c = @import("../bindings/c.zig");
const err = @import("../core/gl.zig");


/// Error type for time operations
pub const MeshError = error{
    InvalidPackageSize,
};


pub const Mesh = struct {
    vao: c.GLuint,
    vbo: c.GLuint,
    ebo: c.GLuint,
    index_count: usize,

    ref_count: std.atomic.Value(u32),
    allocator: std.mem.Allocator,

    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    pub fn create(allocator: std.mem.Allocator, data: []const f32, indices: []const u32, package_size: u4) !*Mesh {

        var layout: VertexLayout = undefined;
        var floats_per_vertex: usize = 0;

        // Determine layout and floats_per_vertex
       switch (package_size) {
            3 => |size| { 
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.Pos();
            },
            5 => |size| { 
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.PosTex();
            },
            6 => |size| { 
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.PosNorm();
            },
            8 => |size| {
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.PosNormTex();
            },
            else => return MeshError.InvalidPackageSize,
        }

        // Validate input data length
        if (data.len % floats_per_vertex != 0) return error.InvalidVertexData;

        // Call createInternal directly since data is already properly formatted
        return createInternal(allocator, data, indices, layout);
    }

    /// Mesh creation helper function
    pub fn createQuad(allocator: std.mem.Allocator) !*Mesh {

        // Quad vertices: 4 points with positions (x,y,z) and tex coords (u,v)
        const vertices = [_]f32{
            // Positions          // TexCoords
            -0.5, -0.5, 0.0, 0.0, 0.0, // Bottom-left
            0.5, -0.5, 0.0, 1.0, 0.0, // Bottom-right
            0.5, 0.5, 0.0, 1.0, 1.0, // Top-right
            -0.5, 0.5, 0.0, 0.0, 1.0, // Top-left
        };

        const indices = [_]u32{
            0, 1, 2, // First triangle
            2, 3, 0, // Second triangle
        };

        return Mesh.create(allocator, &vertices, &indices, null);
    }

    /// Mesh creation helper function
    pub fn createCube(allocator: std.mem.Allocator) !*Mesh {
        const vertices = [_]f32{
            // Positions          // Texture coords

            // Front face
            -0.5, -0.5, 0.5, 0.0, 0.0, // Bottom-left
            0.5, -0.5, 0.5, 1.0, 0.0, // Bottom-right
            0.5, 0.5, 0.5, 1.0, 1.0, // Top-right
            -0.5, 0.5, 0.5, 0.0, 1.0, // Top-left
            // Back face
            -0.5, -0.5, -0.5, 1.0, 0.0, // Bottom-right
            0.5, -0.5, -0.5, 0.0, 0.0, // Bottom-left
            0.5, 0.5, -0.5, 0.0, 1.0, // Top-left
            -0.5, 0.5, -0.5, 1.0, 1.0, // Top-right
            // Top face
            -0.5, 0.5, -0.5, 0.0, 0.0, // Bottom-left
            0.5, 0.5, -0.5, 1.0, 0.0, // Bottom-right
            0.5, 0.5, 0.5, 1.0, 1.0, // Top-right
            -0.5, 0.5, 0.5, 0.0, 1.0, // Top-left
            // Bottom face
            -0.5, -0.5, -0.5, 0.0, 0.0, // Top-left
            0.5, -0.5, -0.5, 1.0, 0.0, // Top-right
            0.5, -0.5, 0.5, 1.0, 1.0, // Bottom-right
            -0.5, -0.5, 0.5, 0.0, 1.0, // Bottom-left
            // Right face
            0.5, -0.5, -0.5, 0.0, 0.0, // Bottom-left
            0.5, 0.5, -0.5, 1.0, 0.0, // Top-left
            0.5, 0.5, 0.5, 1.0, 1.0, // Top-right
            0.5, -0.5, 0.5, 0.0, 1.0, // Bottom-right
            // Left face
            -0.5, -0.5, -0.5, 1.0, 0.0, // Bottom-right
            -0.5, 0.5, -0.5, 1.0, 1.0, // Top-right
            -0.5, 0.5, 0.5, 0.0, 1.0, // Top-left
            -0.5, -0.5, 0.5, 0.0, 0.0, // Bottom-left
        };

        const indices = [_]u32{
            0, 1, 2, 2, 3, 0, // Front
            4, 5, 6, 6, 7, 4, // Back
            8, 9, 10, 10, 11, 8, // Top
            12, 13, 14, 14, 15, 12, // Bottom
            16, 17, 18, 18, 19, 16, // Right
            20, 21, 22, 22, 23, 20, // Left
        };

        return Mesh.create(allocator, &vertices, &indices, 5);
    }

    /// Mesh creation helper function
    pub fn createTriangle(allocator: std.mem.Allocator) !*Mesh {
        // Triangle vertices: 3 points with positions (x,y,z)
        const vertices = [_]f32{
            0.0, 0.5, 0.0, // Top
            -0.5, -0.5, 0.0, // Left
            0.5, -0.5, 0.0, // Right
        };
        const indices = [_]u32{ 0, 1, 2 };

        return Mesh.create(allocator, &vertices, &indices, 3);
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
    // Public API: Mesh Modification
    // ============================================================

    /// Updates the vertex data of an existing mesh
    /// This will replace all vertex data while keeping the same VAO and VBO
    pub fn updateVertexData(self: *Mesh, data: []const f32, package_size: u4) !void {
        // Validate package size
        var layout: VertexLayout = undefined;
        var floats_per_vertex: usize = 0;

        // Determine layout and floats_per_vertex
        switch (package_size) {
            3 => |size| {
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.Pos();
            },
            5 => |size| {
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.PosTex();
            },
            6 => |size| {
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.PosNorm();
            },
            8 => |size| {
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.PosNormTex();
            },
            else => return MeshError.InvalidPackageSize,
        }

        // Validate input data length
        if (data.len % floats_per_vertex != 0) return error.InvalidVertexData;

        // Bind the VAO to ensure we're updating the correct buffer
        c.glBindVertexArray(self.vao);
        err.checkGLError("updateVertexData: bind VAO");

        // Update vertex buffer
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        err.checkGLError("updateVertexData: bind VBO");
        
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(data.len * @sizeOf(f32)), data.ptr, c.GL_STATIC_DRAW);
        err.checkGLError("updateVertexData: glBufferData for vertices");

        // Reset vertex attributes based on the possibly new layout
        // First, disable all previous attributes
        var attr_index: c.GLuint = 0;
        while (attr_index < 8) : (attr_index += 1) { // 8 is a "ok" max for attributes?
            c.glDisableVertexAttribArray(attr_index);
        }

        // Set up new vertex attributes based on layout
        var offset: usize = 0;
        for (layout.descriptors, 0..) |desc, index| {
            const attr_size: c.GLint = switch (desc.attribute_type) {
                .Position => 3,
                .TexCoord => 2,
                .Normal => 3,
            };

            c.glVertexAttribPointer(
                @intCast(index),
                attr_size,
                desc.data_type,
                c.GL_FALSE,
                @intCast(layout.stride),
                @ptrFromInt(offset),
            );
            err.checkGLError("updateMesh: glVertexAttribPointer");

            c.glEnableVertexAttribArray(@intCast(index));
            err.checkGLError("updateMesh: glEnableVertexAttribArray");

            offset += @as(usize, @intCast(attr_size)) * @sizeOf(f32);
        }

        // Make sure EBO is still bound to VAO
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ebo);
        err.checkGLError("updateVertexData: rebind EBO");

        c.glBindVertexArray(0); // Unbind VAO
        c.glBindBuffer(c.GL_ARRAY_BUFFER, 0); // Unbind VBO
    }

    /// Updates the index data of an existing mesh
    pub fn updateIndexData(self: *Mesh, indices: []const u32) !void {
        // Bind the VAO to ensure we're updating the correct buffer
        c.glBindVertexArray(self.vao);
        err.checkGLError("updateIndexData: bind VAO");

        // Update element buffer
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ebo);
        err.checkGLError("updateIndexData: bind EBO");
        
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @intCast(indices.len * @sizeOf(u32)), indices.ptr, c.GL_STATIC_DRAW);
        err.checkGLError("updateIndexData: glBufferData for indices");

        // Update index count
        self.index_count = indices.len;

        c.glBindVertexArray(0); // Unbind VAO
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, 0); // Unbind EBO
    }

    /// Updates both vertex and index data of an existing mesh
    pub fn updateMesh(self: *Mesh, data: []const f32, indices: []const u32, package_size: u4) !void {
        // Single VAO bind/unbind for the entire operation
        c.glBindVertexArray(self.vao);
        err.checkGLError("updateMesh: bind VAO");
        
        // Update vertex buffer and attributes
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        err.checkGLError("updateMesh: bind VBO");
        
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(data.len * @sizeOf(f32)), data.ptr, c.GL_STATIC_DRAW);
        err.checkGLError("updateMesh: glBufferData for vertices");

        // Validate package size and set up the appropriate layout
        var layout: VertexLayout = undefined;
        var floats_per_vertex: usize = 0;

        switch (package_size) {
            3 => |size| {
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.Pos();
            },
            5 => |size| {
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.PosTex();
            },
            6 => |size| {
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.PosNorm();
            },
            8 => |size| {
                floats_per_vertex = @as(usize, size);
                layout = VertexLayout.PosNormTex();
            },
            else => return MeshError.InvalidPackageSize,
        }

        // Validate input data length
        if (data.len % floats_per_vertex != 0) return error.InvalidVertexData;

        // Reset and set up vertex attributes
        var attr_index: c.GLuint = 0;
        while (attr_index < 8) : (attr_index += 1) {
            c.glDisableVertexAttribArray(attr_index);
        }

        var offset: usize = 0;
        for (layout.descriptors, 0..) |desc, index| {
            const attr_size: c.GLint = switch (desc.attribute_type) {
                .Position => 3,
                .TexCoord => 2,
                .Normal => 3,
            };

            c.glVertexAttribPointer(
                @intCast(index),
                attr_size,
                desc.data_type,
                c.GL_FALSE,
                @intCast(layout.stride),
                @ptrFromInt(offset),
            );
            err.checkGLError("updateMesh: glVertexAttribPointer");

            c.glEnableVertexAttribArray(@intCast(index));
            err.checkGLError("updateMesh: glEnableVertexAttribArray");

            offset += @as(usize, @intCast(attr_size)) * @sizeOf(f32);
        }

        // Update index buffer
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ebo);
        err.checkGLError("updateMesh: bind EBO");
        
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @intCast(indices.len * @sizeOf(u32)), indices.ptr, c.GL_STATIC_DRAW);
        err.checkGLError("updateMesh: glBufferData for indices");

        // Update index count
        self.index_count = indices.len;

        // Unbind everything
        c.glBindVertexArray(0);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, 0);
    }

    

    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    // Decrement reference count and free if no more references
    pub fn release(self: *Mesh) u32 {
        const prev = self.ref_count.fetchSub(1, .monotonic);

        if (prev == 0) {
            @panic("Double release of Mesh detected"); // already freed
            
        } else if (prev == 1) {
            // Last reference, clean up resources
            self.deinit();
            self.allocator.destroy(self);
        }

        return prev;
    }

    // ============================================================
    // Private Helper Functions
    // ============================================================

    fn createInternal(allocator: std.mem.Allocator, vertex_data: []const f32, indices: []const u32, layout: VertexLayout) !*Mesh {
        const mesh_ptr = try allocator.create(Mesh);
        errdefer allocator.destroy(mesh_ptr);

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
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(vertex_data.len * @sizeOf(f32)), vertex_data.ptr, c.GL_STATIC_DRAW);
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
                .Normal => 3,
            };

            c.glVertexAttribPointer(
                @intCast(i),
                size,
                desc.data_type,
                c.GL_FALSE,
                @intCast(layout.stride),
                @ptrFromInt(offset),
            );
            err.checkGLError("glVertexAttribPointer");

            c.glEnableVertexAttribArray(@intCast(i));
            err.checkGLError("glEnableVertexAttribArray");

            offset += @intCast(size * @sizeOf(f32));
        }

        c.glBindVertexArray(0); // Unbind VAO

        // Initialize the mesh
        mesh_ptr.* = .{
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
            .index_count = indices.len,
            .ref_count = std.atomic.Value(u32).init(1),
            .allocator = allocator,
        };

        return mesh_ptr;
    }

    // Clean up OpenGL resources
    fn deinit(self: *Mesh) void {
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteBuffers(1, &self.vbo);
        c.glDeleteBuffers(1, &self.ebo);
        err.checkGLError("Mesh cleanup");
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
                .Normal => 3 * @sizeOf(f32),
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

    pub fn PosNorm() VertexLayout {
        return VertexLayout.init(&[_]VertexAttributeDescriptor{
            .{ .attribute_type = .Position, .data_type = c.GL_FLOAT },
            .{ .attribute_type = .Normal, .data_type = c.GL_FLOAT },
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

    // Get the size of a specific attribute type
    pub fn getAttributeSize(attr_type: AttributeType) usize {
        return switch (attr_type) {
            .Position => 3,
            .TexCoord => 2,
            .Normal => 3,
        };
    }

    // Calculate offset of attribute within the interleaved data
    pub fn getAttributeOffset(self: VertexLayout, attr_index: usize) usize {
        var offset: usize = 0;
        var i: usize = 0;
        while (i < attr_index) : (i += 1) {
            offset += getAttributeSize(self.descriptors[i].attribute_type) * @sizeOf(f32);
        }
        return offset;
    }
};

pub const VertexAttributeDescriptor = struct {
    attribute_type: AttributeType,
    data_type: c.GLenum,
};

pub const AttributeType = enum {
    Position,
    TexCoord,
    Normal,
};
