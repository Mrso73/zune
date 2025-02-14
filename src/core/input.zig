const std = @import("std");
const c = @import("../bindings/c.zig");
const Window = @import("window.zig").Window;


pub const MousePosition = struct {
    x: f64,
    y: f64,
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

pub const MouseButton = enum(c_int) {
    left = c.GLFW_MOUSE_BUTTON_LEFT,
    right = c.GLFW_MOUSE_BUTTON_RIGHT,
    middle = c.GLFW_MOUSE_BUTTON_MIDDLE,
    
    pub fn fromGLFW(button: c_int) MouseButton {
        return @enumFromInt(button);
    }
};

pub const InputState = enum {
    released,
    pressed,
    held,
};

// Input system main struct
pub const Input = struct {
    allocator: std.mem.Allocator,
    window: *Window,
    
    // State tracking
    current_keys: std.AutoHashMap(KeyCode, InputState),
    previous_keys: std.AutoHashMap(KeyCode, InputState),
    current_mouse: std.AutoHashMap(MouseButton, InputState),
    previous_mouse: std.AutoHashMap(MouseButton, InputState),
    
    // Mouse position tracking
    mouse_pos: MousePosition,
    mouse_delta: MousePosition,
    previous_mouse_pos: MousePosition,
    

    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    pub fn create(allocator: std.mem.Allocator, window: *Window) !*Input {
        const input_ptr = try allocator.create(Input);
        
        input_ptr.* = .{
            .allocator = allocator,
            .window = window,
            .current_keys = std.AutoHashMap(KeyCode, InputState).init(allocator),
            .previous_keys = std.AutoHashMap(KeyCode, InputState).init(allocator),
            .current_mouse = std.AutoHashMap(MouseButton, InputState).init(allocator),
            .previous_mouse = std.AutoHashMap(MouseButton, InputState).init(allocator),
            .mouse_pos = .{ .x = 0, .y = 0 },
            .mouse_delta = .{ .x = 0, .y = 0 },
            .previous_mouse_pos = .{ .x = 0, .y = 0 },
        };
        
        try input_ptr.setupCallbacks();

        return input_ptr;
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================
    
    fn setupCallbacks(self: *Input) !void {
        const window_handle = self.window.handle;
        
        // Store self pointer in window user pointer for callbacks
        c.glfwSetWindowUserPointer(window_handle, self);
        
        // Set up key callback
        _ = c.glfwSetKeyCallback(window_handle, keyCallback);
        _ = c.glfwSetMouseButtonCallback(window_handle, mouseButtonCallback);
        _ = c.glfwSetCursorPosCallback(window_handle, cursorPosCallback);
    }
    
    // Callback implementations
    fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
        _ = scancode;
        _ = mods;
        
        const self = @as(*Input, @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window))));
        const key_code = KeyCode.fromGLFW(key);
        
        const state = switch (action) {
            c.GLFW_PRESS => InputState.pressed,
            c.GLFW_RELEASE => InputState.released,
            c.GLFW_REPEAT => InputState.held,
            else => return,
        };
        
        self.current_keys.put(key_code, state) catch return;
    }
    
    fn mouseButtonCallback(window: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
        _ = mods;
        
        const self = @as(*Input, @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window))));
        const mouse_button = MouseButton.fromGLFW(button);
        
        const state = switch (action) {
            c.GLFW_PRESS => InputState.pressed,
            c.GLFW_RELEASE => InputState.released,
            else => return,
        };
        
        self.current_mouse.put(mouse_button, state) catch return;
    }

    fn cursorPosCallback(window: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
        const self = @as(*Input, @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window))));
        
        self.previous_mouse_pos = self.mouse_pos;
        self.mouse_pos = .{ .x = xpos, .y = ypos };
        self.mouse_delta = .{
            .x = self.mouse_pos.x - self.previous_mouse_pos.x,
            .y = self.mouse_pos.y - self.previous_mouse_pos.y,
        };
    }
    

    pub fn update(self: *Input) !void {
        // Swap previous and current states
        std.mem.swap(
            std.AutoHashMap(KeyCode, InputState),
            &self.previous_keys,
            &self.current_keys,
        );
        std.mem.swap(
            std.AutoHashMap(MouseButton, InputState),
            &self.previous_mouse,
            &self.current_mouse,
        );
        
        // Update held states
        var key_it = self.current_keys.iterator();
        while (key_it.next()) |entry| {
            if (entry.value_ptr.* == .pressed) {
                entry.value_ptr.* = .held;
            }
        }
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
            state == .held
        else
            false;
    }
    
    pub fn isKeyReleased(self: *const Input, key: KeyCode) bool {
        return if (self.current_keys.get(key)) |state|
            state == .released
        else
            false;
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
            state == .held
        else
            false;
    }
    
    pub fn getMousePosition(self: *const Input) MousePosition {
        return self.mouse_pos;
    }
    
    pub fn getMouseDelta(self: *const Input) MousePosition {
        return self.mouse_delta;
    }
    
    pub fn release(self: *Input) void {
        self.current_keys.deinit();
        self.previous_keys.deinit();
        self.current_mouse.deinit();
        self.previous_mouse.deinit();
        self.allocator.destroy(self);
    }
};