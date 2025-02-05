// camera.zig
const std = @import("std");
const c = @import("../c.zig");

const math = @import("../math/common.zig");
const Vec3 = @import("../math/vector.zig").Vec3;
const Mat4 = @import("../math/matrix.zig").Mat4;

/// Camera implementation supporting both perspective and orthographic projections.
/// Handles view and projection matrix calculations for 3D rendering.
pub const Camera = struct {
    position: Vec3 = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
    target: Vec3 = .{ .x = 0.0, .y = 0.0, .z = -1.0 },
    up: Vec3 = .{ .x = 0.0, .y = 1.0, .z = 0.0 },

    view_matrix: Mat4 = Mat4.identity(),
    projection_matrix: Mat4 = Mat4.identity(),

    near: f32,
    far: f32,

    camera_type: union(enum) {
        perspective: struct {
            fov: f32,
            aspect: f32,
        },
        orthographic: struct {
            left: f32,
            right: f32,
            bottom: f32,
            top: f32,
        },
    },


    // Initialize a perspective camera with the given parameters
    pub fn initPerspective(fov: f32, aspect: f32, near: f32, far: f32) Camera {
        var camera = Camera{
            .near = near,
            .far = far,
            .camera_type = .{
                .perspective = .{
                    .fov = fov,
                    .aspect = aspect,
                },
            },
        };
        camera.updateProjection();
        camera.updateViewMatrix();
        return camera;
    }
    

    /// Initialize an orthographic camera with the given parameters
    pub fn initOrthographic(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) Camera {
        var camera = Camera{
            .near = near,
            .far = far,
            .camera_type = .{
                .orthographic = .{
                    .left = left,
                    .right = right,
                    .bottom = bottom,
                    .top = top,
                },
            },
        };
        camera.updateProjection();
        camera.updateViewMatrix();
        return camera;
    }


    /// Update the projection matrix based on camera type
    pub fn updateProjection(self: *Camera) void {

        switch (self.camera_type) {
            .perspective => |*persp| {
                self.projection_matrix = Mat4.perspective(
                    persp.fov,
                    persp.aspect,
                    self.near,
                    self.far,
                );
            },
            .orthographic => |*ortho| {
                self.projection_matrix = Mat4.ortho(
                    ortho.left,
                    ortho.right,
                    ortho.bottom,
                    ortho.top,
                    self.near,
                    self.far,
                );
            },
        }
    }
    

    /// Set the camera position and update the view matrix
    pub fn setPosition(self: *Camera, position: Vec3) void {
        self.position = position;
        self.updateViewMatrix();
    }


    /// Set the camera target and update the view matrix
    pub fn lookAt(self: *Camera, target: Vec3) void {
        self.target = target;
        self.updateViewMatrix();
    }


    /// Update the view matrix based on the current position, target, and up vector.
    pub fn updateViewMatrix(self: *Camera) void {
        self.view_matrix = Mat4.lookAt(
            self.position,
            self.target,
            self.up,
        );
    }


    /// Get the combined view-projection matrix
    pub fn getViewProjectionMatrix(self: *Camera) Mat4 {
        return math.multiplyMatrices(self.projection_matrix, self.view_matrix);
    }


    /// Handle window resize events
    pub fn resize(self: *Camera, width: u32, height: u32) void {
        const w_f32: f32 = @floatFromInt(width);
        const h_f32: f32 = @floatFromInt(height);

        switch (self.camera_type) {
            .perspective => |*persp| {
                persp.aspect = w_f32 / h_f32;
            },
            .orthographic => |*ortho| {
                ortho.left = -w_f32 / 2;
                ortho.right = w_f32 / 2;
                ortho.bottom = -h_f32 / 2;
                ortho.top = h_f32 / 2;
            },
        }
        self.updateProjection();
    }

    /// Debug information printing - only included in debug builds
    pub fn debugInfo(self: *const Camera) void {
        if (@import("builtin").mode == .Debug) {
            std.debug.print("\nCamera Debug Info:\n", .{});
            std.debug.print("Position: ({d:.2}, {d:.2}, {d:.2})\n", .{
                self.position[0], self.position[1], self.position[2],
            });
            std.debug.print("Target: ({d:.2}, {d:.2}, {d:.2})\n", .{
                self.target[0], self.target[1], self.target[2],
            });
            std.debug.print("Up: ({d:.2}, {d:.2}, {d:.2})\n", .{
                self.up[0], self.up[1], self.up[2],
            });
        }
    }
};


/// Mouse-controlled camera system for first-person and similar camera movements
pub const CameraMouseController = struct {
    camera: *Camera,
    
    yaw: f32 = -90.0, // Facing negative z by default
    pitch: f32 = 0.0,
    
    mouse_sensitivity: f32 = 1.5,
    
    last_x: f32,
    last_y: f32,
    first_mouse: bool = true,

    var max_delta: f32 = 100.0;


    /// Initialize the mouse controller with initial mouse position
    pub fn init(camera: *Camera, initial_x: f32, initial_y: f32) CameraMouseController {
        return .{
            .camera = camera,
            .last_x = initial_x,
            .last_y = initial_y,
        };
    }


    /// Handle mouse movement to update yaw, pitch, and the camera’s target.
    pub fn handleMouseMovement(self: *CameraMouseController, x_pos: f32, y_pos: f32, delta_time: f32) void {

        if (self.first_mouse) {
            self.last_x = x_pos;
            self.last_y = y_pos;
            self.first_mouse = false;
            return;
        }

        // Compute mouse offsets.
        const delta_x = x_pos - self.last_x;
        const delta_y = self.last_y - y_pos;

        self.last_x = x_pos;
        self.last_y = y_pos;

        // Apply sensitivity after clamping
        const x_offset = std.math.clamp(delta_x, -max_delta, max_delta) * self.mouse_sensitivity * delta_time;
        const y_offset = std.math.clamp(delta_y, -max_delta, max_delta) * self.mouse_sensitivity * delta_time;

        self.yaw += x_offset;
        self.pitch = std.math.clamp(self.pitch + y_offset, -89.0, 89.0);

        // Calculate new direction vector
        const rad_yaw = std.math.degreesToRadians(self.yaw);
        const rad_pitch = std.math.degreesToRadians(self.pitch);

        var direction = Vec3{
            .x = @cos(rad_yaw) * @cos(rad_pitch),
            .y = @sin(rad_pitch),
            .z = @sin(rad_yaw) * @cos(rad_pitch),
        };

        // Normalize the direction vector
        direction = direction.normalize();

        // Calculate the view distance (distance between camera position and target)
        const current_view_vector = self.camera.target.subtract(self.camera.position);
        const view_distance = current_view_vector.length();

        // Scale the direction vector by the view distance
        const scaled_direction = direction.scale(view_distance);

        // Update camera target while maintaining the same distance
        self.camera.target = self.camera.position.add(scaled_direction);
        
        self.camera.updateViewMatrix();
    }

    /// Debug information for mouse controller - only included in debug builds
    pub fn debugMouseInfo(self: *const CameraMouseController) void {
        if (comptime @import("builtin").mode == .Debug) {
            std.debug.print("\nMouse Controller Debug:\n", .{});
            std.debug.print("Yaw: {d:.2}, Pitch: {d:.2}\n", .{ self.yaw, self.pitch });
            std.debug.print("Last mouse pos: ({d:.2}, {d:.2})\n", .{ self.last_x, self.last_y });
        }
    }
};