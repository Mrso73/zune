const std = @import("std");
const c = @import("../bindings/c.zig");
const Window = @import("window.zig").Window;

pub const MousePosition = struct {
    x: f64,
    y: f64,
};

pub const MouseButton = enum(c_int) {
    left = c.GLFW_MOUSE_BUTTON_LEFT,
    right = c.GLFW_MOUSE_BUTTON_RIGHT,
    middle = c.GLFW_MOUSE_BUTTON_MIDDLE,

    pub fn fromGLFW(button: c_int) MouseButton {
        return @enumFromInt(button);
    }
};

// Core input types
pub const KeyCode = enum(c_int) {
    // Printable keys
    KEY_SPACE = c.GLFW_KEY_SPACE,
    KEY_APOSTROPHE = c.GLFW_KEY_APOSTROPHE,
    KEY_COMMA = c.GLFW_KEY_COMMA,
    KEY_MINUS = c.GLFW_KEY_MINUS,
    KEY_PERIOD = c.GLFW_KEY_PERIOD,
    KEY_SLASH = c.GLFW_KEY_SLASH,
    KEY_0 = c.GLFW_KEY_0,
    KEY_1 = c.GLFW_KEY_1,
    KEY_2 = c.GLFW_KEY_2,
    KEY_3 = c.GLFW_KEY_3,
    KEY_4 = c.GLFW_KEY_4,
    KEY_5 = c.GLFW_KEY_5,
    KEY_6 = c.GLFW_KEY_6,
    KEY_7 = c.GLFW_KEY_7,
    KEY_8 = c.GLFW_KEY_8,
    KEY_9 = c.GLFW_KEY_9,
    KEY_SEMICOLON = c.GLFW_KEY_SEMICOLON,
    KEY_EQUAL = c.GLFW_KEY_EQUAL,

    // Alphabet
    KEY_A = c.GLFW_KEY_A,
    KEY_B = c.GLFW_KEY_B,
    KEY_C = c.GLFW_KEY_C,
    KEY_D = c.GLFW_KEY_D,
    KEY_E = c.GLFW_KEY_E,
    KEY_F = c.GLFW_KEY_F,
    KEY_G = c.GLFW_KEY_G,
    KEY_H = c.GLFW_KEY_H,
    KEY_I = c.GLFW_KEY_I,
    KEY_J = c.GLFW_KEY_J,
    KEY_K = c.GLFW_KEY_K,
    KEY_L = c.GLFW_KEY_L,
    KEY_M = c.GLFW_KEY_M,
    KEY_N = c.GLFW_KEY_N,
    KEY_O = c.GLFW_KEY_O,
    KEY_P = c.GLFW_KEY_P,
    KEY_Q = c.GLFW_KEY_Q,
    KEY_R = c.GLFW_KEY_R,
    KEY_S = c.GLFW_KEY_S,
    KEY_T = c.GLFW_KEY_T,
    KEY_U = c.GLFW_KEY_U,
    KEY_V = c.GLFW_KEY_V,
    KEY_W = c.GLFW_KEY_W,
    KEY_X = c.GLFW_KEY_X,
    KEY_Y = c.GLFW_KEY_Y,
    KEY_Z = c.GLFW_KEY_Z,

    // Function keys
    KEY_F1 = c.GLFW_KEY_F1,
    KEY_F2 = c.GLFW_KEY_F2,
    KEY_F3 = c.GLFW_KEY_F3,
    KEY_F4 = c.GLFW_KEY_F4,
    KEY_F5 = c.GLFW_KEY_F5,
    KEY_F6 = c.GLFW_KEY_F6,
    KEY_F7 = c.GLFW_KEY_F7,
    KEY_F8 = c.GLFW_KEY_F8,
    KEY_F9 = c.GLFW_KEY_F9,
    KEY_F10 = c.GLFW_KEY_F10,
    KEY_F11 = c.GLFW_KEY_F11,
    KEY_F12 = c.GLFW_KEY_F12,

    // Navigation keys
    KEY_ESCAPE = c.GLFW_KEY_ESCAPE,
    KEY_ENTER = c.GLFW_KEY_ENTER,
    KEY_TAB = c.GLFW_KEY_TAB,
    KEY_BACKSPACE = c.GLFW_KEY_BACKSPACE,
    KEY_INSERT = c.GLFW_KEY_INSERT,
    KEY_DELETE = c.GLFW_KEY_DELETE,
    KEY_RIGHT = c.GLFW_KEY_RIGHT,
    KEY_LEFT = c.GLFW_KEY_LEFT,
    KEY_DOWN = c.GLFW_KEY_DOWN,
    KEY_UP = c.GLFW_KEY_UP,
    KEY_PAGE_UP = c.GLFW_KEY_PAGE_UP,
    KEY_PAGE_DOWN = c.GLFW_KEY_PAGE_DOWN,
    KEY_HOME = c.GLFW_KEY_HOME,
    KEY_END = c.GLFW_KEY_END,

    // Modifier keys
    KEY_CAPS_LOCK = c.GLFW_KEY_CAPS_LOCK,
    KEY_SCROLL_LOCK = c.GLFW_KEY_SCROLL_LOCK,
    KEY_NUM_LOCK = c.GLFW_KEY_NUM_LOCK,
    KEY_PRINT_SCREEN = c.GLFW_KEY_PRINT_SCREEN,
    KEY_PAUSE = c.GLFW_KEY_PAUSE,
    KEY_LEFT_SHIFT = c.GLFW_KEY_LEFT_SHIFT,
    KEY_LEFT_CONTROL = c.GLFW_KEY_LEFT_CONTROL,
    KEY_LEFT_ALT = c.GLFW_KEY_LEFT_ALT,
    KEY_LEFT_SUPER = c.GLFW_KEY_LEFT_SUPER,
    KEY_RIGHT_SHIFT = c.GLFW_KEY_RIGHT_SHIFT,
    KEY_RIGHT_CONTROL = c.GLFW_KEY_RIGHT_CONTROL,
    KEY_RIGHT_ALT = c.GLFW_KEY_RIGHT_ALT,
    KEY_RIGHT_SUPER = c.GLFW_KEY_RIGHT_SUPER,
    KEY_MENU = c.GLFW_KEY_MENU,

    // Add a safety case for unknown keys
    KEY_UNKNOWN = c.GLFW_KEY_UNKNOWN,

    pub fn fromGLFW(key: c_int) KeyCode {
        return std.meta.intToEnum(KeyCode, key) catch .KEY_UNKNOWN;
    }
};


pub const InputState = enum {
    up, // Key is not pressed and wasn't recently released
    pressed, // Key was just pressed this frame
    held, // Key continues to be held down
    released, // Key was just released this frame
};


/// Event type to track raw input events from GLFW
const InputEvent = struct {
    event_type: enum {
        key_press,
        key_release,
        mouse_press,
        mouse_release,
        cursor_move,
    },
    key_or_button: c_int,
    cursor_x: f64 = 0,
    cursor_y: f64 = 0,
};


// Struct to track recent input events with timeout
pub const RecentInputTracker = struct {
    frame_count: u32,
    last_pressed_frame: std.AutoHashMap(i32, u32),
    last_released_frame: std.AutoHashMap(i32, u32),

    pub fn init(allocator: std.mem.Allocator) RecentInputTracker {
        return .{
            .frame_count = 0,
            .last_pressed_frame = std.AutoHashMap(i32, u32).init(allocator),
            .last_released_frame = std.AutoHashMap(i32, u32).init(allocator),
        };
    }

    pub fn deinit(self: *RecentInputTracker) void {
        self.last_pressed_frame.deinit();
        self.last_released_frame.deinit();
    }

    pub fn incrementFrame(self: *RecentInputTracker) void {
        self.frame_count += 1;
    }

    pub fn recordPress(self: *RecentInputTracker, key_or_button: i32) !void {
        try self.last_pressed_frame.put(key_or_button, self.frame_count);
    }

    pub fn recordRelease(self: *RecentInputTracker, key_or_button: i32) !void {
        try self.last_released_frame.put(key_or_button, self.frame_count);
    }

    pub fn wasRecentlyPressed(self: *const RecentInputTracker, key_or_button: i32, frame_threshold: u32) bool {
        if (self.last_pressed_frame.get(key_or_button)) |last_frame| {
            return (self.frame_count - last_frame) <= frame_threshold;
        }
        return false;
    }

    pub fn wasRecentlyReleased(self: *const RecentInputTracker, key_or_button: i32, frame_threshold: u32) bool {
        if (self.last_released_frame.get(key_or_button)) |last_frame| {
            return (self.frame_count - last_frame) <= frame_threshold;
        }
        return false;
    }
};


// Input system main struct
pub const Input = struct {
    allocator: std.mem.Allocator,
    window: ?*Window,

    // State tracking
    current_keys: std.AutoHashMap(KeyCode, InputState),
    previous_keys: std.AutoHashMap(KeyCode, InputState),
    current_mouse: std.AutoHashMap(MouseButton, InputState),
    previous_mouse: std.AutoHashMap(MouseButton, InputState),

    // Event queue for raw input events
    event_queue: std.ArrayList(InputEvent),

    // Physical key/button state maps (directly from GLFW)
    key_physical_state: std.AutoHashMap(c_int, bool),
    mouse_physical_state: std.AutoHashMap(c_int, bool),

    // Recent input tracking
    keyboard_tracker: RecentInputTracker,
    mouse_tracker: RecentInputTracker,

    // Mouse position tracking
    mouse_pos: MousePosition,
    mouse_delta: MousePosition,
    previous_mouse_pos: MousePosition,


    // ============================================================
    // Public API: Creation Functions
    // ============================================================


    pub fn create(allocator: std.mem.Allocator, window: ?*Window) !*Input {
        const self = try allocator.create(Input);

        self.* = .{
            .allocator = allocator,
            .window = window,

            .current_keys = std.AutoHashMap(KeyCode, InputState).init(allocator),
            .previous_keys = std.AutoHashMap(KeyCode, InputState).init(allocator),
            .current_mouse = std.AutoHashMap(MouseButton, InputState).init(allocator),
            .previous_mouse = std.AutoHashMap(MouseButton, InputState).init(allocator),

            .event_queue = std.ArrayList(InputEvent).init(allocator),
            .key_physical_state = std.AutoHashMap(c_int, bool).init(allocator),
            .mouse_physical_state = std.AutoHashMap(c_int, bool).init(allocator),

            .keyboard_tracker = RecentInputTracker.init(allocator),
            .mouse_tracker = RecentInputTracker.init(allocator),

            .mouse_pos = .{ .x = 0, .y = 0 },
            .mouse_delta = .{ .x = 0, .y = 0 },
            .previous_mouse_pos = .{ .x = 0, .y = 0 },
        };

        // Only set up callbacks if a window is provided
        if (window != null) {
            try self.setupCallbacks();
        }

        return self;
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    // Add function to connect input to a window
    pub fn attachToWindow(self: *Input, window: *Window) !void {
        self.window = window;
        try self.setupCallbacks();
    }


    /// Process all input events and update input state
    pub fn update(self: *Input) !void {
        // Increment frame counters
        self.keyboard_tracker.incrementFrame();
        self.mouse_tracker.incrementFrame();

        // Save previous state
        self.previous_keys.clearRetainingCapacity();
        self.previous_mouse.clearRetainingCapacity();

        var key_it = self.current_keys.iterator();
        while (key_it.next()) |entry| {
            try self.previous_keys.put(entry.key_ptr.*, entry.value_ptr.*);
        }

        var mouse_it = self.current_mouse.iterator();
        while (mouse_it.next()) |entry| {
            try self.previous_mouse.put(entry.key_ptr.*, entry.value_ptr.*);
        }

        // transition all pressed -> held and released -> up
        var keys_to_update = std.ArrayList(struct { key: KeyCode, new_state: InputState }).init(self.allocator);
        defer keys_to_update.deinit();

        key_it = self.current_keys.iterator();
        while (key_it.next()) |entry| {
            switch (entry.value_ptr.*) {
                .pressed => try keys_to_update.append(.{ .key = entry.key_ptr.*, .new_state = .held }),
                .released => try keys_to_update.append(.{ .key = entry.key_ptr.*, .new_state = .up }),
                else => {}, // Leave held and up as they are
            }
        }

        for (keys_to_update.items) |update_item| {
            try self.current_keys.put(update_item.key, update_item.new_state);
        }

        // Similar for mouse
        var buttons_to_update = std.ArrayList(struct { button: MouseButton, new_state: InputState }).init(self.allocator);
        defer buttons_to_update.deinit();

        mouse_it = self.current_mouse.iterator();
        while (mouse_it.next()) |entry| {
            switch (entry.value_ptr.*) {
                .pressed => try buttons_to_update.append(.{ .button = entry.key_ptr.*, .new_state = .held }),
                .released => try buttons_to_update.append(.{ .button = entry.key_ptr.*, .new_state = .up }),
                else => {}, // Leave held and up as they are
            }
        }

        for (buttons_to_update.items) |update_item| {
            try self.current_mouse.put(update_item.button, update_item.new_state);
        }

        // Process all queued events
        for (self.event_queue.items) |event| {
            switch (event.event_type) {
                .key_press => {
                    const key_code = KeyCode.fromGLFW(event.key_or_button);
                    try self.current_keys.put(key_code, .pressed);
                    try self.keyboard_tracker.recordPress(event.key_or_button);
                },
                .key_release => {
                    const key_code = KeyCode.fromGLFW(event.key_or_button);
                    try self.current_keys.put(key_code, .released);
                    try self.keyboard_tracker.recordRelease(event.key_or_button);
                },
                .mouse_press => {
                    const mouse_button = MouseButton.fromGLFW(event.key_or_button);
                    try self.current_mouse.put(mouse_button, .pressed);
                    try self.mouse_tracker.recordPress(event.key_or_button);
                },
                .mouse_release => {
                    const mouse_button = MouseButton.fromGLFW(event.key_or_button);
                    try self.current_mouse.put(mouse_button, .released);
                    try self.mouse_tracker.recordRelease(event.key_or_button);
                },
                .cursor_move => {
                    self.previous_mouse_pos = self.mouse_pos;
                    self.mouse_pos = .{ .x = event.cursor_x, .y = event.cursor_y };
                    self.mouse_delta = .{
                        .x = self.mouse_pos.x - self.previous_mouse_pos.x,
                        .y = self.mouse_pos.y - self.previous_mouse_pos.y,
                    };
                },
            }
        }

        // Clear event queue for next frame
        self.event_queue.clearRetainingCapacity();
    }


    // Key state checking
    pub fn isKeyPressed(self: *const Input, key: KeyCode) bool {
        return if (self.current_keys.get(key)) |state|
            state == .pressed
        else
            false;
    }


    pub fn isKeyHeld(self: *const Input, key: KeyCode) bool {
        return if (self.current_keys.get(key)) |state|
            state == .held or state == .pressed
        else
            false;
    }


    pub fn isKeyReleased(self: *const Input, key: KeyCode) bool {
        return if (self.current_keys.get(key)) |state|
            state == .released
        else
            false;
    }


    pub fn isKeyUp(self: *const Input, key: KeyCode) bool {
        return if (self.current_keys.get(key)) |state|
            state == .up
        else
            true; // If not found, consider it Up
    }


    /// Check if key was pressed during the last x frames
    pub fn wasKeyJustPressed(self: *const Input, key: KeyCode, frame_threshold: u32) bool {
        // Use the raw key value (c_int) directly
        const key_value: c_int = @intFromEnum(key);
        return self.keyboard_tracker.wasRecentlyPressed(key_value, frame_threshold);
    }


    /// Check if key was released during the last x frames
    pub fn wasKeyJustReleased(self: *const Input, key: KeyCode, frame_threshold: u32) bool {
        // Use the raw key value (c_int) directly
        const key_value: c_int = @intFromEnum(key);
        return self.keyboard_tracker.wasRecentlyReleased(key_value, frame_threshold);
    }


    // Mouse state checking
    pub fn isMouseButtonPressed(self: *const Input, button: MouseButton) bool {
        return if (self.current_mouse.get(button)) |state|
            state == .pressed
        else
            false;
    }


    pub fn isMouseButtonHeld(self: *const Input, button: MouseButton) bool {
        return if (self.current_mouse.get(button)) |state|
            state == .held or state == .pressed
        else
            false;
    }


    pub fn isMouseButtonReleased(self: *const Input, button: MouseButton) bool {
        return if (self.current_mouse.get(button)) |state|
            state == .released
        else
            false;
    }


    pub fn isMouseButtonUp(self: *const Input, button: MouseButton) bool {
        return if (self.current_mouse.get(button)) |state| 
            state == .up 
        else 
            true; // If not found, consider it Up
    }


    /// Check if button was pressed during the last x frames
    pub fn wasMouseButtonJustPressed(self: *const Input, button: MouseButton, frame_threshold: u32) bool {
        // Use the raw button value (c_int) directly
        const button_value: c_int = @intFromEnum(button);
        return self.mouse_tracker.wasRecentlyPressed(button_value, frame_threshold);
    }


    /// Check if key was released during the last x frames
    pub fn wasMouseButtonJustReleased(self: *const Input, button: MouseButton, frame_threshold: u32) bool {
        // Use the raw button value (c_int) directly
        const button_value: c_int = @intFromEnum(button);
        return self.mouse_tracker.wasRecentlyReleased(button_value, frame_threshold);
    }


    pub fn getMousePosition(self: *const Input) MousePosition {
        return self.mouse_pos;
    }


    pub fn getMouseDelta(self: *const Input) MousePosition {
        return self.mouse_delta;
    }


    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    pub fn release(self: *Input) void {
        self.current_keys.deinit();
        self.previous_keys.deinit();
        self.current_mouse.deinit();
        self.previous_mouse.deinit();
        self.event_queue.deinit();
        self.key_physical_state.deinit();
        self.mouse_physical_state.deinit();
        self.keyboard_tracker.deinit();
        self.mouse_tracker.deinit();
        self.allocator.destroy(self);
    }


    // ============================================================
    // Private Functions: Callbacks 
    // ============================================================

    fn setupCallbacks(self: *Input) !void {
        if (self.window) |window| {
            const window_handle = window.handle;

            // Store self pointer in window user pointer for callbacks
            //c.glfwSetWindowUserPointer(window_handle, self);

            // Store self pointer in window callback data
            window.setCallbackData(self);

            // Set up key callback
            _ = c.glfwSetKeyCallback(window_handle, keyCallback);
            _ = c.glfwSetMouseButtonCallback(window_handle, mouseButtonCallback);
            _ = c.glfwSetCursorPosCallback(window_handle, cursorPosCallback);
        } else {
            return error.NoWindowAttached;
        }
    }


    // Callback implementations
    fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
        _ = scancode;
        _ = mods;

        const user_ptr = c.glfwGetWindowUserPointer(window);
        if (user_ptr == null) return;

        // Determine if the user pointer is a Window or an Input
        const self = @as(*Input, @ptrCast(@alignCast(user_ptr)));

        // Queue the event instead of immediately changing state
        const event = switch (action) {
            c.GLFW_PRESS => InputEvent{ 
                .event_type = .key_press,
                .key_or_button = key,
            },
            c.GLFW_RELEASE => InputEvent{
                .event_type = .key_release,
                .key_or_button = key,
            },
            else => return, // Ignore repeats as they're handled differently now
        };

        // Update physical key state map
        if (action == c.GLFW_PRESS) {
            self.key_physical_state.put(key, true) catch return;
        } else if (action == c.GLFW_RELEASE) {
            self.key_physical_state.put(key, false) catch return;
        }

        // Add to event queue
        self.event_queue.append(event) catch return;
    }


    fn mouseButtonCallback(window: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
        _ = mods;

        const user_ptr = c.glfwGetWindowUserPointer(window);
        if (user_ptr == null) return;

        // Determine if the user pointer is a Window or an Input
        const self = @as(*Input, @ptrCast(@alignCast(user_ptr)));

        // Queue the event instead of immediately changing state
        const event = switch (action) {
            c.GLFW_PRESS => InputEvent{
                .event_type = .mouse_press,
                .key_or_button = button,
            },
            c.GLFW_RELEASE => InputEvent{
                .event_type = .mouse_release,
                .key_or_button = button,
            },
            else => return,
        };

        // Update physical button state map
        if (action == c.GLFW_PRESS) {
            self.mouse_physical_state.put(button, true) catch return;
        } else if (action == c.GLFW_RELEASE) {
            self.mouse_physical_state.put(button, false) catch return;
        }

        // Add to event queue
        self.event_queue.append(event) catch return;
    }


    fn cursorPosCallback(window: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
        const user_ptr = c.glfwGetWindowUserPointer(window);
        if (user_ptr == null) return;

        // Determine if the user pointer is a Window or an Input
        const self = @as(*Input, @ptrCast(@alignCast(user_ptr)));

        // Queue cursor movement event
        const event = InputEvent{
            .event_type = .cursor_move,
            .key_or_button = 0, // Not used for cursor
            .cursor_x = xpos,
            .cursor_y = ypos,
        };

        self.event_queue.append(event) catch return;
    }
};
