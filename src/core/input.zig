const std = @import("std");
const c = @import("../bindings/c.zig");

const Window = @import("window.zig").Window;
const CallbackContext = @import("window.zig").CallbackContext;

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


pub const InputState = enum(u2) {
    up = 0, // Key is not pressed and wasn't recently released
    pressed = 1, // Key was just pressed this frame
    held = 2, // Key continues to be held down
    released = 3, // Key was just released this frame
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

// Constants for array sizes
const KEY_ARRAY_SIZE = 512; // GLFW_KEY_LAST + 1 (348 in standard GLFW)
const MOUSE_BUTTON_ARRAY_SIZE = 8; // GLFW_MOUSE_BUTTON_LAST + 1 (8 in standard GLFW)
const RECENT_INPUT_FRAMES = 10; // Number of frames to track for "recent" input

// Constant for initial frame value (ensures wasJustPressed/Released returns false initially)
const FRAME_INIT_VALUE = std.math.maxInt(u32);


// Input system main struct
pub const Input = struct {
    allocator: std.mem.Allocator,
    window: ?*Window,

    // State tracking
    current_keys: [KEY_ARRAY_SIZE]InputState = [_]InputState{.up} ** KEY_ARRAY_SIZE,
    previous_keys: [KEY_ARRAY_SIZE]InputState = [_]InputState{.up} ** KEY_ARRAY_SIZE,
    current_mouse: [MOUSE_BUTTON_ARRAY_SIZE]InputState = [_]InputState{.up} ** MOUSE_BUTTON_ARRAY_SIZE,
    previous_mouse: [MOUSE_BUTTON_ARRAY_SIZE]InputState = [_]InputState{.up} ** MOUSE_BUTTON_ARRAY_SIZE,

    // Event queue for raw input events
    event_queue: std.ArrayList(InputEvent),

    // Recent input frame tracking
    frame_count: u32 = 0,
    key_press_frames: [KEY_ARRAY_SIZE]u32 = [_]u32{FRAME_INIT_VALUE} ** KEY_ARRAY_SIZE,
    key_release_frames: [KEY_ARRAY_SIZE]u32 = [_]u32{FRAME_INIT_VALUE} ** KEY_ARRAY_SIZE,
    mouse_press_frames: [MOUSE_BUTTON_ARRAY_SIZE]u32 = [_]u32{FRAME_INIT_VALUE} ** MOUSE_BUTTON_ARRAY_SIZE,
    mouse_release_frames: [MOUSE_BUTTON_ARRAY_SIZE]u32 = [_]u32{FRAME_INIT_VALUE} ** MOUSE_BUTTON_ARRAY_SIZE,

    // Mouse position tracking
    mouse_pos: MousePosition = .{ .x = 0, .y = 0 },
    mouse_delta: MousePosition = .{ .x = 0, .y = 0 },
    previous_mouse_pos: MousePosition = .{ .x = 0, .y = 0 },


    // ============================================================
    // Public API: Creation Functions
    // ============================================================


    pub fn create(allocator: std.mem.Allocator, window: ?*Window) !*Input {
        const self = try allocator.create(Input);

        self.* = .{
            .allocator = allocator,
            .window = window,
            .event_queue = std.ArrayList(InputEvent).init(allocator),
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
        // Increment frame counter
        self.frame_count += 1;

        // Save previous state
        std.mem.copyForwards(InputState, &self.previous_keys, &self.current_keys);
        std.mem.copyForwards(InputState, &self.previous_mouse, &self.current_mouse);

        // Update states: transition all pressed -> held and released -> up
        for (0..KEY_ARRAY_SIZE) |i| {
            switch (self.current_keys[i]) {
                .pressed => self.current_keys[i] = .held,
                .released => self.current_keys[i] = .up,
                else => {}, // Leave held and up as they are
            }
        }

        for (0..MOUSE_BUTTON_ARRAY_SIZE) |i| {
            switch (self.current_mouse[i]) {
                .pressed => self.current_mouse[i] = .held,
                .released => self.current_mouse[i] = .up,
                else => {}, // Leave held and up as they are
            }
        }

        // Process all queued events
        for (self.event_queue.items) |event| {
            switch (event.event_type) {
                .key_press => {
                    const key_index = @as(usize, @intCast(event.key_or_button));
                    if (key_index < KEY_ARRAY_SIZE) {
                        self.current_keys[key_index] = .pressed;
                        self.key_press_frames[key_index] = self.frame_count;
                    }
                },
                .key_release => {
                    const key_index = @as(usize, @intCast(event.key_or_button));
                    if (key_index < KEY_ARRAY_SIZE) {
                        self.current_keys[key_index] = .released;
                        self.key_release_frames[key_index] = self.frame_count;
                    }
                },
                .mouse_press => {
                    const button_index = @as(usize, @intCast(event.key_or_button));
                    if (button_index < MOUSE_BUTTON_ARRAY_SIZE) {
                        self.current_mouse[button_index] = .pressed;
                        self.mouse_press_frames[button_index] = self.frame_count;
                    }
                },
                .mouse_release => {
                    const button_index = @as(usize, @intCast(event.key_or_button));
                    if (button_index < MOUSE_BUTTON_ARRAY_SIZE) {
                        self.current_mouse[button_index] = .released;
                        self.mouse_release_frames[button_index] = self.frame_count;
                    }
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
        const key_index = @as(usize, @intCast(@intFromEnum(key)));
        if (key_index >= KEY_ARRAY_SIZE) return false;
        return self.current_keys[key_index] == .pressed;
    }


    pub fn isKeyHeld(self: *const Input, key: KeyCode) bool {
        const key_index = @as(usize, @intCast(@intFromEnum(key)));
        if (key_index >= KEY_ARRAY_SIZE) return false;
        return self.current_keys[key_index] == .held or self.current_keys[key_index] == .pressed;
    }


    pub fn isKeyReleased(self: *const Input, key: KeyCode) bool {
        const key_index = @as(usize, @intCast(@intFromEnum(key)));
        if (key_index >= KEY_ARRAY_SIZE) return false;
        return self.current_keys[key_index] == .released;
    }


    pub fn isKeyUp(self: *const Input, key: KeyCode) bool {
        const key_index = @as(usize, @intCast(@intFromEnum(key)));
        if (key_index >= KEY_ARRAY_SIZE) return true; // Consider out-of-range as up
        return self.current_keys[key_index] == .up;
    }


    /// Check if key was pressed during the last x frames
    pub fn wasKeyJustPressed(self: *const Input, key: KeyCode, frame_threshold: u32) bool {
        const key_index = @as(usize, @intCast(@intFromEnum(key)));
        if (key_index >= KEY_ARRAY_SIZE) return false;  

        // Check if this key has ever been pressed
        if (self.key_press_frames[key_index] == FRAME_INIT_VALUE) return false;
        
        // Check if the key was pressed within the threshold
        return (self.frame_count - self.key_press_frames[key_index]) <= frame_threshold;
    }


    /// Check if key was released during the last x frames
    pub fn wasKeyJustReleased(self: *const Input, key: KeyCode, frame_threshold: u32) bool {
        const key_index = @as(usize, @intCast(@intFromEnum(key)));
        if (key_index >= KEY_ARRAY_SIZE) return false;

        // Check if this key has ever been released
        if (self.key_release_frames[key_index] == FRAME_INIT_VALUE) return false;

        // Check if the key was released within the threshold
        return (self.frame_count - self.key_release_frames[key_index]) <= frame_threshold;
    }


    // Mouse state checking
    pub fn isMouseButtonPressed(self: *const Input, button: MouseButton) bool {
        const button_index = @as(usize, @intCast(@intFromEnum(button)));
        if (button_index >= MOUSE_BUTTON_ARRAY_SIZE) return false;
        return self.current_mouse[button_index] == .pressed;
    }


    pub fn isMouseButtonHeld(self: *const Input, button: MouseButton) bool {
        const button_index = @as(usize, @intCast(@intFromEnum(button)));
        if (button_index >= MOUSE_BUTTON_ARRAY_SIZE) return false;
        return self.current_mouse[button_index] == .held or self.current_mouse[button_index] == .pressed;
    }


    pub fn isMouseButtonReleased(self: *const Input, button: MouseButton) bool {
        const button_index = @as(usize, @intCast(@intFromEnum(button)));
        if (button_index >= MOUSE_BUTTON_ARRAY_SIZE) return false;
        return self.current_mouse[button_index] == .released;
    }


    pub fn isMouseButtonUp(self: *const Input, button: MouseButton) bool {
        const button_index = @as(usize, @intCast(@intFromEnum(button)));
        if (button_index >= MOUSE_BUTTON_ARRAY_SIZE) return true; // Consider out-of-range as up
        return self.current_mouse[button_index] == .up;
    }


    /// Check if button was pressed during the last x frames
    pub fn wasMouseButtonJustPressed(self: *const Input, button: MouseButton, frame_threshold: u32) bool {
        const button_index = @as(usize, @intCast(@intFromEnum(button)));
        if (button_index >= MOUSE_BUTTON_ARRAY_SIZE) return false;

        // Check if this button has ever been pressed
        if (self.mouse_press_frames[button_index] == FRAME_INIT_VALUE) return false;
        
        // Check if the button was pressed within the threshold
        return (self.frame_count - self.mouse_press_frames[button_index]) <= frame_threshold;
    }


    /// Check if button was released during the last x frames
    pub fn wasMouseButtonJustReleased(self: *const Input, button: MouseButton, frame_threshold: u32) bool {
        const button_index = @as(usize, @intCast(@intFromEnum(button)));
        if (button_index >= MOUSE_BUTTON_ARRAY_SIZE) return false;

        // Check if this button has ever been released
        if (self.mouse_release_frames[button_index] == FRAME_INIT_VALUE) return false;
        
        // Check if the button was released within the threshold
        return (self.frame_count - self.mouse_release_frames[button_index]) <= frame_threshold;
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
        self.event_queue.deinit();
        self.allocator.destroy(self);
    }


    // ============================================================
    // Private Functions: Callbacks 
    // ============================================================

    fn setupCallbacks(self: *Input) !void {
        if (self.window) |window| {
            const window_handle = window.handle;

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

        const context_ptr = c.glfwGetWindowUserPointer(window);
        if (context_ptr == null) return;

        // Determine if the user pointer is a Window or an Input
        const context = @as(*CallbackContext, @ptrCast(@alignCast(context_ptr)));
        if (context.input) |input| {
            // Continue with event handling using input...
            const event = switch (action) {
                c.GLFW_PRESS => InputEvent{
                    .event_type = .key_press,
                    .key_or_button = key,
                },
                c.GLFW_RELEASE => InputEvent{
                    .event_type = .key_release,
                    .key_or_button = key,
                },
                else => return, // Ignore repeats
            };

            // Add to event queue
            input.event_queue.append(event) catch return;
        }
    }


    fn mouseButtonCallback(window: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
        _ = mods;

        const context_ptr = c.glfwGetWindowUserPointer(window);
        if (context_ptr == null) return;

        // Determine if the user pointer is a Window or an Input
        const context = @as(*CallbackContext, @ptrCast(@alignCast(context_ptr)));
        if (context.input) |input| {
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

            // Add to event queue
            input.event_queue.append(event) catch return;
        }
    }


    fn cursorPosCallback(window: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
        const context_ptr = c.glfwGetWindowUserPointer(window);
        if (context_ptr == null) return;

        // Determine if the user pointer is a Window or an Input
        const context = @as(*CallbackContext, @ptrCast(@alignCast(context_ptr)));
        if (context.input) |input| {
            // Queue cursor movement event
            const event = InputEvent{
                .event_type = .cursor_move,
                .key_or_button = 0, // Not used for cursor
                .cursor_x = xpos,
                .cursor_y = ypos,
            };  

            // Add to event queue
            input.event_queue.append(event) catch return;
        }
    }
};
