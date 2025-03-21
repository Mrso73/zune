// camera.zig
const std = @import("std");
const c = @import("../bindings/c.zig");

const Renderer = @import("renderer.zig").Renderer;
const Model = @import("model.zig").Model;
const Mesh = @import("mesh.zig").Mesh;
const Material = @import("material.zig").Material;

const Vec2f = @import("../math/vector.zig").Vec2f;
const Vec3f = @import("../math/vector.zig").Vec3f;
const Mat4f = @import("../math/matrix.zig").Mat4f;

/// Camera implementation supporting both perspective and orthographic projections.
/// Handles view and projection matrix calculations for 3D rendering.
pub const Camera = struct {
    active_renderer: *Renderer,

    position: Vec3f = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
    target: Vec3f = .{ .x = 0.0, .y = 0.0, .z = -1.0 },
    up: Vec3f = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
    forward: Vec3f = .{ .x = 0.0, .y = 0.0, .z = -1.0 },

    view_matrix: Mat4f,
    projection_matrix: Mat4f,

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


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    // Initialize a perspective camera with the given parameters
    pub fn initPerspective(renderer_ptr: *Renderer, fov: f32, aspect: f32, near: f32, far: f32) Camera {
        var camera = Camera{
            .active_renderer = renderer_ptr,
            .view_matrix = Mat4f.identity(),
            .projection_matrix = Mat4f.identity(),
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
    pub fn initOrthographic(renderer_ptr: *Renderer, left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) Camera {
        var camera = Camera{
            .active_renderer = renderer_ptr, 
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


    // ============================================================
    // Public API: Operational Functions
    // ============================================================
    
    /// Draw a model from the camera perspective
    pub fn drawModel(self: *Camera, model: *Model, model_matrix: *Mat4f) !void {
        try self.active_renderer.drawModel(model, model_matrix, &self.view_matrix, &self.projection_matrix);
    }


    pub fn drawMesh(self: *Camera, mesh: *Mesh, material: *Material, model_matrix: *Mat4f) !void {
        try self.active_renderer.drawMesh(mesh, material, model_matrix, &self.view_matrix, &self.projection_matrix);
    }


    /// Update the projection matrix based on camera type
    pub fn updateProjection(self: *Camera) void {

        switch (self.camera_type) {
            .perspective => |*persp| {
                self.projection_matrix = Mat4f.perspective(
                    persp.fov,
                    persp.aspect,
                    self.near,
                    self.far,
                );
            },
            .orthographic => |*ortho| {
                self.projection_matrix = Mat4f.ortho(
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


    pub fn worldToScreen(self: Camera, point: Vec3f) Vec2f {
        const M = self.getViewProjectionMatrix().data;
        const v = point;

        const x = M[0]*v.x + M[4]*v.y + M[8]*v.z + M[12];
        const y = M[1]*v.x + M[5]*v.y + M[9]*v.z + M[13];
        const w = M[3]*v.x + M[7]*v.y + M[11]*v.z + M[15];

        if (w == 0) return .{};

        return .{
            .x = x/w,
            .y = y/w,
        };
    }


    /// Return wether point
    pub fn inView(self: Camera, point: Vec3f) bool {
        _ = self;
        const pos = worldToScreen(point);
        return (@abs(pos.x) <= 1 and @abs(pos.y) < 1);
    } 

    /// Get the forward direction vector
    pub fn getForwardVector(self: *const Camera) Vec3f {
        return self.forward;
    }


    /// Set the camera position and update the view matrix
    pub fn setPosition(self: *Camera, position: Vec3f) void {
        self.position = position;
        self.updateViewMatrix();
    }


    /// Set the camera target and update the view matrix
    pub fn lookAt(self: *Camera, target: Vec3f) void {
        self.target = target;
        self.updateViewMatrix();
    }


    /// Update the view matrix based on the current position, target, and up vector.
    pub fn updateViewMatrix(self: *Camera) void {
        // Calculate forward vector
        //self.forward = self.target.subtract(self.position).normalize();
        self.forward = Vec3f.normalize(Vec3f.subtract(self.target, self.position));
        
        // Create the view matrix
        self.view_matrix = Mat4f.lookAt(
            self.position,
            self.target,
            self.up,
        );
    }


    /// Get the combined view-projection matrix
    pub fn getViewProjectionMatrix(self: *Camera) Mat4f {
        return self.projection_matrix.multiply(self.view_matrix);
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
            std.debug.print("Forward: ({d:.2}, {d:.2}, {d:.2})\n", .{
                self.forward.x, self.forward.y, self.forward.z,
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


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    /// Initialize the mouse controller with initial mouse position
    pub fn init(camera: *Camera, current_x_cursor: f32, current_y_cursor: f32) CameraMouseController {

        // Calculate the yaw based on the forward vector (idk what is happening here)
        const v = if (camera.forward.x != 0) camera.forward.z / camera.forward.x else null;
        const yaw: f32 = if (v) | val | std.math.radiansToDegrees(if (camera.forward.z > 0) std.math.atan(val) else -std.math.atan(val)) else (if(camera.forward.z <= 0) -90.0 else 90.0);

        return .{
            .camera = camera,
            .last_x = current_x_cursor,
            .last_y = current_y_cursor,
            .yaw = yaw,
            .pitch = 0.0,
        };
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

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

        var direction: Vec3f = .{
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