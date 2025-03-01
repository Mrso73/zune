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


/// Represents a unique entity id with generation counting to prevent confusion after destruction and recreation
pub const EntityId = struct {

    /// Index in the entity array
    index: u32,
    /// Generation counter to prevent using stale entity references
    generation: u32,
    

    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    /// Check if entity is valid (not the invalid sentinel value)
    pub fn isValid(self: EntityId) bool {
        return self.index != std.math.maxInt(u32) and self.generation != 0;
    }
    

    /// Create an invalid entity ID (sentinel value)
    pub fn invalid() EntityId {
        return .{
            .index = std.math.maxInt(u32),
            .generation = 0,
        };
    }
};










/// Generic component storage using a sparse set approach
/// This allows O(1) addition, removal, and lookup of components
pub fn ComponentStorage(comptime T: type) type {
    return struct {
        const Self = @This();
        
        /// Stores entity ID alongside component data
        const ComponentData = struct {
            entity: EntityId,
            component: T,
        };

        /// Memory allocator
        allocator: std.mem.Allocator,
        /// Maps entity index to component position
        entity_to_index: std.AutoHashMap(u32, usize),
        /// Stores actual component data
        components: std.ArrayList(ComponentData),


        // ============================================================
        // Public API: Creation Functions
        // ============================================================

        /// Initialize a new component storage
        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .entity_to_index = std.AutoHashMap(u32, usize).init(allocator),
                .components = std.ArrayList(ComponentData).init(allocator),
            };
        }


        // ============================================================
        // Public API: Operational Functions
        // ============================================================

        /// Add a component to an entity
        pub fn add(self: *Self, entity: EntityId, component: T) !void {

            // Check if entity already has this component
            if (self.entity_to_index.get(entity.index)) |_| {
                return EcsError.DuplicateComponent;
            }
            
            // Add to the end of the components list
            const index = self.components.items.len;
            try self.entity_to_index.put(entity.index, index);
            try self.components.append(.{
                .entity = entity,
                .component = component,
            });
        }


        /// Remove a component from an entity
        pub fn remove(self: *Self, entity: EntityId) !void {
            const index = self.entity_to_index.get(entity.index) orelse
                return EcsError.ComponentNotFound;
            
            // Remove from the index map
            _ = self.entity_to_index.remove(entity.index);
            
            // If not the last element, move the last element to fill the gap
            if (index != self.components.items.len - 1) {
                const last = self.components.items[self.components.items.len - 1];
                self.components.items[index] = last;
                
                // Update the index of the moved component
                try self.entity_to_index.put(last.entity.index, index);
            }
            
            // Remove the now-redundant last element
            _ = self.components.pop();
        }


        /// Get a component for an entity if it exists
        pub fn get(self: *Self, entity: EntityId) ?*T {
            if (self.entity_to_index.get(entity.index)) |index| {
                return &self.components.items[index].component;
            }
            return null;
        }


        /// Get all components for iteration
        pub fn iter(self: *Self) []ComponentData {
            return self.components.items;
        }


        /// Run a function for each component and its entity
        pub fn forEach(self: *Self, comptime func: fn (entity: EntityId, component: *T) void) void {
            for (self.components.items) |*data| {
                func(data.entity, &data.component);
            }
        }


        // ============================================================
        // Public API: Destruction Function
        // ============================================================

        /// Free all allocated resources
        pub fn deinit(self: *Self) void {
            self.entity_to_index.deinit();
            self.components.deinit();
        }
    };
}










/// Registry that manages entities, components, and their relationships
pub const Registry = struct {
    const Self = @This();

     /// Type ID for component type identification
    const ComponentTypeId = u64;
    
    /// Interface for type-erased component storage operations
    const ComponentStorageInterface = struct {
        ptr: *anyopaque,
        deinit_fn: *const fn(*anyopaque, std.mem.Allocator) void,
        remove_fn: *const fn(*anyopaque, EntityId) EcsError!void,

        /// Create interface to a component storage
         fn create(comptime T: type, store: *ComponentStorage(T), comptime auto_deinit: bool) ComponentStorageInterface {
            return .{
                .ptr = store,

                // Deinit function
                .deinit_fn = struct {
                    fn deinitFn(ptr: *anyopaque, allocator: std.mem.Allocator) void {
                        const storage = @as(*ComponentStorage(T), @ptrCast(@alignCast(ptr)));
                        
                        // If auto_deinit is enabled and component has deinit method, call it
                        if (auto_deinit and @hasDecl(T, "deinit")) {
                            for (storage.components.items) |item| {
                                item.component.deinit();
                            }
                        }
                        
                        storage.deinit();
                        allocator.destroy(storage); // Free the storage struct itself
                    }
                }.deinitFn,

                // Remove function
                .remove_fn = struct {
                    fn removeFn(ptr: *anyopaque, entity: EntityId) EcsError!void {
                        const storage = @as(*ComponentStorage(T), @ptrCast(@alignCast(ptr)));
                        return storage.remove(entity);
                    }
                }.removeFn,
            };
        }
    };


    /// Memory allocator
    allocator: std.mem.Allocator,
    /// Tracks entity generations
    generations: std.ArrayList(u32),
    /// Stores available entity indices for reuse
    free_indices: std.ArrayList(u32),
    /// Maps component type IDs to storage instances
    component_stores: std.AutoHashMap(ComponentTypeId, ComponentStorageInterface),


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    /// Create a new registry
    pub fn create(allocator: std.mem.Allocator) !*Self {
        const registry_ptr = try allocator.create(Self);
        registry_ptr.* = .{
            .allocator = allocator,
            .generations = std.ArrayList(u32).init(allocator),
            .free_indices = std.ArrayList(u32).init(allocator),
            .component_stores = std.AutoHashMap(ComponentTypeId, ComponentStorageInterface).init(allocator),
        };
        return registry_ptr;
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    /// Create a new entity
    pub fn createEntity(self: *Self) !EntityId {
        
        // Reuse a freed entity index if available
        if (self.free_indices.items.len > 0) {
            const index = self.free_indices.pop() orelse unreachable; // Should never fail since length is checked 
            const generation = self.generations.items[index];
            return EntityId{ .index = index, .generation = generation };
        }

        // Create a new entity at the end
        const index: u32 = @intCast(self.generations.items.len);
        try self.generations.append(1);
        return EntityId{ .index = index, .generation = 1 };
    }


    /// Destroy an entity and all its components
    pub fn destroyEntity(self: *Self, entity: EntityId) !void {

        if (!self.isValidEntity(entity)) {
            return EcsError.InvalidEntity;
        }

        // Remove all components attached to the entity
        var iter = self.component_stores.iterator();
        while (iter.next()) |entry| {
            const interface = entry.value_ptr.*;
            
            // Try to remove the component, ignore if not found
            interface.remove_fn(interface.ptr, entity) catch |err| {
                if (err != EcsError.ComponentNotFound) {
                    return err;
                }
            };
        }

        // Mark entity as free and add 1 to generation to invalidate existing references
        try self.free_indices.append(entity.index);
        self.generations.items[entity.index] += 1;
    }


    /// Check if an entity ID is valid in this registry
    pub fn isValidEntity(self: Self, entity: EntityId) bool {
        return entity.index < self.generations.items.len and
               self.generations.items[entity.index] == entity.generation;
    }


    /// Register a component type with automatic cleanup
    pub fn registerAutoDeinitComponent(self: *Self, comptime T: type) !void {
        try self.registerComponentInternal(T, true);
    }


    /// Register a component type
    pub fn registerComponent(self: *Self, comptime T: type) !void {
        try self.registerComponentInternal(T, false);
    }


    /// Add a component to an entity
    pub fn addComponent(self: *Self, entity: EntityId, component: anytype) !void {
        const T = @TypeOf(component);
        const storage = try self.getComponentStorage(T);
        try storage.add(entity, component);
    }


    /// Remove a component from an entity
    pub fn removeComponent(self: *Self, entity: EntityId, comptime T: type) !void {
        const storage = try self.getComponentStorage(T);
        try storage.remove(entity);
    }
    

    /// Get a component from an entity
    pub fn getComponent(self: *Self, entity: EntityId, comptime T: type) ?*T {
        const storage = self.getComponentStorage(T) catch return null;
        return storage.get(entity);
    }


    /// Create a query for entities with specific components
    pub fn query(self: *Self, comptime Components: type) !Query(Components) {
        return Query(Components).init(self);
    }


    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    /// Free all resources and destroy the registry
    pub fn release(self: *Self) void {

        // Deinit all component storages
        var iter = self.component_stores.iterator();
        while (iter.next()) |entry| {
            const interface = entry.value_ptr.*;
            interface.deinit_fn(interface.ptr, self.allocator);
        }

        // Deinit other resources
        self.component_stores.deinit();
        self.generations.deinit();
        self.free_indices.deinit();

        // Free the registry itself
        self.allocator.destroy(self);
    }


    // ============================================================
    // Private: Helper Functions
    // ============================================================

    /// Internal function to register a component with optional auto-deinit
    fn registerComponentInternal(self: *Self, comptime T: type, comptime auto_deinit: bool) !void {
        const type_id = std.hash.Wyhash.hash(0, @typeName(T));
        if (self.component_stores.contains(type_id)) {
            return; // Already registered
        }
        
        // Create new component storage
        const store = try self.allocator.create(ComponentStorage(T));
        store.* = ComponentStorage(T).init(self.allocator);
        
        // Add to component stores
        try self.component_stores.put(
            type_id,
            ComponentStorageInterface.create(T, store, auto_deinit)
        );
    }


    /// Get the storage for a component type
    fn getComponentStorage(self: *Self, comptime T: type) !*ComponentStorage(T) {
        const type_id = std.hash.Wyhash.hash(0, @typeName(T));
        const interface = self.component_stores.get(type_id) orelse
            return EcsError.ComponentNotFound;
        return @as(*ComponentStorage(T), @ptrCast(@alignCast(interface.ptr)));
    }
};










/// Query system to efficiently iterate over entities with specific components
pub fn Query(comptime Components: type) type {
    return struct {
        const Self = @This();
        
        /// Reference to the registry
        registry: *Registry,
        /// Storage for each component type in the query
        storages: QueryStorages,
        /// Current index in the iteration
        current_index: usize = 0,
        

        /// Compile-time generated struct that holds references to component storages
        const QueryStorages = blk: {
            const fields = std.meta.fields(Components);
            var storage_fields: [fields.len]std.builtin.Type.StructField = undefined;
            
            for (fields, 0..) |field, i| {

                // Get the actual component type (handle both value and pointer types)
                const FieldType = switch (@typeInfo(field.type)) {
                    .pointer => |ptr| ptr.child,
                    else => field.type,
                };

                storage_fields[i] = .{
                    .name = field.name,
                    .type = *ComponentStorage(FieldType),
                    .default_value_ptr = null,
                    .is_comptime = false,
                    .alignment = @alignOf(*ComponentStorage(FieldType)),
                };
            }
            
            break :blk @Type(.{
                .@"struct" = .{
                    .layout = .auto,
                    .fields = &storage_fields,
                    .decls = &[_]std.builtin.Type.Declaration{},
                    .is_tuple = false,
                },
            });
        };


        // ============================================================
        // Public API: Creation Functions
        // ============================================================

        /// Initialize a new query
        pub fn init(registry: *Registry) !Self {
            var result = Self{
                .registry = registry,
                .storages = undefined,
                .current_index = 0,
            };

            // Get storage for each component type
            inline for (std.meta.fields(Components)) |field| {
                const FieldType = switch (@typeInfo(field.type)) {
                    .pointer => |ptr| ptr.child,
                    else => field.type,
                };
                
                @field(result.storages, field.name) = try registry.getComponentStorage(FieldType);
            }
            
            return result;
        }


        // ============================================================
        // Public API: Operational Functions
        // ============================================================

        /// Get the next entity that matches the query
        pub fn next(self: *Self) !?Components {

            // Use the first component's storage to lead iteration
            const first_field = std.meta.fields(Components)[0];
            const first_storage = @field(self.storages, first_field.name);

            // Iterate until we find an entity with all components or reach the end
            while (self.current_index < first_storage.components.items.len) {
                const entity = first_storage.components.items[self.current_index].entity;
                self.current_index += 1;

                // Check if the entity has all required components
                var result: Components = undefined;
                var all_components_present = true;

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

        
        /// Reset the query to start from the beginning
        pub fn reset(self: *Self) void {
            self.current_index = 0;
        }


        /// Iterate over all matching entities
        pub fn forEach(self: *Self, comptime callback: fn (components: Components) void) !void {
            self.reset();
            while (try self.next()) |components| {
                callback(components);
            }
        }
    };
}
