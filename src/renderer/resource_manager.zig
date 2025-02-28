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

const ResourceRefInfo = struct {
    name: []const u8,              // Resource identifier
    resource_type: ResourceType,    // Type of resource
    ref_count: u32,                // Reference count before cleanup
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

    // Counters for auto-generated names
    next_model_id: u32 = 0,
    next_mesh_id: u32 = 0,
    next_material_id: u32 = 0,
    next_texture_id: u32 = 0,
    next_shader_id: u32 = 0,


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
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // Create a empty Model struct
        const model = try Model.create(self.allocator);
        errdefer _ = model.release();

        // Add the Model to the hash map
        try self.models.put(owned_name, model);
        return model;
    }


    /// Create a model with autogenerated name using only a prefix
    pub fn autoCreateModel(self: *ResourceManager, prefix: []const u8) !*Model {
        
        // Generate a unique name for the Model using the provided prefix
        const unique_name = try self.generateUniqueName(ResourceType.Model, prefix);
        errdefer self.allocator.free(unique_name);

        // Create the Model
        const model = try Model.create(self.allocator);
        errdefer _ = model.release();

        // Add the Model to the hash map
        try self.models.put(unique_name, model);
        return model;
    }


    /// Create a mesh with the given parameters
    pub fn createMesh(self: *ResourceManager, name: []const u8, data: []const f32, indices: []const u32, has_normals: bool) !*Mesh {

        // Check if already exists
        if (self.meshes.get(name)) |existing| {
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // Create the Mesh creation function
        const mesh = try Mesh.create(self.allocator, data, indices, has_normals);
        errdefer _ = mesh.release();

        // Add the Mesh to the hash map
        try self.meshes.put(owned_name, mesh);
        return mesh;
    }   


    /// Create a mesh with autogenerated name using only a prefix
    pub fn autoCreateMesh(self: *ResourceManager, prefix: []const u8, data: []const f32, indices: []const u32, has_normals: bool) !*Mesh {
        
        // Generate a unique name for the Mesh using the provided prefix
        const unique_name = try self.generateUniqueName(ResourceType.Mesh, prefix);
        errdefer self.allocator.free(unique_name);

        // Create the Mesh
        const mesh = try Mesh.create(self.allocator, data, indices, has_normals);
        errdefer _ = mesh.release();

        // Add the Mesh to the hash map
        try self.meshes.put(unique_name, mesh);
        return mesh;
    }


    /// Create a standard cube mesh
    pub fn createCubeMesh(self: *ResourceManager) !*Mesh {

        // Check if already exists
        const name = "standard_cube_mesh";
        if (self.meshes.get(name)) |existing| {
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // Call the Mesh creation function
        const mesh = try Mesh.createCube(self.allocator);
        errdefer _ = mesh.release();

        // Add the Mesh to the hash map
        try self.meshes.put(owned_name, mesh);
        return mesh;
    }


    /// Create a standard quad mesh
    pub fn createQuadMesh(self: *ResourceManager) !*Mesh {

        // Check if already exists
        const name = "standard_quad_mesh";
        if (self.meshes.get(name)) |existing| {
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // call the Mesh creation function
        const mesh = try Mesh.createQuad(self.allocator);
        errdefer _ = mesh.release();

        // Add the Mesh to the hash map
        try self.meshes.put(owned_name, mesh);
        return mesh;
    }


    /// Create a material with the given parameters
    pub fn createMaterial(self: *ResourceManager, name: []const u8, shader: *Shader, color: [4]f32, texture: ?*Texture) !*Material {

        // Check if already exists
        if (self.materials.get(name)) |existing| {
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // Call the Material creation function
        const material = try Material.create(self.allocator, shader, color, texture);
        errdefer _ = material.release();

        // Add the Material to the hash map
        try self.materials.put(owned_name, material);
        return material;
    }


    /// Create a material with autogenerated name using only a prefix
    pub fn autoCreateMaterial(self: *ResourceManager, prefix: []const u8, shader: *Shader, color: [4]f32, texture: ?*Texture) !*Material {
        
        // Generate a unique name for the Material using the existing helper
        const unique_name = try self.generateUniqueName(ResourceType.Material, prefix);
        errdefer self.allocator.free(unique_name);
        
        // Create the Material
        const material = try Material.create(self.allocator, shader, color, texture);
        errdefer _ = material.release(); 
        
        // Add the Material to the hash map
        try self.materials.put(unique_name, material);
        return material;
    }


    /// Load a texture from file, or return existing if already loaded
    pub fn createTexture(self: *ResourceManager, path: []const u8) !*Texture {

        // Check if already loaded
        if (self.textures.get(path)) |existing| {
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_path = try self.allocator.dupe(u8, path);
        errdefer self.allocator.free(owned_path);

        // Call the Texture creation fucntion
        const texture = try Texture.createFromFile(self.allocator, path);
        errdefer _ = texture.release();

        // Add the Texture to the hash map
        try self.textures.put(owned_path, texture);
        return texture;
    }


    /// Create a Texture with autogenerated name using only a prefix
    pub fn autoCreateTexture(self: *ResourceManager, prefix: []const u8, path: []const u8) !*Texture {
        
        // Generate a unique name for the Texture using the provided prefix
        const unique_name = try self.generateUniqueName(ResourceType.Texture, prefix);
        errdefer self.allocator.free(unique_name);

        // Create the Texture
        const tex = try Texture.createFromFile(self.allocator, path);
        errdefer _ = tex.release();

        // Add the Texture to the hash map
        try self.textures.put(unique_name, tex);
        return tex;
    }


    /// Create a shader from source code
    pub fn createShader(self: *ResourceManager, name: []const u8, vertex_source: []const u8, fragment_source: []const u8) !*Shader {

        // Check if already exists
        if (self.shaders.get(name)) |existing| {
            existing.addRef();
            return existing;
        }

        // Store in our maps
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        // Call the shader creation function
        const shader = try Shader.create(self.allocator, vertex_source, fragment_source);
        errdefer _ = shader.release();

        // Add the Shader to the hash map
        try self.shaders.put(owned_name, shader);
        return shader;
    }


    /// Create a Shader with autogenerated name using only a prefix
    pub fn autoCreateShader(self: *ResourceManager, prefix: []const u8, vertex_source: []const u8, fragment_source: []const u8) !*Shader {

        // Generate a unique name for the Shader using the provided prefix
        const unique_name = try self.generateUniqueName(ResourceType.Shader, prefix);
        errdefer self.allocator.free(unique_name);

        // Create the Shader
        const shdr = try Shader.create(self.allocator, vertex_source, fragment_source);
        errdefer _ = shdr.release();

        // Add the Shader to the hash map
        try self.textures.put(unique_name, shdr);
        return shdr;
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
        std.debug.print("\n=== Resource Manager Cleanup Start ===\n", .{});

        // Track counts for debug output
        var total_models: usize = 0;
        var total_meshes: usize = 0;
        var total_materials: usize = 0;
        var total_textures: usize = 0;
        var total_shaders: usize = 0;

        // Create lists to store reference information before cleanup
        var model_refs = std.ArrayList(ResourceRefInfo).init(self.allocator);
        defer model_refs.deinit();
        var mesh_refs = std.ArrayList(ResourceRefInfo).init(self.allocator);
        defer mesh_refs.deinit();
        var material_refs = std.ArrayList(ResourceRefInfo).init(self.allocator);
        defer material_refs.deinit();
        var texture_refs = std.ArrayList(ResourceRefInfo).init(self.allocator);
        defer texture_refs.deinit();
        var shader_refs = std.ArrayList(ResourceRefInfo).init(self.allocator);
        defer shader_refs.deinit();

        // First pass: collect reference count information for all resources
        self.collectResourceRefs(&model_refs, &mesh_refs, &material_refs, &texture_refs, &shader_refs) catch |err| {
            std.debug.print("Error collecting reference information: {}\n", .{err});
        };


        // Print reference count information
        self.printRefCounts(.Model, model_refs);
        self.printRefCounts(.Mesh, mesh_refs);
        self.printRefCounts(.Material, material_refs);
        self.printRefCounts(.Texture, texture_refs);
        self.printRefCounts(.Shader, shader_refs);



        // IMPORTANT: We release resources in REVERSE order of dependencies:
        // 1. Models (depend on Materials and Meshes)
        // 2. Materials (depend on Shaders and Textures)
        // 3. Meshes (no dependencies)
        // 4. Textures (no dependencies)
        // 5. Shaders (no dependencies)


        // Clean up models first (they depend on materials and meshes)
        {
            var iter = self.models.iterator();
            while (iter.next()) |entry| {
                const model = entry.value_ptr.*;
                total_models += 1;

                _ = model.release();
                self.allocator.free(entry.key_ptr.*);
            }
            self.models.deinit();
        }


        // Clean up materials next (they depend on shaders and textures)
        {
            var iter = self.materials.iterator();
            while (iter.next()) |entry| {
                const material = entry.value_ptr.*;
                total_materials += 1;

                _ = material.release();
                self.allocator.free(entry.key_ptr.*);
            }
            self.materials.deinit();
        }


        // Clean up meshes (no dependencies)
        {
            var iter = self.meshes.iterator();
            while (iter.next()) |entry| {
                const mesh = entry.value_ptr.*;
                total_meshes += 1;

                _ = mesh.release();
                self.allocator.free(entry.key_ptr.*);
            }
            self.meshes.deinit();
        }


        // Clean up textures (no dependencies)
        {
            var iter = self.textures.iterator();
            while (iter.next()) |entry| {
                const texture = entry.value_ptr.*;
                total_textures += 1;

                _ = texture.release();
                self.allocator.free(entry.key_ptr.*);
            }
            self.textures.deinit();
        }


        // Clean up shaders (no dependencies)
        {
            var iter = self.shaders.iterator();
            while (iter.next()) |entry| {
                const shader = entry.value_ptr.*;
                total_shaders += 1;

                _ = shader.release();
                self.allocator.free(entry.key_ptr.*);
            }
            self.shaders.deinit();
        }


        // Print summary of resource counts
        std.debug.print("\n=== Resource Manager Cleanup Summary ===\n\n", .{});

        std.debug.print("Models left in manager: {d}\n", .{total_models});
        std.debug.print("Meshes left in manager: {d}\n", .{total_meshes});
        std.debug.print("Materials left in manager: {d}\n", .{total_materials});
        std.debug.print("Textures left in manager: {d}\n", .{total_textures});
        std.debug.print("Shaders left in manager: {d}\n", .{total_shaders});
        std.debug.print("Total resources left in manager: {d}\n", .{total_models + total_meshes + total_materials + total_textures + total_shaders});
        
        std.debug.print("\n=== Resource Manager Cleanup Complete ===\n\n", .{});

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

    /// Generate a unique name for a resource type widh a prefix
    fn generateUniqueName(self: *ResourceManager, resource_type: ResourceType, prefix: []const u8) ![]const u8 {
        // Use a static counter for each resource type to ensure uniqueness
        var buffer: [64]u8 = undefined;

        const used_id = switch (resource_type) {
            .Model => self.next_model_id,
            .Mesh => self.next_mesh_id,
            .Material => self.next_material_id,
            .Texture => self.next_texture_id,
            .Shader => self.next_shader_id,
        };


        // Create custom name using prefix and the next recourse type id
        const name = try std.fmt.bufPrint(&buffer, "{s}{d}", .{prefix, used_id});
        
        // Increment the appropriate counter
        switch (resource_type) {
            .Model => self.next_model_id += 1,
            .Mesh => self.next_mesh_id += 1,
            .Material => self.next_material_id += 1,
            .Texture => self.next_texture_id += 1,
            .Shader => self.next_shader_id += 1,
        }
        
        // Return a duplicate that will be owned by the resource manager
        return try self.allocator.dupe(u8, name);
    }

    /// Collect reference counts for all resources before cleanup
    fn collectResourceRefs(
        self: *ResourceManager,
        model_refs: *std.ArrayList(ResourceRefInfo),
        mesh_refs: *std.ArrayList(ResourceRefInfo),
        material_refs: *std.ArrayList(ResourceRefInfo),
        texture_refs: *std.ArrayList(ResourceRefInfo),
        shader_refs: *std.ArrayList(ResourceRefInfo),
    ) !void {
        // Collect model reference counts
        {
            var iter = self.models.iterator();
            while (iter.next()) |entry| {
                const model = entry.value_ptr.*;
                const name = try self.allocator.dupe(u8, entry.key_ptr.*);
                errdefer self.allocator.free(name);
                
                try model_refs.append(.{
                    .name = name,
                    .resource_type = .Model,
                    .ref_count = model.ref_count.load(.monotonic),
                });
            }
        }

        // Collect mesh reference counts
        {
            var iter = self.meshes.iterator();
            while (iter.next()) |entry| {
                const mesh = entry.value_ptr.*;
                const name = try self.allocator.dupe(u8, entry.key_ptr.*);
                errdefer self.allocator.free(name);
                
                try mesh_refs.append(.{
                    .name = name,
                    .resource_type = .Mesh,
                    .ref_count = mesh.ref_count.load(.monotonic),
                });
            }
        }

        // Collect material reference counts
        {
            var iter = self.materials.iterator();
            while (iter.next()) |entry| {
                const material = entry.value_ptr.*;
                const name = try self.allocator.dupe(u8, entry.key_ptr.*);
                errdefer self.allocator.free(name);
                
                try material_refs.append(.{
                    .name = name,
                    .resource_type = .Material,
                    .ref_count = material.ref_count.load(.monotonic),
                });
            }
        }

        // Collect texture reference counts
        {
            var iter = self.textures.iterator();
            while (iter.next()) |entry| {
                const texture = entry.value_ptr.*;
                const path = try self.allocator.dupe(u8, entry.key_ptr.*);
                errdefer self.allocator.free(path);
                
                try texture_refs.append(.{
                    .name = path,
                    .resource_type = .Texture,
                    .ref_count = texture.ref_count.load(.monotonic),
                });
            }
        }

        // Collect shader reference counts
        {
            var iter = self.shaders.iterator();
            while (iter.next()) |entry| {
                const shader = entry.value_ptr.*;
                const name = try self.allocator.dupe(u8, entry.key_ptr.*);
                errdefer self.allocator.free(name);
                
                try shader_refs.append(.{
                    .name = name,
                    .resource_type = .Shader,
                    .ref_count = shader.ref_count.load(.monotonic),
                });
            }
        }
    }


    /// Print reference count information for a specific type of resource
    fn printRefCounts(self: *ResourceManager, res_type: ResourceType, refs: std.ArrayList(ResourceRefInfo)) void {
        std.debug.print("\n--- {s} Reference Counts Before Cleanup ---\n", .{@tagName(res_type)});
        
        if (refs.items.len == 0) {
            std.debug.print("No {s} resources found.\n", .{@tagName(res_type)});
            return;
        }
        
        var total_refs: u32 = 0;
        for (refs.items) |ref_info| {
            std.debug.print("{s} - Refs: {d}\n", .{ref_info.name, ref_info.ref_count});
            total_refs += ref_info.ref_count;
            self.allocator.free(ref_info.name); // Free the duplicated ID string
        }
        
        std.debug.print("Total reference count for {s}: {d}\n", .{@tagName(res_type), total_refs});
    }
};
