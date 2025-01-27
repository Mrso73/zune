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
                    .aspect = aspect 
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
};

