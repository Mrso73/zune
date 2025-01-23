const std = @import("std");
const c = @import("../c.zig"); // Import c libraries like GLFW and GLAD

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("GLFW Error: {d} {s}\n", .{ err, description });
}

pub const WindowConfig = struct {
    title: [:0]const u8,
    width: u32 = 800,
    height: u32 = 600,
    vsync: bool = true,
    resizable: bool = true,
    decorated: bool = true,
    fullscreen: bool = false,
    msaa_samples: u32 = 0,
    cursor_visible: bool = true,
    transparent: bool = false,
    floating: bool = false,
};

pub const Window = struct {
    handle: *c.GLFWwindow,
    allocator: std.mem.Allocator,
    config: WindowConfig,
    framebuffer_size: struct { width: u32, height: u32 },

    // Window state
    is_minimized: bool,
    is_focused: bool,
    cursor_pos: struct { x: f64, y: f64 },

    // Errors that can occur during window operations
    pub const Error = error{
        GLFWInitFailed,
        WindowCreationFailed,
        GLADInitFailed,
        GLContextCreationFailed,
    };

    // Initialize GLFW and create window
    pub fn init(allocator: std.mem.Allocator, config: WindowConfig) !*Window {

        // Initialize GLFW
        if (c.glfwInit() != c.GLFW_TRUE) {
            std.debug.print("could not init glfw\n", .{});
            return Error.GLFWInitFailed;
        }
        errdefer c.glfwTerminate();

        _ = c.glfwSetErrorCallback(errorCallback);

        // Set window hints
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
        c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
        c.glfwWindowHint(c.GLFW_RESIZABLE, if (config.resizable) c.GLFW_TRUE else c.GLFW_FALSE); // Resizability
        c.glfwWindowHint(c.GLFW_DECORATED, if (config.decorated) c.GLFW_TRUE else c.GLFW_FALSE); // Decoration
        c.glfwWindowHint(c.GLFW_TRANSPARENT_FRAMEBUFFER, if (config.transparent) c.GLFW_TRUE else c.GLFW_FALSE); //Transparency
        c.glfwWindowHint(c.GLFW_FLOATING, if (config.floating) c.GLFW_TRUE else c.GLFW_FALSE); //floating
        c.glfwWindowHint(c.GLFW_SAMPLES, @intCast(config.msaa_samples));
        c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GLFW_TRUE);

        // Create the window
        const monitor = if (config.fullscreen) c.glfwGetPrimaryMonitor() else null;
        const window = c.glfwCreateWindow(
            @intCast(config.width),
            @intCast(config.height),
            config.title,
            monitor,
            null,
        ) orelse return Error.WindowCreationFailed;
        errdefer c.glfwDestroyWindow(window);

        // Make OpenGL context current
        c.glfwMakeContextCurrent(window);

        // Initialize GLAD
        if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == 0) {
            return Error.GLADInitFailed;
        }

        // Setup vsync
        c.glfwSwapInterval(if (config.vsync) 1 else 0);

        // Create Window struct
        const self = try allocator.create(Window);
        self.* = .{
            .handle = window,
            .allocator = allocator,
            .config = config,
            .framebuffer_size = .{
                .width = config.width,
                .height = config.height,
            },
            .is_minimized = false,
            .is_focused = false,
            .cursor_pos = .{ .x = 0, .y = 0 },
        };

        // Store self pointer in GLFW user pointer
        c.glfwSetWindowUserPointer(window, self);

        return self;
    }

    // Window state queries --------------------------------------------------------
    pub fn shouldClose(self: *const Window) bool {
        return c.glfwWindowShouldClose(self.handle) == c.GLFW_TRUE;
    }

    pub fn isMinimized(self: *const Window) bool {
        return self.is_minimized;
    }

    pub fn isFocused(self: *const Window) bool {
        return self.is_focused;
    }

    pub fn getCursorPos(self: *const Window) struct { x: f64, y: f64 } {
        return self.cursor_pos;
    }

    pub fn getSize(self: *const Window) struct { width: u32, height: u32 } {
        var width: c_int = undefined;
        var height: c_int = undefined;
        c.glfwGetWindowSize(self.handle, &width, &height);
        return .{
            // Use @intCast to safely convert from c_int to u32, with the assumption that window sizes are positive
            .width = if (width < 0) 0 else @intCast(width),
            .height = if (height < 0) 0 else @intCast(height),
        };
    }

    // Window control
    pub fn setCursorVisible(self: *Window, visible: bool) void {
        c.glfwSetInputMode(
            self.handle,
            c.GLFW_CURSOR,
            if (visible) c.GLFW_CURSOR_NORMAL else c.GLFW_CURSOR_DISABLED,
        );
    }

    pub fn setMousePos(self: *Window, x: f64, y: f64) void {
        c.glfwSetCursorPos(self.handle, x, y);
        self.cursor_pos = .{ .x = x, .y = y };
    }

    pub fn centerWindow(self: *Window) void {
        const monitor = c.glfwGetPrimaryMonitor();
        const video_mode = c.glfwGetVideoMode(monitor);

        if (video_mode != null) {
            const size = self.getSize();
            // Dereference the video_mode pointer and access fields
            const monitor_width = video_mode.*.width;
            const monitor_height = video_mode.*.height;

            // Convert size.width and size.height to c_int for calculation
            const window_width = @as(c_int, @intCast(size.width));
            const window_height = @as(c_int, @intCast(size.height));

            const x = @divTrunc(monitor_width - window_width, @as(c_int, 2));
            const y = @divTrunc(monitor_height - window_height, @as(c_int, 2));

            c.glfwSetWindowPos(self.handle, x, y);
        }
    }

    pub fn minimize(self: *Window) void {
        c.glfwIconifyWindow(self.handle);
    }

    pub fn maximize(self: *Window) void {
        c.glfwMaximizeWindow(self.handle);
    }

    pub fn restore(self: *Window) void {
        c.glfwRestoreWindow(self.handle);
    }

    pub fn setTitle(self: *Window, title: [:0]const u8) void {
        c.glfwSetWindowTitle(self.handle, title);
    }

    pub fn setVsync(self: *Window, enabled: bool) void {
        _ = self; // temp
        c.glfwSwapInterval(if (enabled) 1 else 0);
    }

    pub fn swapBuffers(self: *Window) void {
        c.glfwSwapBuffers(self.handle);
    }

    pub fn pollEvents(self: *Window) void {
        _ = self;
        c.glfwPollEvents();
    }

    // Cleanup
    pub fn deinit(self: *Window) void {
        c.glfwDestroyWindow(self.handle);
        c.glfwTerminate();
        self.allocator.destroy(self);
    }
};
