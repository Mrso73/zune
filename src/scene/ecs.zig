const std = @import("std");

// --- Error Management --- //
/// Possible errors that can occur during ECS operations

// TODO: Move error system to err module
pub const EcsError = error{
    ComponentNotFound,
    EntityNotFound,
    DuplicateComponent,
    InvalidEntity,
    SystemError,
};



// --- Entity Management --- \\

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

/// Manages entity lifecycle including creation, destruction, and validation.
pub const EntityManager = struct {
    const Self = @This();
    
    allocator: std.mem.Allocator,
    generations: std.ArrayList(u32),
    free_indices: std.ArrayList(u32),
    
    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .allocator = allocator,
            .generations = std.ArrayList(u32).init(allocator),
            .free_indices = std.ArrayList(u32).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.generations.deinit();
        self.free_indices.deinit();
    }

    /// Creates a new entity and returns its ID.
    /// Uses recycled indices when available, otherwise creates a new one.
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

    /// Destroys an entity and recycles its index for future use.
    pub fn destroyEntity(self: *Self, entity: EntityId) !void {
        if (!self.isValid(entity)) return EcsError.InvalidEntity;

        try self.free_indices.append(entity.index);
        self.generations.items[entity.index] += 1;
    }

    pub fn isValid(self: Self, entity: EntityId) bool {
        return entity.index < self.generations.items.len and
            self.generations.items[entity.index] == entity.generation;
    }
};



// --- Component Storage --- \\

/// Generic component storage implementing a sparse set
pub fn ComponentStorage(comptime T: type) type {
    return struct {
        const Self = @This();
        
        /// Internal structure to store component data with its entity ID
        const ComponentData = struct {
            entity: EntityId,
            component: T,
        };

        allocator: std.mem.Allocator,

        /// Sparse array mapping entity indices to dense array indices
        entity_to_component_index: std.AutoHashMap(u32, usize),
        /// Dense array of actual component data
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

        /// Adds a component to an entity
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

            // Swap and pop for O(1) removal
            if (index != self.components.items.len - 1) {
                const last = self.components.items[self.components.items.len - 1];
                self.components.items[index] = last;
                try self.entity_to_component_index.put(last.entity.index, index);
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



// --- Component Registry --- \\

/// Central registry managing all entities and components.
/// Handles component registration, storage, and access.
pub const Registry = struct {
    const Self = @This();

    /// Unique identifier for component types
    const ComponentTypeId = u64;
    
    /// Stores component storage along
    const ComponentStorageMetadata = struct {
        ptr: *anyopaque,
        deinitFn: *const fn(*anyopaque, std.mem.Allocator) void, // Type-specific cleanup

        /// Creates store info with type information
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
            };
        }
    };

    allocator: std.mem.Allocator,
    entity_manager: EntityManager,

    // Stores component storage
    component_stores: std.AutoHashMap(ComponentTypeId, ComponentStorageMetadata),

    pub fn init(allocator: std.mem.Allocator) !Self {
        return .{
            .allocator = allocator,
            .entity_manager = try EntityManager.init(allocator),
            .component_stores = std.AutoHashMap(ComponentTypeId, ComponentStorageMetadata).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        // Clean up all component stores
        var iter = self.component_stores.iterator();
        while (iter.next()) |entry| {
            const info = entry.value_ptr.*;
            info.deinitFn(info.ptr, self.allocator);
        }
        self.component_stores.deinit();
        self.entity_manager.deinit();
    }

    /// Registers a new component
    pub fn registerComponent(self: *Self, comptime T: type) !void {
        // Generate consistent type ID using type name hash
        const type_id = std.hash.Wyhash.hash(0, @typeName(T));
        
        // Prevent duplicates
        if (self.component_stores.contains(type_id)) return;

        // Create type-specific storage
        const store = try self.allocator.create(ComponentStorage(T));
        store.* = ComponentStorage(T).init(self.allocator);

        try self.component_stores.put(
            type_id,
            ComponentStorageMetadata.create(T, store)
        );
    }


    /// Register a group of new components
    pub fn registerComponents(self: *Registry, comptime Components: anytype) !void {
        inline for (std.meta.fields(Components)) |field| {
            try self.registerComponent(field.type);
        }
    }

    /// Get component storage
    pub fn getComponentStorage(self: *Self, comptime T: type) !*ComponentStorage(T) {
        // Use same hashing method as registration
        const type_id = std.hash.Wyhash.hash(0, @typeName(T));
        
        const info = self.component_stores.get(type_id) orelse
            return EcsError.ComponentNotFound;

        // Cast back
        return @as(*ComponentStorage(T), @ptrCast(@alignCast(info.ptr)));
    }

    pub fn addComponent(self: *Registry, entity: EntityId, component: anytype) !void {
        const T = @TypeOf(component);
        var storage = try self.getComponentStorage(T);
        try storage.add(entity, component);
    }
};



// --- Query System --- \\

/// Query interface for efficiently iterating over entities with specific components
pub fn Query(comptime Components: type) type {
    return struct {
        const Self = @This();

        registry: *Registry,
        
        pub fn init(registry: *Registry) Self {
            return .{ .registry = registry };
        }

        /// Creates a new query iterator for the specified component types
        pub fn iter(self: *Self) !QueryIterator(Components) {
            return QueryIterator(Components).init(self.registry);
        }
    };
}

/// Iterator implementation for Query results
fn QueryIterator(comptime Components: type) type {
    return struct {
        const Self = @This();
        
        registry: *Registry,
        /// Current position in the iteration
        current_index: usize,

        pub fn init(registry: *Registry) Self {
            return .{
                .registry = registry,
                .current_index = 0,
            };
        }

        // TODO: this
        /// Returns the next matching entity's components or null when done
        pub fn next(self: *Self) !?Components {
            // Implementation depends on component type structure
            // This is a simplified version
            _ = self;
            return null;
        }
    };
}



// --- System Management --- \\

/// Represents a system in the ECS with its dependencies and execution function
pub const System = struct {
    const SystemFn = *const fn (*Registry) anyerror!void;
    
    /// Unique identifier
    name: []const u8,
    run: SystemFn,

    /// Names of systems that must run before this one
    dependencies: []const []const u8,
};

/// Manages system execution order and dependencies
pub const SystemManager = struct {
    const Self = @This();
    
    const SystemState = struct {
        system: System,
        executed: bool,
    };

    allocator: std.mem.Allocator,
    systems: std.StringHashMap(SystemState),
    execution_order: std.ArrayList([]const u8),

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .systems = std.StringHashMap(SystemState).init(allocator),
            .execution_order = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.systems.deinit();
        self.execution_order.deinit();
    }

    /// Registers a new system and updates execution order
    /// Returns error if adding the system would create a dependency cycle
    pub fn registerSystem(self: *Self, system: System) !void {
        const node = SystemState{
            .system = system,
            .executed = false,
        };
        
        try self.systems.put(system.name, node);
        try self.updateExecutionOrder();
    }

    /// Internal function to update system execution order using topological sort
    fn updateExecutionOrder(self: *Self) !void {
        self.execution_order.clearRetainingCapacity();
        var visited = std.StringHashMap(bool).init(self.allocator);
        defer visited.deinit();

        // Perform topological sort
        var iter = self.systems.iterator();
        while (iter.next()) |entry| {
            if (!visited.contains(entry.key_ptr.*)) {
                try self.solveSystemDependencies(entry.key_ptr.*, &visited);
            }
        }
    }

    fn solveSystemDependencies(self: *Self, name: []const u8, visited: *std.StringHashMap(bool)) !void {
        // Detect cycles
        if (visited.get(name)) |value| {
            if (!value) return error.CyclicDependency;
            return;
        }

        try visited.put(name, false);

        const system = self.systems.get(name) orelse return error.SystemNotFound;
        
        // Visit dependencies first
        for (system.system.dependencies) |dep| {
            try self.solveSystemDependencies(dep, visited);
        }

        try visited.put(name, true);
        try self.execution_order.append(name);
    }


    /// Executes all systems in dependency order
    /// Systems are executed exactly once per update
    pub fn update(self: *Self, registry: *Registry) !void {
        // Reset execution flags
        var iter = self.systems.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.executed = false;
        }

        // Execute systems in topologically sorted order
        for (self.execution_order.items) |name| {
            if (self.systems.getPtr(name)) |system| {
                if (!system.executed) {
                    try system.system.run(registry);
                    system.executed = true;
                }
            }
        }
    }
};

