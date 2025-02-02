// graphics/model.zig

const std = @import("std");
const Mesh = @import("mesh.zig").Mesh;
const Material = @import("material.zig").Material;
const Transform = @import("../scene/transform.zig").Transform;

pub const ModelError = error{
    OutOfSpace,
    InvalidIndex,
    MeshNotFound,
    MaterialNotFound,
};

pub const Model = struct {
    meshes: []*Mesh,
    materials: []*Material,
    mesh_count: usize,
    material_count: usize,
    transform: Transform,
    allocator: std.mem.Allocator,
    

    // ==== Struct creation and deletion ==== \\

    /// Initialize a new model with given mesh and material capacity
    pub fn initEmpty(allocator: std.mem.Allocator, mesh_capacity: usize, material_capacity: usize) !Model {
        return Model{
            .meshes = try allocator.alloc(*Mesh, mesh_capacity),
            .materials = try allocator.alloc(*Material, material_capacity),
            .transform = Transform.identity(),
            .mesh_count = 0,
            .material_count = 0,
            .allocator = allocator,
        };
    }


    /// Clean up model resources
    pub fn deinit(self: *Model) void {

        // Free meshes
        var i: usize = 0;
        while (i < self.mesh_count) : (i += 1) {
            self.meshes[i].deinit();
        }

        // Free materials - no need to call deinit() on materials
        i = 0;
        while (i < self.material_count) : (i += 1) {
            // Just destroy the allocated material instance
            // self.allocator.destroy(self.materials[i]);
        }

        self.allocator.free(self.meshes);
        self.allocator.free(self.materials);
    }

    // ==== MODEL MANAGEMENT ==== \\ 

    /// Add a mesh to the model
    pub fn addMesh(self: *Model, mesh: *Mesh) ModelError!void {
        if (self.mesh_count >= self.meshes.len) {
            return ModelError.OutOfSpace;
        }
        self.meshes[self.mesh_count] = mesh;
        self.mesh_count += 1;
    }

    pub fn removeMesh(self: *Model, index: usize) ModelError!void {
        if (index >= self.mesh_count) {
            return ModelError.InvalidIndex;
        }

        if (self.meshes[index]) |mesh| {
            mesh.deinit();
            self.allocator.destroy(mesh);
            
            // Shift remaining meshes
            var i = index;
            while (i < self.mesh_count - 1) : (i += 1) {
                self.meshes[i] = self.meshes[i + 1];
            }
            self.mesh_count -= 1;
        }
    }

    /// Add a material to the model
    pub fn addMaterial(self: *Model, material: *Material) ModelError!void {
        if (self.material_count >= self.materials.len) {
            return ModelError.OutOfSpace;
        }
        self.materials[self.material_count] = material;
        self.material_count += 1;
    }

    /// Remove a material from the model
    pub fn removeMaterial(self: *Model, index: usize) ModelError!void {
        if (index >= self.material_count) {
            return ModelError.InvalidIndex;
        }

        if (self.materials[index]) |material| {
            material.deinit();
            self.allocator.destroy(material);
            // Shift remaining materials
            var i = index;
            while (i < self.material_count - 1) : (i += 1) {
                self.materials[i] = self.materials[i + 1];
            }
            self.material_count -= 1;
        }
    }


    // ==== MATRIX STUFF ==== \\W


    // ==== UTILITY FUNCTIONS ==== \\

    pub fn getMeshCount(self: Model) usize {
        return self.mesh_count;
    }

    pub fn getMaterialCount(self: Model) usize {
        return self.material_count;
    }

    pub fn getMesh(self: Model, index: usize) ModelError!*Mesh {
        if (index >= self.mesh_count) {
            return ModelError.InvalidIndex;
        }
        return self.meshes[index];
    }
};