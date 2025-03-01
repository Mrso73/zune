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


    /// Create a Model with the given name
    pub fn createModel(self: *ResourceManager, name: []const u8) !*Model {
        return try self.models.createResource(name, Model.create, .{});
    }

    /// Create a Model with a generated name
    pub fn autoCreateModel(self: *ResourceManager, prefix: []const u8) !*Model {
        const name = try self.models.generateUniqueName(prefix);
        defer self.models.allocator.free(name); // Free the generated unique name after duplicating in createResource.

        return try self.models.createResource(name, Model.create, .{});
    }

    /// Release a reference to a Model
    pub fn releaseModel(self: *ResourceManager, name: []const u8) !void {
        return try self.models.releaseResource(name);
    }
  
  
    
    /// Create a Mesh with the given parameters
    pub fn createMesh(self: *ResourceManager, name: []const u8, data: []const f32, indices: []const u32, has_normals: bool) !*Mesh {
        return try self.meshes.createResource(name, Mesh.create, .{data, indices, has_normals});
    }

    /// Create a Mesh with a generated name
    pub fn autoCreateMesh(self: *ResourceManager, prefix: []const u8, data: []const f32, indices: []const u32, has_normals: bool) !*Mesh {
        const name = try self.meshes.generateUniqueName(prefix);
        defer self.meshes.allocator.free(name); // Free the generated unique name after duplicating in createResource.

        return try self.meshes.createResource(name, Mesh.create, .{data, indices, has_normals});
    }

    pub fn createCubeMesh(self: *ResourceManager, name: []const u8) !*Mesh {
        return try self.meshes.createResource(name, Mesh.createCube, .{});
    }

    /// Release a reference to a Mesh
    pub fn releaseMesh(self: *ResourceManager, name: []const u8) !void {
        return try self.meshes.releaseResource(name);
    }



    /// Create a Material with the given parameters
    pub fn createMaterial(self: *ResourceManager, name: []const u8, shader: *Shader, color: [4]f32, texture: ?*Texture) !*Material {
        return try self.materials.createResource(name, Material.create, .{shader, color, texture});
    }

    /// Create a Material with a generated name
    pub fn autoCreateMaterial(self: *ResourceManager, prefix: []const u8, shader: *Shader, color: [4]f32, texture: ?*Texture) !*Material {
        const name = try self.materials.generateUniqueName(prefix);
        defer self.materials.allocator.free(name); // Free the generated unique name after duplicating in createResource.

        return try self.materials.createResource(name, Material.create, .{shader, color, texture});
    }

    /// Release a reference to a Material
    pub fn releaseMaterial(self: *ResourceManager, name: []const u8) !void {
        return try self.materials.releaseResource(name);
    }



    /// Load a Texture from file, or return existing if already loaded
    pub fn createTexture(self: *ResourceManager, path: []const u8) !*Texture {
        return try self.textures.createResource(path, Texture.createFromFile, .{path});
    }

    /// Create a Texture with a generated name
    pub fn autoCreateTexture(self: *ResourceManager, prefix: []const u8, path: []const u8) !*Texture {
        const name = try self.textures.generateUniqueName(prefix);
        defer self.textures.allocator.free(name); // Free the generated unique name after duplicating in createResource.

        return try self.textures.createResource(name, Texture.createFromFile, .{path});
    }

    /// Release a reference to a Texture
    pub fn releaseTexture(self: *ResourceManager, path: []const u8) !void {
        return try self.textures.releaseResource(path);
    }



    /// Create a hader from source code
    pub fn createShader(self: *ResourceManager, name: []const u8, vertex_source: []const u8, fragment_source: []const u8) !*Shader {
        return try self.shaders.createResource(name, Shader.create, .{vertex_source, fragment_source});
    }

    /// Create a Shader with a generated name
    pub fn autoCreateShader(self: *ResourceManager, prefix: []const u8, vertex_source: []const u8, fragment_source: []const u8) !*Shader {
        const name = try self.shaders.generateUniqueName(prefix);
        defer self.shaders.allocator.free(name); // Free the generated unique name after duplicating in createResource.

        return try self.shaders.createResource(name, Shader.create, .{vertex_source, fragment_source});
    }

    pub fn createColorShader(self: *ResourceManager, name: []const u8) !*Shader {
        return try self.shaders.createResource(name, Shader.createColorShader, .{});
    }

    pub fn createTextureShader(self: *ResourceManager, name: []const u8) !*Shader {
        return try self.shaders.createResource(name, Shader.createTextureShader, .{});
    }

    /// Release a reference to a Shader
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

        next_id: u32 = 1,


        // ============================================================
        // Public API: Creation Functions
        // ============================================================

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .resources = std.StringHashMap(*T).init(allocator),
            };
        }


        // ============================================================
        // Public API: Resources Manipulation Functions
        // ============================================================

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


        /// Release a reference to a resource by pointer.
        /// This iterates over the collection to find the matching resource.
        pub fn releaseResourceByPtr(self: *Self, resource_ptr: *T) !void {
            var found: bool = false;
            var iter = self.resources.iterator();
            while (iter.next()) |entry| {
                if (entry.value_ptr.* == resource_ptr) {
                    found = true;
                    const prev = resource_ptr.release();
                    if (prev == 1) {
                        // Remove from hashmap and free the key.
                        const key = entry.key_ptr.*;
                        _ = self.resources.remove(key);
                        self.allocator.free(key);
                    }
                    break;
                }
            }
            if (!found) {
                return ResourceError.ResourceNotFound;
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


        // ============================================================
        // Public API: Destruction Functions
        // ============================================================

        pub fn deinit(self: *Self) void {
            self.resources.deinit();
        }


        // ============================================================
        // Private Helper Functions
        // ============================================================

        /// Generate a unique name for a resource widh a prefix
        pub fn generateUniqueName(self: *Self, prefix: []const u8) ![]const u8 {

            // Allocate the formatted string dynamically
            const tmp_name = try std.fmt.allocPrint(self.allocator, "{s}{d}", .{ prefix, self.next_id });
            defer self.allocator.free(tmp_name); // Make sure the temporary allocation is freed.

            // Duplicate the string to get an good sized allocation.
            const name = try self.allocator.dupe(u8, tmp_name);
            self.next_id += 1;
            return name;
        }
    };
}