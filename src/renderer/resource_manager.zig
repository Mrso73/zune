// graphics/resource_manager.zig

const std = @import("std");

const Model = @import("model.zig").Model;
const Mesh = @import("mesh.zig").Mesh;
const VertexLayout = @import("mesh.zig").VertexLayout;
const Material = @import("material.zig").Material;
const Texture = @import("texture.zig").Texture;
const Shader = @import("shader.zig").Shader;

pub const ResourceType = enum {
    Model,
    Mesh,
    Material,
    Texture,
    Shader,
};

pub const ResourceError = error{
    ResourceNotFound,
    ResourceAllocationFailed,
    InvalidResourceType,
    ResourceAlreadyExists,
};

pub const ResourceManager = struct {
    allocator: std.mem.Allocator,

    // Hashmaps to store resources by ID/path
    models: std.StringHashMap(*Model),
    meshes: std.StringHashMap(*Mesh),
    materials: std.StringHashMap(*Material),
    textures: std.StringHashMap(*Texture),
    shaders: std.StringHashMap(*Shader),


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    /// Initialize a new resource manager
    pub fn create(allocator: std.mem.Allocator) !*ResourceManager {
        const resource_manager_ptr = try allocator.create(ResourceManager);
        errdefer allocator.destroy(resource_manager_ptr);

        resource_manager_ptr.* = ResourceManager{
            .allocator = allocator,
            .models = std.StringHashMap(*Model).init(allocator),
            .meshes = std.StringHashMap(*Mesh).init(allocator),
            .materials = std.StringHashMap(*Material).init(allocator),
            .shaders = std.StringHashMap(*Shader).init(allocator),
            .textures = std.StringHashMap(*Texture).init(allocator),
        };
        return resource_manager_ptr;
    }


    /// Create a model with the given name
    pub fn createModel(self: *ResourceManager, name: []const u8) !*Model {

        // Check if already exists
        if (self.models.get(name)) |existing| {
            //std.debug.print("Alreay exists: {}", .{name});
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // Create a empty model struct
        const model = try Model.create(self.allocator);
        errdefer _ = model.release();

        try self.models.put(owned_name, model);
        return model;
    }


    /// Create a mesh with the given parameters
    pub fn createMesh(self: *ResourceManager, name: []const u8, data: []const f32, indices: []const u32, has_normals: bool) !*Mesh {

        // Check if already exists
        if (self.meshes.get(name)) |existing| {
            //std.debug.print("Alreay exists: {}", .{name});
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // Create the mesh creation function
        const mesh = switch (has_normals) {
            true => try Mesh.create(self.allocator, data, indices, true),
            false => try Mesh.create(self.allocator, data, indices, false),
        };
        errdefer _ = mesh.release();

        try self.meshes.put(owned_name, mesh);
        return mesh;
    }


    /// Create a standard cube mesh
    pub fn createCubeMesh(self: *ResourceManager) !*Mesh {

        // Check if already exists
        const name = "standard_cube_mesh";
        if (self.meshes.get(name)) |existing| {
            //std.debug.print("Alreay exists: {}", .{name});
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // Call the mesh creation function
        const mesh = try Mesh.createCube(self.allocator);
        errdefer _ = mesh.release();

        try self.meshes.put(owned_name, mesh);
        return mesh;
    }


    /// Create a standard quad mesh
    pub fn createQuadMesh(self: *ResourceManager) !*Mesh {

        // Check if already exists
        const name = "standard_quad_mesh";
        if (self.meshes.get(name)) |existing| {
            //std.debug.print("Alreay exists: {}", .{name});
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // call the mesh creation function
        const mesh = try Mesh.createQuad(self.allocator);
        errdefer _ = mesh.release();

        try self.meshes.put(owned_name, mesh);
        return mesh;
    }


    /// Create a material with the given parameters
    pub fn createMaterial(self: *ResourceManager, name: []const u8, shader: *Shader, color: [4]f32, texture: ?*Texture) !*Material {

        // Check if already exists
        if (self.materials.get(name)) |existing| {
            //std.debug.print("Alreay exists: {}", .{name});
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // Call the metarial creation function
        const material = try Material.create(self.allocator, shader, color, texture);
        errdefer _ = material.release();

        try self.materials.put(owned_name, material);
        return material;
    }


    /// Load a texture from file, or return existing if already loaded
    pub fn createTexture(self: *ResourceManager, path: []const u8) !*Texture {

        // Check if already loaded
        if (self.textures.get(path)) |existing| {
            //std.debug.print("Alreay exists: {}", .{path});
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_path = try self.allocator.dupe(u8, path);
        errdefer self.allocator.free(owned_path);

        // Call the texture creation fucntion
        const texture = try Texture.createFromFile(self.allocator, path);
        errdefer _ = texture.release();

        try self.textures.put(owned_path, texture);
        return texture;
    }


    /// Create a shader from source code
    pub fn createShader(self: *ResourceManager, name: []const u8, vertex_source: []const u8, fragment_source: []const u8) !*Shader {

        // Check if already exists
        if (self.shaders.get(name)) |existing| {
            //std.debug.print("Alreay exists: {s}", .{name.});
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // Call the shader creation function
        const shader = try Shader.create(self.allocator, vertex_source, fragment_source);
        errdefer _ = shader.release();

        try self.shaders.put(owned_name, shader);
        return shader;
    }


    /// Create a color shader with standard parameters
    pub fn createColorShader(self: *ResourceManager) !*Shader {
        const color_shader = try self.createShader("color_shader",
        // Vertex shader
            \\#version 330 core
            \\layout (location=0) in vec3 aPos;
            \\uniform mat4 model;
            \\uniform mat4 view;
            \\uniform mat4 projection;
            \\void main() {
            \\    gl_Position = projection * view * model * vec4(aPos, 1.0);
            \\}
        ,
        // Fragment shader
            \\#version 330 core
            \\out vec4 FragColor;
            \\uniform vec4 color;
            \\void main() { FragColor = color; }
        );
        try color_shader.cacheUniforms(&.{ "model", "view", "projection", "color" });
        return color_shader;
    }


    /// Create a texture shader with standard parameters
    pub fn createTextureShader(self: *ResourceManager) !*Shader {
        const textured_shader = try self.createShader("texture_shader",
        // Vertex shader
            \\#version 330 core
            \\layout (location=0) in vec3 aPos;
            \\layout (location=1) in vec2 aTexCoord;
            \\out vec2 TexCoord;
            \\uniform mat4 model; uniform mat4 view; uniform mat4 projection;
            \\void main() {
            \\    gl_Position = projection * view * model * vec4(aPos, 1.0);
            \\    TexCoord = aTexCoord;
            \\}
        ,
        // Fragment shader
            \\#version 330 core
            \\in vec2 TexCoord;
            \\out vec4 FragColor;
            \\uniform vec4 color;
            \\uniform sampler2D texSampler;
            \\void main() {
            \\    FragColor = texture(texSampler, TexCoord) * color;
            \\}
        );

        try textured_shader.cacheUniforms(&.{ "model", "view", "projection", "color", "texSampler" });
        return textured_shader;
    }


    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    /// Clean up all resources and print debug info about remaining resources
    pub fn releaseAll(self: *ResourceManager) void {
        // std.debug.print("\n=== Resource Manager Cleanup Start ===\n", .{});

        // Track counts for debug output
        var total_models: usize = 0;
        var total_meshes: usize = 0;
        var total_materials: usize = 0;
        var total_textures: usize = 0;
        var total_shaders: usize = 0;

        // Clean up models
        {
            var iter = self.models.iterator();
            while (iter.next()) |entry| {
                const model = entry.value_ptr.*;
                const ref_count = model.ref_count.load(.monotonic);
                total_models += 1;

                std.debug.print("Model '{s}' has {d} references\n", .{
                    entry.key_ptr.*,
                    ref_count,
                });
                _ = model.release();
                self.allocator.free(entry.key_ptr.*);
            }
            self.models.deinit();
        }


        // Clean up meshes
        {
            var iter = self.meshes.iterator();
            while (iter.next()) |entry| {
                const mesh = entry.value_ptr.*;
                const ref_count = mesh.ref_count.load(.monotonic);
                total_meshes += 1;

                std.debug.print("Mesh '{s}' has {d} references\n", .{
                    entry.key_ptr.*,
                    ref_count,
                });
                _ = mesh.release();
                self.allocator.free(entry.key_ptr.*);
            }
            self.meshes.deinit();
        }


        // Clean up materials
        {
            var iter = self.materials.iterator();
            while (iter.next()) |entry| {
                const material = entry.value_ptr.*;
                const ref_count = material.ref_count.load(.monotonic);
                total_materials += 1;

                std.debug.print("Material '{s}' has {d} references\n", .{
                    entry.key_ptr.*,
                    ref_count,
                });
                _ = material.release();
                self.allocator.free(entry.key_ptr.*);
            }
            self.materials.deinit();
        }


        // Clean up textures
        {
            var iter = self.textures.iterator();
            while (iter.next()) |entry| {
                const texture = entry.value_ptr.*;
                const ref_count = texture.ref_count.load(.monotonic);
                total_textures += 1;

                std.debug.print("Texture '{s}' has {d} references\n", .{
                    entry.key_ptr.*,
                    ref_count,
                });
                _ = texture.release();
                self.allocator.free(entry.key_ptr.*);
            }
            self.textures.deinit();
        }


        // Clean up shaders
        {
            var iter = self.shaders.iterator();
            while (iter.next()) |entry| {
                const shader = entry.value_ptr.*;
                const ref_count = shader.ref_count.load(.monotonic);
                total_shaders += 1;

                std.debug.print("Shader '{s}' has {d} references\n", .{
                    entry.key_ptr.*,
                    ref_count,
                });
                _ = shader.release();
                self.allocator.free(entry.key_ptr.*);
            }
            self.shaders.deinit();
        }


        // Print summary
        std.debug.print("\n=== Resource Manager Cleanup Summary ===\n", .{});
        std.debug.print("Models in manager: {d}\n", .{total_models});
        std.debug.print("Meshes in manager: {d}\n", .{total_meshes});
        std.debug.print("Materials in manager: {d}\n", .{total_materials});
        std.debug.print("Textures in manager: {d}\n", .{total_textures});
        std.debug.print("Shaders in manager: {d}\n", .{total_shaders});
        std.debug.print("Total resources in manager: {d}\n", .{total_models + total_meshes + total_materials + total_textures + total_shaders});
        std.debug.print("=== Resource Manager Cleanup Complete ===\n\n", .{});

        self.allocator.destroy(self);
    }


    /// Release a reference to a model
    pub fn releaseModel(self: *ResourceManager, name: []const u8) !void {
        const entry = self.models.getEntry(name) orelse return ResourceError.ResourceNotFound;
        const model = entry.value_ptr.*;
        const prev = model.release();
        if (prev == 1) {
            const key = entry.key_ptr.*;
            _ = self.models.remove(name);
            self.allocator.free(key);
        }
    }


    /// Release a reference to a mesh
    pub fn releaseMesh(self: *ResourceManager, name: []const u8) !void {
        const entry = self.meshes.getEntry(name) orelse return ResourceError.ResourceNotFound;
        const mesh = entry.value_ptr.*;
        const prev = mesh.release();
        if (prev == 1) {
            const key = entry.key_ptr.*;
            _ = self.meshes.remove(name);
            self.allocator.free(key);
        }
    }


    /// Release a reference to a material
    pub fn releaseMaterial(self: *ResourceManager, name: []const u8) !void {
        const entry = self.materials.getEntry(name) orelse return ResourceError.ResourceNotFound;
        const material = entry.value_ptr.*;
        const prev = material.release();
        if (prev == 1) {
            const key = entry.key_ptr.*;
            _ = self.materials.remove(name);
            self.allocator.free(key);
        }
    }


    /// Release a reference to a texture
    pub fn releaseTexture(self: *ResourceManager, path: []const u8) !void {
        const entry = self.textures.getEntry(path) orelse return ResourceError.ResourceNotFound;
        const texture = entry.value_ptr.*;
        const prev = texture.release();
        if (prev == 1) {
            const key = entry.key_ptr.*;
            _ = self.textures.remove(path);
            self.allocator.free(key);
        }
    }


    /// Release a reference to a shader
    pub fn releaseShader(self: *ResourceManager, name: []const u8) !void {
        const entry = self.shaders.getEntry(name) orelse return ResourceError.ResourceNotFound;
        const shader = entry.value_ptr.*;
        const prev = shader.release();
        if (prev == 1) {
            const key = entry.key_ptr.*;
            _ = self.shaders.remove(name);
            self.allocator.free(key);
        }
    }


    // ============================================================
    // Private Helper Functions
    // ============================================================

    // Type-specific resource name lookup functions
    //fn getModelName(self: *ResourceManager, resource: *Model) ?[]const u8 {}

    //fn getMeshName(self: *ResourceManager, resource: *Mesh) ?[]const u8 {}

    //fn getMaterialName(self: *ResourceManager, resource: *Material) ?[]const u8 {}

    //fn getTextureName(self: *ResourceManager, resource: *Texture) ?[]const u8 {}

    //fn getShaderName(self: *ResourceManager, resource: *Shader) ?[]const u8 {}
};
