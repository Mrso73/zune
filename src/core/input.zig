const std = @import("std");
const c = @import("../c.zig");

// Maximum number of GLFW keys we track
pub const MAX_KEYS = 348; // GLFW_KEY_LAST
// Maximum number of key events to store in the event queue
pub const MAX_KEY_EVENTS = 32;

// Represents key state using bit flags for efficient storage and querying
pub const KeyState = packed struct {
    is_pressed: bool = false,
    is_repeated: bool = false,
    _padding: u6 = 0, // Ensure proper alignment

    pub fn fromGLFW(action: c_int) KeyState {
        return switch (action) {
            c.GLFW_PRESS => .{ .is_pressed = true },
            c.GLFW_RELEASE => .{},
            c.GLFW_REPEAT => .{ .is_pressed = true, .is_repeated = true },
            else => .{},
        };
    }

    pub fn isDown(self: KeyState) bool {
        return self.is_pressed;
    }

    pub fn isRepeating(self: KeyState) bool {
        return self.is_repeated;
    }

    pub fn isJustPressed(self: KeyState, previous: KeyState) bool {
        return self.is_pressed and !previous.is_pressed;
    }
};

// Key modifiers stored as packed bits
pub const KeyMods = packed struct {
    shift: bool = false,
    control: bool = false,
    alt: bool = false,
    super: bool = false,
    caps_lock: bool = false,
    num_lock: bool = false,
    _padding: u2 = 0, // Ensure proper alignment

    pub fn fromGLFW(mods: c_int) KeyMods {
        return .{
            .shift = (mods & c.GLFW_MOD_SHIFT) != 0,
            .control = (mods & c.GLFW_MOD_CONTROL) != 0,
            .alt = (mods & c.GLFW_MOD_ALT) != 0,
            .super = (mods & c.GLFW_MOD_SUPER) != 0,
            .caps_lock = (mods & c.GLFW_MOD_CAPS_LOCK) != 0,
            .num_lock = (mods & c.GLFW_MOD_NUM_LOCK) != 0,
        };
    }

    pub fn hasAnyModifier(self: KeyMods) bool {
        return self.shift or self.control or self.alt or self.super;
    }
};

// Structure to store key events for the event queue
const KeyEvent = packed struct {
    key: i32,
    state: KeyState,
    mods: KeyMods,
    timestamp: u64,
};

// Simple ring buffer implementation for key events
const KeyEventBuffer = struct {
    buffer: []KeyEvent,
    head: usize = 0,
    tail: usize = 0,
    len: usize = 0,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, capacity: usize) !KeyEventBuffer {
        const buffer = try allocator.alloc(KeyEvent, capacity);
        return KeyEventBuffer{
            .buffer = buffer,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *KeyEventBuffer) void {
        self.allocator.free(self.buffer);
    }

    pub fn write(self: *KeyEventBuffer, event: KeyEvent) bool {
        if (self.len == self.buffer.len) return false;

        self.buffer[self.tail] = event;
        self.tail = (self.tail + 1) % self.buffer.len;
        self.len += 1;
        return true;
    }

    pub fn read(self: *KeyEventBuffer) ?KeyEvent {
        if (self.len == 0) return null;

        const event = self.buffer[self.head];
        self.head = (self.head + 1) % self.buffer.len;
        self.len -= 1;
        return event;
    }

    pub fn clear(self: *KeyEventBuffer) void {
        self.head = 0;
        self.tail = 0;
        self.len = 0;
    }

    pub fn iterator(self: *const KeyEventBuffer) KeyEventIterator {
        return .{
            .buffer = self,
            .remaining = self.len,
            .current = self.head,
        };
    }
};

const KeyEventIterator = struct {
    buffer: *const KeyEventBuffer,
    remaining: usize,
    current: usize,

    pub fn next(self: *KeyEventIterator) ?KeyEvent {
        if (self.remaining == 0) return null;

        const event = self.buffer.buffer[self.current];
        self.current = (self.current + 1) % self.buffer.buffer.len;
        self.remaining -= 1;
        return event;
    }
};

// Main Input manager for handling keyboard input
pub const Input = struct {
    // Key state storage using fixed arrays
    current_keys: [MAX_KEYS]KeyState = [_]KeyState{.{}} ** MAX_KEYS,
    previous_keys: [MAX_KEYS]KeyState = [_]KeyState{.{}} ** MAX_KEYS,
    key_mods: KeyMods = .{},

    // Event queue
    key_events: KeyEventBuffer,

    // Callback system
    callback_context: ?*anyopaque = null,
    key_callback_fn: ?*const fn (*Input, c_int, KeyState, KeyMods) void = null,

    // Timestamp for event tracking
    last_event_time: u64 = 0,

    // Initialize the input system
    pub fn init(allocator: std.mem.Allocator) !Input {
        return Input{
            .key_events = try KeyEventBuffer.init(allocator, MAX_KEY_EVENTS),
        };
    }

    // Cleanup resources
    pub fn deinit(self: *Input) void {
        self.key_events.deinit();
    }

    // Set callback for key events
    pub fn setKeyCallback(
        self: *Input,
        context: ?*anyopaque,
        callback: ?*const fn (*Input, c_int, KeyState, KeyMods) void,
    ) void {
        self.callback_context = context;
        self.key_callback_fn = callback;
    }

    // Update input state (call once per frame)
    pub fn update(self: *Input) void {
        // Efficient memory copy of current to previous states
        @memcpy(&self.previous_keys, &self.current_keys);
        // Clear event queue
        self.key_events.clear();
    }

    // Process a key event from GLFW
    pub fn processKeyEvent(self: *Input, key: c_int, action: c_int, mods: c_int) void {
        if (key < 0 or key >= MAX_KEYS) return;

        const idx: usize = @intCast(key);
        const state = KeyState.fromGLFW(action);
        const key_mods = KeyMods.fromGLFW(mods);

        // Update state
        self.current_keys[idx] = state;
        self.key_mods = key_mods;

        // Add to event queue with current timestamp
        const event = KeyEvent{
            .key = key,
            .state = state,
            .mods = key_mods,
            .timestamp = @intCast(std.time.milliTimestamp()),
        };
        _ = self.key_events.write(event);

        // Call user callback if set
        if (self.key_callback_fn) |callback| {
            callback(self, key, state, key_mods);
        }
    }

    // Key state query methods
    pub fn isKeyPressed(self: *const Input, key: c_int) bool {
        if (key < 0 or key >= MAX_KEYS) return false;
        const idx: usize = @intCast(key);
        return self.current_keys[idx].isDown();
    }

    pub fn isKeyRepeating(self: *const Input, key: c_int) bool {
        if (key < 0 or key >= MAX_KEYS) return false;
        return self.current_keys[@intCast(key)].isRepeating();
    }

    pub fn wasKeyJustPressed(self: *const Input, key: c_int) bool {
        if (key < 0 or key >= MAX_KEYS) return false;
        const idx: usize = @intCast(key);
        return self.current_keys[idx].is_pressed and
            !self.previous_keys[idx].is_pressed;
    }

    pub fn wasKeyReleased(self: *const Input, key: c_int) bool {
        if (key < 0 or key >= MAX_KEYS) return false;
        const idx: usize = @intCast(key);
        return !self.current_keys[idx].is_pressed and
            self.previous_keys[idx].is_pressed;
    }

    // Key combination checks
    pub fn isKeyCombo(self: *const Input, key: c_int, required_mods: KeyMods) bool {
        return self.isKeyPressed(key) and std.meta.eql(self.key_mods, required_mods);
    }

    // Check if any of the given keys are pressed
    pub fn areAnyKeysPressed(self: *const Input, keys: []const c_int) bool {
        for (keys) |key| {
            if (self.isKeyPressed(key)) return true;
        }
        return false;
    }

    // Check if all of the given keys are pressed
    pub fn areAllKeysPressed(self: *const Input, keys: []const c_int) bool {
        for (keys) |key| {
            if (!self.isKeyPressed(key)) return false;
        }
        return true;
    }

    // Get current key modifiers state
    pub fn getKeyMods(self: *const Input) KeyMods {
        return self.key_mods;
    }

    // SIMD-optimized count of currently pressed keys
    pub fn countPressedKeys(self: *const Input) usize {
        const Vector = std.meta.Vector(4, KeyState);
        var count: usize = 0;
        var i: usize = 0;

        while (i + 4 <= MAX_KEYS) : (i += 4) {
            const vec = @as(Vector, self.current_keys[i..][0..4].*);
            count += @popCount(@as(u4, @bitCast(vec)));
        }

        // Handle remaining keys
        while (i < MAX_KEYS) : (i += 1) {
            if (self.current_keys[i].isDown()) count += 1;
        }

        return count;
    }

    // Comptime key group checker
    pub fn KeyGroup(comptime keys: []const c_int) type {
        return struct {
            pub fn areAllPressed(input: *const Input) bool {
                inline for (keys) |key| {
                    if (!input.isKeyPressed(key)) return false;
                }
                return true;
            }

            pub fn areAnyPressed(input: *const Input) bool {
                inline for (keys) |key| {
                    if (input.isKeyPressed(key)) return true;
                }
                return false;
            }
        };
    }

    // Debug helper
    pub fn debugPrint(self: *const Input, writer: anytype) !void {
        try writer.print("Input State:\n", .{});
        try writer.print("Pressed Keys: {d}\n", .{self.countPressedKeys()});
        try writer.print("Active Modifiers: {}\n", .{self.key_mods});

        // Print currently pressed keys
        for (self.current_keys, 0..) |state, i| {
            if (state.isDown()) {
                try writer.print("Key {d}: {}\n", .{ i, state });
            }
        }

        // Print recent events
        try writer.print("\nRecent Events:\n", .{});
        var it = self.key_events.iterator();
        while (it.next()) |event| {
            try writer.print("Key: {d}, State: {}, Mods: {}, Time: {d}ms\n", .{ event.key, event.state, event.mods, event.timestamp });
        }
    }

    // Key code constants
    pub const Key = struct {
        // Function keys
        pub const F1: c_int = c.GLFW_KEY_F1;
        pub const F2: c_int = c.GLFW_KEY_F2;
        pub const F3: c_int = c.GLFW_KEY_F3;
        pub const F4: c_int = c.GLFW_KEY_F4;
        pub const F5: c_int = c.GLFW_KEY_F5;
        pub const F6: c_int = c.GLFW_KEY_F6;
        pub const F7: c_int = c.GLFW_KEY_F7;
        pub const F8: c_int = c.GLFW_KEY_F8;
        pub const F9: c_int = c.GLFW_KEY_F9;
        pub const F10: c_int = c.GLFW_KEY_F10;
        pub const F11: c_int = c.GLFW_KEY_F11;
        pub const F12: c_int = c.GLFW_KEY_F12;

        // Letter keys
        pub const A: c_int = c.GLFW_KEY_A;
        pub const B: c_int = c.GLFW_KEY_B;
        pub const C: c_int = c.GLFW_KEY_C;
        // ... add all letters

        // Number keys
        pub const N0: c_int = c.GLFW_KEY_0;
        pub const N1: c_int = c.GLFW_KEY_1;
        pub const N2: c_int = c.GLFW_KEY_2;
        pub const N3: c_int = c.GLFW_KEY_3;
        pub const N4: c_int = c.GLFW_KEY_4;
        pub const N5: c_int = c.GLFW_KEY_5;
        pub const N6: c_int = c.GLFW_KEY_6;
        pub const N7: c_int = c.GLFW_KEY_7;
        pub const N8: c_int = c.GLFW_KEY_8;
        pub const N9: c_int = c.GLFW_KEY_9;

        // Special keys
        pub const SPACE: c_int = c.GLFW_KEY_SPACE;
        pub const ENTER: c_int = c.GLFW_KEY_ENTER;
        pub const ESCAPE: c_int = c.GLFW_KEY_ESCAPE;
        pub const TAB: c_int = c.GLFW_KEY_TAB;
        pub const BACKSPACE: c_int = c.GLFW_KEY_BACKSPACE;
        pub const INSERT: c_int = c.GLFW_KEY_INSERT;
        pub const DELETE: c_int = c.GLFW_KEY_DELETE;
        pub const RIGHT: c_int = c.GLFW_KEY_RIGHT;
        pub const LEFT: c_int = c.GLFW_KEY_LEFT;
        pub const DOWN: c_int = c.GLFW_KEY_DOWN;
        pub const UP: c_int = c.GLFW_KEY_UP;
    };

    // Common key groups for convenience
    pub const KeyGroups = struct {
        pub const ArrowKeys = KeyGroup(&[_]c_int{ Key.UP, Key.DOWN, Key.LEFT, Key.RIGHT });
        pub const NumberKeys = KeyGroup(&[_]c_int{ Key.N0, Key.N1, Key.N2, Key.N3, Key.N4, Key.N5, Key.N6, Key.N7, Key.N8, Key.N9 });
        pub const FunctionKeys = KeyGroup(&[_]c_int{ Key.F1, Key.F2, Key.F3, Key.F4, Key.F5, Key.F6, Key.F7, Key.F8, Key.F9, Key.F10, Key.F11, Key.F12 });
    };
};
