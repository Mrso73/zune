// graphics/model.zig
const std = @import("std");

const Mesh = @import("mesh.zig").Mesh;
const Material = @import("material.zig").Material;


pub const ModelError = error{
    OutOfSpace,
    InvalidIndex,
    MeshNotFound,
    MaterialNotFound,
};


pub const MeshMaterialPair = struct {
    mesh: *Mesh,
    material: *Material,
}; 


pub const Model = struct {
    pairs: std.ArrayList(MeshMaterialPair),

    is_managed: bool = false,
    ref_count: std.atomic.Value(u32),
    allocator: std.mem.Allocator,

    
    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    /// Initialize a new model and return a pointer to it
    pub fn create(allocator: std.mem.Allocator) !*Model {
        const model_ptr = try allocator.create(Model);
        model_ptr.* = .{
            .pairs = std.ArrayList(MeshMaterialPair).init(allocator),
            .allocator = allocator,
            .ref_count = std.atomic.Value(u32).init(1),
        };
        return model_ptr;
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    pub fn addRef(self: *Model) void {
        _ = self.ref_count.fetchAdd(1, .monotonic);
    }


    pub fn addMeshMaterial(self: *Model, mesh: *Mesh, material: *Material) !void {
        mesh.addRef();
        material.addRef();
        try self.pairs.append(.{ .mesh = mesh, .material = material });
    }


    pub fn getMeshMaterialCount(self: *Model) usize {
        return self.pairs.items.len;
    }


    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    pub fn release(self: *Model) u32 {
        const prev = self.ref_count.fetchSub(1, .monotonic);
        if (prev == 1) {
            
            for (self.pairs.items) |pair| {
                _ = pair.mesh.release();
                _ = pair.material.release();
            }

            self.pairs.deinit();
            self.allocator.destroy(self);
        }
        return prev;
    }
};