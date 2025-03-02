// time.zig - Time management module
const std = @import("std");
const c = @import("../bindings/c.zig");


/// Error type for time operations
pub const TimeError = error{
    TimeSourceUnavailable,
    InvalidTimeSource,
};


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

    /// Custom time source function (only used when time_source is .Custom)
    custom_time_source: ?*const fn () f64 = null,
};


/// Available time sources
pub const TimeSource = enum {
    GLFW,
    System,
    Custom,
};


/// Represents frame timing statistics
pub const FrameStats = struct {
    /// Current FPS value (averaged over 1 second)
    current: f32,
    /// Frame counter for FPS calculation
    frames: u32,
    /// Timer for FPS calculation (in seconds)
    timer: f32,
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
    fps: FrameStats,

    /// Time source function pointer
    getTime: *const fn () f64,


    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    /// Creates a new Time instance with the given configuration
    pub fn init(config: TimeConfig) TimeError!Time {
        // Validate configuration
        const time_source_fn = try getTimeSource(config);
        
        // Get initial time
        const initial_time = time_source_fn();
        
        return .{
            .config = config,
            .delta = 0.0,
            .accumulated = 0.0,
            .last_frame = initial_time,
            .total = 0.0,
            .fps = .{
                .current = 0.0,
                .frames = 0,
                .timer = 0.0,
            },
            .getTime = time_source_fn,
        };
    }


    /// Creates a Time instance with default configuration
    pub fn initDefault() TimeError!Time {
        return try init(.{});
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
            frameLimiter(self.getTime, current_time, self.config.target_fps);
        }
    }


    /// Checks if it's time for a fixed update and returns number of updates needed
    pub fn getFixedUpdateCount(self: *Time) u32 {
        var count: u32 = 0;
        while (self.accumulated >= self.config.fixed_timestep) {
            self.accumulated -= self.config.fixed_timestep;
            count += 1;
        }
        return count;
    }


    /// Performs a single fixed update check
    pub fn shouldFixedUpdate(self: *Time) bool {
        if (self.accumulated >= self.config.fixed_timestep) {
            self.accumulated -= self.config.fixed_timestep;
            return true;
        }
        return false;
    }


    // ============================================================
    // Public API: Accessor Functions
    // ============================================================

    /// Gets the current FPS
    pub fn getFPS(self: Time) f32 {
        return self.fps.current;
    }


    /// Gets the target FPS
    pub fn getTargetFPS(self: Time) u32 {
        return self.config.target_fps;
    }


    /// Sets a new target FPS
    pub fn setTargetFPS(self: *Time, target_fps: u32) void {
        self.config.target_fps = target_fps;
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


    /// Sets a new fixed timestep value
    pub fn setFixedTimestep(self: *Time, timestep: f32) void {
        self.config.fixed_timestep = timestep;
    }
};


/// Helper function to get the appropriate time source function
fn getTimeSource(config: TimeConfig) TimeError!*const fn () f64 {
    return switch (config.time_source) {
        .GLFW => glfwTimeSource,
        .System => systemTimeSource,
        .Custom => if (config.custom_time_source) |source| 
                      source 
                   else 
                      return TimeError.InvalidTimeSource,
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


/// Efficient frame limiter
fn frameLimiter(timeFunc: *const fn () f64, frame_start: f64, target_fps: u32) void {
    const target_frame_time = 1.0 / @as(f64, @floatFromInt(target_fps));
    const end_time = frame_start + target_frame_time;
    
    // Time remaining until next frame should start
    const remaining = end_time - timeFunc();
    
    // If we have time to wait
    if (remaining > 0) {
        // For longer waits, sleep in chunks to save CPU
        if (remaining > 0.002) { // 2ms threshold for sleep

            // Sleep a bit less than the full time to account for sleep inaccuracy
            const sleep_time = @as(u64, @intFromFloat((remaining - 0.001) * std.time.ns_per_s));
            std.time.sleep(sleep_time);
        }
        
        // Spin for the remainder to get precise timing
        while (timeFunc() < end_time) {
            std.atomic.spinLoopHint();
        }
    }
}


/// Helper function for multiple fixed updates
pub fn runFixedUpdates(time: *Time, updateFn: *const fn() void) void {
    const update_count = time.getFixedUpdateCount();
    var i: u32 = 0;
    while (i < update_count) : (i += 1) {
        updateFn();
    }
}