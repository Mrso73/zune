// time.zig - Time management module
const std = @import("std");
const c = @import("../bindings/c.zig");

/// Configuration for the time system
pub const TimeConfig = struct {
    /// Target frames per second (0 for unlimited)
    target_fps: u32 = 60,
    /// Fixed timestep for physics/game logic updates (e.g., 1/60 for 60 updates per second)
    fixed_timestep: f32 = 1.0 / 60.0,
    /// Maximum allowed delta time to prevent spiral of death
    max_frame_time: f32 = 0.25,
    /// Time source to use (allows for easy testing and custom time sources)
    time_source: TimeSource = .GLFW,
};


/// Available time sources
pub const TimeSource = enum {
    GLFW,
    System,
    Custom,
};


/// Time system that tracks various timing metrics
pub const Time = struct {
    config: TimeConfig,

    /// Current frame's delta time
    delta: f32,
    /// Time accumulated for fixed timestep updates
    accumulated: f32,
    /// Last frame's timestamp
    last_frame: f64,
    /// Time since startup
    total: f64,

    /// FPS tracking
    fps: struct {
        current: f32,
        frames: u32,
        timer: f32,
    },

    /// Time source function pointer for flexibility
    getTime: *const fn () f64,


    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    /// Creates a new Time instance with the given configuration
    pub fn init(config: TimeConfig) Time {
        return .{
            .config = config,
            .delta = 0.0,
            .accumulated = 0.0,
            .last_frame = getTimeSource(config.time_source)(),
            .total = 0.0,
            .fps = .{
                .current = 0.0,
                .frames = 0,
                .timer = 0.0,
            },
            .getTime = getTimeSource(config.time_source),
        };
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    /// Updates timing information for the current frame
    pub fn update(self: *Time) void {
        const current_time = self.getTime();
        const frame_time = current_time - self.last_frame;

        // Update delta time with clamping to prevent spiral of death
        self.delta = @floatCast(@min(frame_time, @as(f64, self.config.max_frame_time)));
        self.last_frame = current_time;

        // Update accumulated time for fixed timestep
        self.accumulated += self.delta;

        // Update total time
        self.total = current_time;

        // Update FPS counter
        self.fps.frames += 1;
        self.fps.timer += self.delta;

        if (self.fps.timer >= 1.0) {
            self.fps.current = @as(f32, @floatFromInt(self.fps.frames)) / self.fps.timer;
            self.fps.frames = 0;
            self.fps.timer = 0;
        }

        // Frame limiting if target FPS is set
        if (self.config.target_fps > 0) {
            const target_frame_time = 1.0 / @as(f64, @floatFromInt(self.config.target_fps));
            while (self.getTime() - current_time < target_frame_time) {
                // Yield CPU to prevent high usage during waiting
                std.time.sleep(std.time.ns_per_ms);
            }
        }
    }

    /// Checks if it's time for a fixed update
    pub fn shouldFixedUpdate(self: *Time) bool {
        if (self.accumulated >= self.config.fixed_timestep) {
            self.accumulated -= self.config.fixed_timestep;
            return true;
        }
        return false;
    }

    /// Gets the current FPS
    pub fn getFPS(self: Time) f32 {
        return self.fps.current;
    }

    /// Gets the fixed timestep interval
    pub fn getFixedTimestep(self: Time) f32 {
        return self.config.fixed_timestep;
    }

    /// Gets the current frame's delta time
    pub fn getDelta(self: Time) f32 {
        return self.delta;
    }

    /// Gets total time since initialization
    pub fn getTotal(self: Time) f64 {
        return self.total;
    }
};

/// Helper function to get the appropriate time source function
fn getTimeSource(source: TimeSource) *const fn () f64 {
    return switch (source) {
        .GLFW => glfwTimeSource,
        .System => systemTimeSource,
        .Custom => @panic("Custom time source must be set explicitly"),
    };
}

/// GLFW time source implementation
fn glfwTimeSource() f64 {
    return c.glfwGetTime();
}

/// System time source implementation
fn systemTimeSource() f64 {
    return @as(f64, @floatFromInt(std.time.milliTimestamp())) / 1000.0;
}