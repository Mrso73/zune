const std = @import("std");

/// Possible errors that can occur during ECS operations
pub const EcsError = error{
    ComponentNotFound,
    EntityNotFound,
    DuplicateComponent,
    InvalidEntity,
    SystemError,
    OutOfMemory,
};

/// Represents a unique entity identifier with generation counting
pub const EntityId = struct {
    index: u32,
    generation: u32,

    pub fn isValid(self: EntityId) bool {
        return self.index != std.math.maxInt(u32) and self.generation != 0;
    }

    pub fn invalid() EntityId {
        return .{
            .index = std.math.maxInt(u32),
            .generation = 0,
        };
    }
};

/// Generic component storage implementing a sparse set
pub fn ComponentStorage(comptime T: type) type {
    return struct {
        const Self = @This();
        
        const ComponentData = struct {
            entity: EntityId,
            component: T,
        };

        allocator: std.mem.Allocator,
        entity_to_component_index: std.AutoHashMap(u32, usize),
        components: std.ArrayList(ComponentData),

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .entity_to_component_index = std.AutoHashMap(u32, usize).init(allocator),
                .components = std.ArrayList(ComponentData).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.entity_to_component_index.deinit();
            self.components.deinit();
        }

        pub fn add(self: *Self, entity: EntityId, component: T) !void {
            if (self.entity_to_component_index.get(entity.index)) |_| {
                return EcsError.DuplicateComponent;
            }

            const index = self.components.items.len;
            try self.entity_to_component_index.put(entity.index, index);
            try self.components.append(.{
                .entity = entity,
                .component = component,
            });
        }

        pub fn remove(self: *Self, entity: EntityId) !void {
            const index = self.entity_to_component_index.get(entity.index) orelse
                return EcsError.ComponentNotFound;

            _ = self.entity_to_component_index.remove(entity.index);

            if (index != self.components.items.len - 1) {
                const last = self.components.items[self.components.items.len - 1];
                self.components.items[index] = last;

                self.entity_to_component_index.put(last.entity.index, index) catch |err| switch (err) {
                    error.OutOfMemory => return EcsError.OutOfMemory,
                };
            }
            _ = self.components.pop();
        }

        pub fn get(self: *Self, entity: EntityId) ?*T {
            if (self.entity_to_component_index.get(entity.index)) |index| {
                return &self.components.items[index].component;
            }
            return null;
        }

        pub fn iter(self: *Self) []ComponentData {
            return self.components.items;
        }
    };
}









// --- ECS Centre Point --- \\

/// Central registry managing all entities, components, and systems
pub const Registry = struct {
    const Self = @This();
    const ComponentTypeId = u64;
    
    const ComponentStorageMetadata = struct {
        ptr: *anyopaque,
        deinitFn: *const fn(*anyopaque, std.mem.Allocator) void,
        removeFn: *const fn(*anyopaque, EntityId) EcsError!void,

        fn create(comptime T: type, store: *ComponentStorage(T)) ComponentStorageMetadata {
            return .{
                .ptr = store,
                .deinitFn = (struct {
                    fn deinitErased(ptr: *anyopaque, allocator: std.mem.Allocator) void {
                        const storage = @as(*ComponentStorage(T), @ptrCast(@alignCast(ptr)));
                        storage.deinit();
                        allocator.destroy(storage);
                    }
                }).deinitErased,
                .removeFn = (struct {
                    fn removeErased(ptr: *anyopaque, entity: EntityId) EcsError!void {
                        const storage = @as(*ComponentStorage(T), @ptrCast(@alignCast(ptr)));
                        try storage.remove(entity);
                    }
                }).removeErased,
            };
        }
    };

    allocator: std.mem.Allocator,
    generations: std.ArrayList(u32),
    free_indices: std.ArrayList(u32),
    component_stores: std.AutoHashMap(ComponentTypeId, ComponentStorageMetadata),

    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    pub fn init(allocator: std.mem.Allocator) !*Self {
        const registry_ptr = try allocator.create(Self);
        registry_ptr.* = .{
            .allocator = allocator,
            .generations = std.ArrayList(u32).init(allocator),
            .free_indices = std.ArrayList(u32).init(allocator),
            .component_stores = std.AutoHashMap(ComponentTypeId, ComponentStorageMetadata).init(allocator),
        };
        return registry_ptr;
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    // New simplified entity creation
    pub fn createEntity(self: *Self) !EntityId {
        if (self.free_indices.items.len > 0) {
            const index = self.free_indices.pop();
            const generation = self.generations.items[index];
            return EntityId{ .index = index, .generation = generation };
        }

        const index: u32 = @intCast(self.generations.items.len);
        try self.generations.append(1);
        return EntityId{ .index = index, .generation = 1 };
    }


    pub fn destroyEntity(self: *Self, entity: EntityId) !void {
        if (!self.isValidEntity(entity)) return EcsError.InvalidEntity;

        // Remove all components 
        var iter = self.component_stores.iterator();
        while (iter.next()) |entry| {
            const info = entry.value_ptr.*;
            
            // Try to remove component if it exists
            info.removeFn(info.ptr, entity) catch |err| switch (err) {
                EcsError.ComponentNotFound => {}, // Ignore missing components
                else => return err, // Propagate other errors
            };
        }

        try self.free_indices.append(entity.index);
        self.generations.items[entity.index] += 1;
    }

    pub fn isValidEntity(self: Self, entity: EntityId) bool {
        return entity.index < self.generations.items.len and
            self.generations.items[entity.index] == entity.generation; // GENERATION CHECK
    }


    // New simplified component registration
    pub fn registerComponent(self: *Self, comptime T: type) !void {
        const type_id = std.hash.Wyhash.hash(0, @typeName(T));
        if (self.component_stores.contains(type_id)) return;

        const store = try self.allocator.create(ComponentStorage(T));
        store.* = ComponentStorage(T).init(self.allocator);

        try self.component_stores.put(
            type_id,
            ComponentStorageMetadata.create(T, store)
        );
    }


    // New simplified component addition
    pub fn addComponent(self: *Self, entity: EntityId, component: anytype) !void {
        const T = @TypeOf(component);
        const storage = try self.getComponentStorage(T);
        try storage.add(entity, component);
    }


    // Helper to get component storage
    fn getComponentStorage(self: *Self, comptime T: type) !*ComponentStorage(T) {
        const type_id = std.hash.Wyhash.hash(0, @typeName(T));
        const info = self.component_stores.get(type_id) orelse
            return EcsError.ComponentNotFound;
        return @as(*ComponentStorage(T), @ptrCast(@alignCast(info.ptr)));
    }


    // New query creation
    pub fn query(self: *Self, comptime Components: type) !Query(Components) {
        return Query(Components).init(self);
    }


    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    pub fn release(self: *Self) void {
        var iter = self.component_stores.iterator();
        while (iter.next()) |entry| {
            const info = entry.value_ptr.*;
            info.deinitFn(info.ptr, self.allocator);
        }
        self.component_stores.deinit();
        self.generations.deinit();
        self.free_indices.deinit();

        self.allocator.destroy(self);
    }
};










// --- Querying --- \\

// Improved query system
pub fn Query(comptime Components: type) type {
    return struct {
        const Self = @This();
        
        registry: *Registry,
        storages: QueryStorages,
        current_index: usize = 0,

        const QueryStorages = blk: {
            // Use tuple field names as component names
            const fields = std.meta.fields(Components);
            var storage_fields: [fields.len]std.builtin.Type.StructField = undefined;
            
            for (fields, 0..) |field, i| {

                // Extract underlying type if field is a pointer
                const actual_type = @typeInfo(field.type);
                const component_type = switch (actual_type) {
                    .Pointer => |ptr| ptr.child,
                    else => field.type,
                };

                storage_fields[i] = .{
                    .name = field.name,
                    .type = *ComponentStorage(component_type),
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = @alignOf(*ComponentStorage(component_type)),
                };
            }
            
            break :blk @Type(.{
                .Struct = .{
                    .layout = .auto,
                    .fields = &storage_fields,
                    .decls = &[_]std.builtin.Type.Declaration{},
                    .is_tuple = false,
                },
            });
        };

        pub fn init(registry: *Registry) !Self {
            var result: Self = .{
                .registry = registry,
                .storages = undefined,
                .current_index = 0,
            };

            // Get all required storages
            inline for (std.meta.fields(Components)) |field| {
                const actual_type = @typeInfo(field.type);
                const component_type = switch (actual_type) {
                    .Pointer => |ptr| ptr.child,
                    else => field.type,
                };
                @field(result.storages, field.name) = try registry.getComponentStorage(component_type);
            }

            return result;
        }

        pub fn next(self: *Self) !?Components {
            // Get the first component's storage
            const first_field = comptime std.meta.fields(Components)[0];
            const first_storage = @field(self.storages, first_field.name);

            while (self.current_index < first_storage.components.items.len) {
                const entity = first_storage.components.items[self.current_index].entity;
                self.current_index += 1;

                var all_components_present = true;
                var result: Components = undefined;

                inline for (std.meta.fields(Components)) |field| {
                    const storage = @field(self.storages, field.name);
                    if (storage.get(entity)) |component| {
                        @field(result, field.name) = component;
                    } else {
                        all_components_present = false;
                        break;
                    }
                }

                if (all_components_present) {
                    return result;
                }
            }

            return null;
        }
    };
}
