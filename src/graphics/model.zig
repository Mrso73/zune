// graphics/model.zig

const std = @import("std");
const Mesh = @import("mesh.zig").Mesh;
const Material = @import("material.zig").Material;

// TODO: move error system to err module
pub const ModelError = error{
    OutOfSpace,
    InvalidIndex,
    MeshNotFound,
    MaterialNotFound,
};

pub const Model = struct {
    meshes: std.ArrayList(*Mesh),
    materials: std.ArrayList(*Material),
    allocator: std.mem.Allocator,
    owns_resources: bool,
    

    // ==== Struct creation and deletion ==== \\

    /// Initialize a new model with empty dynamic lists for meshes and materials.
    pub fn init(allocator: std.mem.Allocator, owns_resources: bool) !Model {
        return Model{
            .meshes = std.ArrayList(*Mesh).init(allocator),
            .materials = std.ArrayList(*Material).init(allocator),
            .allocator = allocator,
            .owns_resources = owns_resources,
        };
    }


    /// Clean up model resources.
    pub fn deinit(self: *Model) void {
        if (self.owns_resources) {
            // Free meshes
            for (self.meshes.items) |mesh_ptr| {
                mesh_ptr.deinit();
                self.allocator.destroy(mesh_ptr);
            }
            // Free materials
            for (self.materials.items) |material_ptr| {
                material_ptr.deinit();
                self.allocator.destroy(material_ptr);
            }
        }
        self.meshes.deinit();
        self.materials.deinit();
    }

    /// Add a mesh to the model. If owns_resources is true, clone the mesh.
    pub fn addMesh(self: *Model, mesh: *Mesh) !void {
        if (self.owns_resources) {
            const cloned = try self.allocator.create(Mesh);
            // For a deep copy, you would also duplicate the OpenGL buffers if needed.
            cloned.* = mesh.*;
            try self.meshes.append(cloned);
        } else {
            try self.meshes.append(mesh);
        }
    }

    /// Remove a mesh from the model.
    pub fn removeMesh(self: *Model, index: usize) ModelError!void {
        if (index >= self.meshes.items.len) {
            return ModelError.InvalidIndex;
        }
        if (self.owns_resources) {
            const mesh = self.meshes.items[index];
            mesh.deinit();
            self.allocator.destroy(mesh);
        }
        self.meshes.items.remove(index);
    }

    /// Add a material to the model.
    pub fn addMaterial(self: *Model, material: *Material) !void {
        if (self.owns_resources) {
            // Clone the material if we own resources
            const new_material = try self.allocator.create(Material);
            errdefer self.allocator.destroy(new_material);
            new_material.* = material.*;
            // If material has a texture, increment its reference count
            if (new_material.texture) |texture| {
                texture.addRef();
            }
            try self.materials.append(new_material);
        } else {
            try self.materials.append(material);
        }
    }

    /// Remove a material from the model.
    pub fn removeMaterial(self: *Model, index: usize) ModelError!void {
        if (index >= self.materials.items.len) {
            return ModelError.InvalidIndex;
        }
        const material = self.materials.items[index];
        if (self.owns_resources) {
            // If we own the material, decrease texture reference count
            if (material.texture) |texture| {
                texture.release();
            }
            material.deinit();
            self.allocator.destroy(material);
        }
        _ = self.materials.orderedRemove(index);
    }

    // ==== UTILITY FUNCTIONS ==== \\

    pub fn getMeshCount(self: *Model) usize {
        return self.meshes.items.len;
    }

    pub fn getMaterialCount(self: *Model) usize {
        return self.materials.items.len;
    }

    pub fn getMesh(self: *Model, index: usize) ModelError!*Mesh {
        if (index >= self.meshes.items.len) {
            return ModelError.InvalidIndex;
        }
        return self.meshes.items[index];
    }
};