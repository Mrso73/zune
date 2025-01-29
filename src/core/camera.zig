// camera.zig
const std = @import("std");
const math = @import("../math/math.zig");
const c = @import("../c.zig");

pub const Camera = struct {
    position: math.Vec3 = .{0.0, 0.0, 0.0},
    target: math.Vec3 = .{0, 0, -1},
    up: math.Vec3 = .{0, 1, 0},

    view_matrix: math.Mat4 = math.identity_mat4,
    projection_matrix: math.Mat4 = math.identity_mat4,

    near: f32,
    far: f32,

    camera_type: union(enum) { 
        perspective: struct {fov: f32, aspect: f32 },
        orthographic: struct { left: f32, right: f32, bottom: f32, top: f32,},
    },


    // Initialize a perspective camera
    pub fn initPerspective(fov: f32, aspect: f32, near: f32, far: f32) Camera {
        var camera = Camera{
            .near = near,
            .far = far,
            .camera_type = .{
                .perspective = .{
                    .fov = fov,
                    .aspect = aspect,
                }
            },
        };
        camera.updateProjection();
        camera.updateViewMatrix();
        return camera;
    }
    
    // Initialize an orthographic camera
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
                } 
            }, 
        };
        camera.updateProjection();
        camera.updateViewMatrix();
        return camera;
    }

    pub fn updateProjection(self: *Camera) void {
        switch (self.camera_type) {
            .perspective => |*persp| {
                self.projection_matrix = math.perspective(
                    persp.fov,
                    persp.aspect,
                    self.near,
                    self.far,
                );
            },
            .orthographic => |*ortho| {
                self.projection_matrix = math.ortho(
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
    

    // Set new camera position;
    pub fn setPosition(self: *Camera, position: [3]f32) void {
        self.position = position;
        self.updateViewMatrix(); // Update the view
    }

    // Set new camera target
    pub fn lookAt(self: *Camera, target: [3]f32) void {
    self.target = target;
    self.updateViewMatrix();
}

    // Updates how things look form different positions and angles
    // Run after every change to the camera 
    pub fn updateViewMatrix(self: *Camera) void {
        self.view_matrix = math.lookAt(
            self.position,
            self.target,
            self.up
        );
    }

    // Get combined view-projection matrix
    pub fn getViewProjectionMatrix(self: *Camera) [16]f32 {
        return math.multiplyMatrices(self.projection_matrix, self.view_matrix);
    }

    // Handle window resizing for both camera types
    pub fn resize(self: *Camera, width: u32, height: u32) void {
        const w_f32 = @as(f32, @floatFromInt(width));
        const h_f32 = @as(f32, @floatFromInt(height));

        switch (self.camera_type) {
            .perspective => |*persp| {
                persp.aspect = w_f32 / h_f32;
                self.updateProjection();
            },
            .orthographic => |*ortho| {
                ortho.left = -w_f32 / 2;
                ortho.right = w_f32 / 2;
                ortho.bottom = -h_f32 / 2;
                ortho.top = h_f32 / 2;
                self.updateProjection();
            },
        }
    }

    // Add these debug functions to your Camera struct
    pub fn debugInfo(self: *Camera) void {
        std.debug.print("\nCamera Debug Info:\n", .{});
        std.debug.print("Position: ({d:.2}, {d:.2}, {d:.2})\n", .{
            self.position[0], self.position[1], self.position[2]
        });
        std.debug.print("Target: ({d:.2}, {d:.2}, {d:.2})\n", .{
            self.target[0], self.target[1], self.target[2]
        });
        std.debug.print("Up: ({d:.2}, {d:.2}, {d:.2})\n", .{
            self.up[0], self.up[1], self.up[2]
        });
    }
};


/// Camera controller that can be used for First person and other mouse related things
pub const CameraMouseController = struct {
    camera: *Camera,
    
    // Camera angles
    yaw: f32 = -90.0, // Facing negative z by default
    pitch: f32 = 0.0,
    
    // Camera settings
    mouse_sensitivity: f32 = 0.1,
    
    // Last mouse position for delta calculation
    last_x: f32,
    last_y: f32,
    first_mouse: bool = true,

   // Modify init function to take initial mouse position
    pub fn init(camera: *Camera, initial_x: f32, initial_y: f32) CameraMouseController {
        return .{
            .camera = camera,
            .last_x = initial_x,
            .last_y = initial_y,
        };
    }

    pub fn handleMouseMovement(self: *CameraMouseController, x_pos: f32, y_pos: f32) void {
        if (self.first_mouse) {
            self.last_x = x_pos;
            self.last_y = y_pos;
            self.first_mouse = false;
            return;
        }

        // Reduce the delta to prevent large jumps
        const delta_x = x_pos - self.last_x;
        const delta_y = self.last_y - y_pos;  // Y is inverted
        
        // Clamp the maximum delta to prevent sudden jumps
        const max_delta: f32 = 100.0;
        const clamped_delta_x = std.math.clamp(delta_x, -max_delta, max_delta);
        const clamped_delta_y = std.math.clamp(delta_y, -max_delta, max_delta);

        self.last_x = x_pos;
        self.last_y = y_pos;

        // Apply sensitivity after clamping
        const x_offset = clamped_delta_x * self.mouse_sensitivity;
        const y_offset = clamped_delta_y * self.mouse_sensitivity;

        self.yaw += x_offset;
        self.pitch += y_offset;

        
        // Limit pitch up and down to stop camera fliping 
        self.pitch = std.math.clamp(self.pitch, -89.0, 89.0);

        // Calculate new camera direction
        const direction: math.Vec3 = .{
            @cos(std.math.degreesToRadians(self.yaw)) * @cos(std.math.degreesToRadians(self.pitch)),
            @sin(std.math.degreesToRadians(self.pitch)),
            @sin(std.math.degreesToRadians(self.yaw)) * @cos(std.math.degreesToRadians(self.pitch)),
        };

        // update camera target relative to position 
        const normalized_direction = math.normalizeVec3(direction);
        self.camera.target = math.addVec3(self.camera.position, normalized_direction);
        self.camera.updateViewMatrix();
    }

    // Add these to CameraMouseController
    pub fn debugMouseInfo(self: *CameraMouseController) void {
        std.debug.print("\nMouse Controller Debug:\n", .{});
        std.debug.print("Yaw: {d:.2}, Pitch: {d:.2}\n", .{self.yaw, self.pitch});
        std.debug.print("Last mouse pos: ({d:.2}, {d:.2})\n", .{self.last_x, self.last_y});
    }
};