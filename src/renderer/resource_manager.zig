// graphics/resource_manager.zig

const std = @import("std");

const Model = @import("model.zig").Model;
const Mesh = @import("mesh.zig").Mesh;
const VertexLayout = @import("mesh.zig").VertexLayout;
const Material = @import("material.zig").Material;
const Texture = @import("texture.zig").Texture;
const Shader = @import("shader.zig").Shader;


pub const ResourceError = error{
    ResourceNotFound,
    ResourceAllocationFailed,
    InvalidResourceType,
    ResourceAlreadyExists,
};


pub const ResourceType = enum {
    Model,
    Mesh,
    Material,
    Texture,
    Shader,
};


const ResourceRefInfo = struct {
    name: []u8,                     // Resource identifier
    ref_count: u32,                 // Reference count before cleanup
};


pub const ResourceManager = struct {
    allocator: std.mem.Allocator,

    // Hashmaps to store resources by ID/path
    models: ResourceCollection(Model),
    meshes: ResourceCollection(Mesh),
    materials: ResourceCollection(Material),
    textures: ResourceCollection(Texture),
    shaders: ResourceCollection(Shader),


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    /// Initialize a new resource manager
    pub fn create(allocator: std.mem.Allocator) !*ResourceManager {
        const resource_manager_ptr = try allocator.create(ResourceManager);
        errdefer allocator.destroy(resource_manager_ptr);

        resource_manager_ptr.* = ResourceManager{
            .allocator = allocator,
            .models = ResourceCollection(Model).init(allocator),
            .meshes = ResourceCollection(Mesh).init(allocator),
            .materials = ResourceCollection(Material).init(allocator),
            .textures = ResourceCollection(Texture).init(allocator),
            .shaders = ResourceCollection(Shader).init(allocator),
        };
        return resource_manager_ptr;
    }   


    // ============================================================
    // Public API: Resource Manipulation Functions
    // ============================================================


    /// Create a model with the given name
    pub fn createModel(self: *ResourceManager, name: []const u8) !*Model {
        return try self.models.createResource(name, Model.create, .{});
    }

    /// Release a reference to a model
    pub fn releaseModel(self: *ResourceManager, name: []const u8) !void {
        return try self.models.releaseResource(name);
    }
  
  
    
    /// Create a mesh with the given parameters
    pub fn createMesh(self: *ResourceManager, name: []const u8, data: []const f32, indices: []const u32, has_normals: bool) !*Mesh {
        return try self.meshes.createResource(name, Mesh.create, .{data, indices, has_normals});
    }

    pub fn createCubeMesh(self: *ResourceManager, name: []const u8) !*Mesh {
        return try self.meshes.createResource(name, Mesh.createCube, .{});
    }

    /// Release a reference to a mesh
    pub fn releaseMesh(self: *ResourceManager, name: []const u8) !void {
        return try self.meshes.releaseResource(name);
    }



    /// Create a material with the given parameters
    pub fn createMaterial(self: *ResourceManager, name: []const u8, shader: *Shader, color: [4]f32, texture: ?*Texture) !*Material {
        return try self.materials.createResource(name, Material.create, .{shader, color, texture});
    }

    /// Release a reference to a material
    pub fn releaseMaterial(self: *ResourceManager, name: []const u8) !void {
        return try self.materials.releaseResource(name);
    }



    /// Load a texture from file, or return existing if already loaded
    pub fn createTexture(self: *ResourceManager, path: []const u8) !*Texture {
        return try self.textures.createResource(path, Texture.createFromFile, .{path});
    }

    /// Release a reference to a texture
    pub fn releaseTexture(self: *ResourceManager, path: []const u8) !void {
        return try self.textures.releaseResource(path);
    }



    /// Create a shader from source code
    pub fn createShader(self: *ResourceManager, name: []const u8, vertex_source: []const u8, fragment_source: []const u8) !*Shader {
        return try self.shaders.createResource(name, Shader.create, .{vertex_source, fragment_source});
    }

    pub fn createColorShader(self: *ResourceManager, name: []const u8) !*Shader {
    return try self.shaders.createResource(name, Shader.createColorShader, .{});
}

    /// Release a reference to a shader
    pub fn releaseShader(self: *ResourceManager, name: []const u8) !void {
        return try self.shaders.releaseResource(name);
    }



    /// Clean up all resources and print debug info about remaining resources
    pub fn releaseAll(self: *ResourceManager) !void {
        std.debug.print("\n=== Resource Manager Cleanup Start ===\n", .{});
        
        // Track counts for debug output
        var total_models: usize = 0;
        var total_meshes: usize = 0;
        var total_materials: usize = 0;
        var total_textures: usize = 0;
        var total_shaders: usize = 0;
        
        // Print reference count information
        self.printRefCounts(.Model, try self.models.collectRefInfo());
        self.printRefCounts(.Mesh, try self.meshes.collectRefInfo());
        self.printRefCounts(.Material, try self.materials.collectRefInfo());
        self.printRefCounts(.Texture, try self.textures.collectRefInfo());
        self.printRefCounts(.Shader, try self.shaders.collectRefInfo());
        
        // IMPORTANT: We release resources in REVERSE order of dependencies:
        // 1. Models (depend on Materials and Meshes)
        // 2. Materials (depend on Shaders and Textures)
        // 3. Meshes (no dependencies)
        // 4. Textures (no dependencies)
        // 5. Shaders (no dependencies)
        
        // Clean up resources in order of dependencies
        total_models = self.models.releaseAll();
        total_materials = self.materials.releaseAll();
        total_meshes = self.meshes.releaseAll();
        total_textures = self.textures.releaseAll();
        total_shaders = self.shaders.releaseAll();
        
        // Deinit the collections
        self.models.deinit();
        self.materials.deinit();
        self.meshes.deinit();
        self.textures.deinit();
        self.shaders.deinit();
        
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
    
    
    /// Print reference count information for a specific type of resource
    fn printRefCounts(self: *ResourceManager, res_type: ResourceType, refs: []ResourceRefInfo) void {
        std.debug.print("\n--- {s} Reference Counts Before Cleanup ---\n", .{@tagName(res_type)});
        
        if (refs.len == 0) {
            std.debug.print("No {s} resources found.\n", .{@tagName(res_type)});
            self.allocator.free(refs); // Free the empty array
            return;
        }

        var total_refs: u32 = 0;
        for (refs) |ref_info| {
            std.debug.print("{s} - Refs: {d}\n", .{ref_info.name, ref_info.ref_count});
            total_refs += ref_info.ref_count;
            self.allocator.free(ref_info.name); // Free the duplicated ID string
        }
        std.debug.print("Total reference count for {s}: {d}\n", .{@tagName(res_type), total_refs});

        // Free the array after processing all items
        self.allocator.free(refs);
    }
};





/// A generic collection for managing resources of any type with reference counting
pub fn ResourceCollection(comptime T: type) type {
    return struct {
        const Self = @This();
        
        allocator: std.mem.Allocator,
        resources: std.StringHashMap(*T),

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .resources = std.StringHashMap(*T).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.resources.deinit();
        }
        

        /// Create or get a resource with the given name
        /// If the resource already exists, increments its reference count and returns it
        /// Otherwise, creates a new resource using provided create function
        pub fn createResource( self: *Self, name: []const u8, createFunc: anytype, args: anytype ) !*T {

            // Check if resource already exists
            if (self.resources.get(name)) |existing| {
                existing.addRef();
                return existing;
            }
            
            // Duplicate the name for storage
            const owned_name = try self.allocator.dupe(u8, name);
            errdefer self.allocator.free(owned_name);
            
            // Create the resource
            const resource = try @call(.auto, createFunc, .{self.allocator} ++ args);
            errdefer _ = resource.release();
            
            // Add to the hash map
            try self.resources.put(owned_name, resource);
            return resource;
        }


        /// Release a reference to a resource by name
        /// If the reference count reaches zero, the resource is removed from the collection
        pub fn releaseResource(self: *Self, name: []const u8) !void {
            const entry = self.resources.getEntry(name) orelse return ResourceError.ResourceNotFound;
            const resource = entry.value_ptr.*;
            const prev = resource.release();
            
            // If this was the last reference, remove from the hashmap and free the key
            if (prev == 1) {
                const key = entry.key_ptr.*;
                _ = self.resources.remove(name);
                self.allocator.free(key);
            }
        }


        /// Get a resource by name (doesn't increment reference count)
        pub fn getResource(self: *Self, name: []const u8) ?*T {
            return self.resources.get(name);
        }
        

        /// Collects reference information for all resources in this collection
        pub fn collectRefInfo(self: *Self) ![]ResourceRefInfo {
            var ref_info_list = try self.allocator.alloc(ResourceRefInfo, self.resources.count());

            // Create a mutable iterator
            var iter = self.resources.iterator();
            var i: usize = 0;

            while (iter.next()) |entry| {
                const resource = entry.value_ptr.*;
                const name = try self.allocator.dupe(u8, entry.key_ptr.*);
                errdefer self.allocator.free(name);
                
                ref_info_list[i] = .{
                    .name = name,
                    .ref_count = resource.ref_count.load(.monotonic),
                };
                
                i += 1;
            }

            return ref_info_list;
        }

        
        /// Releases all resources in this collection
        pub fn releaseAll(self: *Self) usize {
            var count: usize = 0;
            var iter = self.resources.iterator();
            while (iter.next()) |entry| {
                const resource = entry.value_ptr.*;
                count += 1;
                
                _ = resource.release();
                self.allocator.free(entry.key_ptr.*);
            }
            return count;
        }
    };
}