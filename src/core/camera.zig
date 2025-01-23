// camera.zig
const std = @import("std");
const math = @import("../math/math.zig");
const c = @import("../c.zig");

const Camera = struct {
    // Common properties for all camera types
    position: [3]f32,
    target: [3]f32,
    up: [3]f32,

    // Cached matrices
    view_matrix: [16]f32,
    projection_matrix: [16]f32,

    // Common camera parameters
    near: f32,
    far: f32,

    // Type tag for runtime camera type checking
    camera_type: CameraType,

    pub const CameraType = enum {
        Perspective,
        Orthographic,
    };

    // Initialize base camera properties
    pub fn init(camera_type: CameraType) Camera {
        return .{
            .position = .{ 0.0, 0.0, 0.0 },
            .target = .{ 0.0, 0.0, -1.0 },
            .up = .{ 0.0, 1.0, 0.0 },
            .view_matrix = computeIdentityMatrix(),
            .projection_matrix = computeIdentityMatrix(),
            .near = 0.1,
            .far = 100.0,
            .camera_type = camera_type,
        };
    }

    // Update view matrix based on current position and target
    pub fn updateViewMatrix(self: *Camera) void {
        self.view_matrix = computeLookAtMatrix(
            self.position,
            self.target,
            self.up,
        );
    }

    // Get combined view-projection matrix
    pub fn getViewProjectionMatrix(self: *Camera) [16]f32 {
        return multiplyMatrices(self.projection_matrix, self.view_matrix);
    }

    // Utility functions for matrix operations
    fn computeIdentityMatrix() [16]f32 {
        return .{
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        };
    }

    fn computeLookAtMatrix(eye: [3]f32, target: [3]f32, up: [3]f32) [16]f32 {
        // Calculate camera axes
        const z_axis = normalize(subtractVectors(eye, target)); // Forward
        const x_axis = normalize(crossProduct(up, z_axis)); // Right
        const y_axis = crossProduct(z_axis, x_axis); // Up

        // Create view matrix
        return .{
            x_axis[0],                y_axis[0],                z_axis[0],                0.0,
            x_axis[1],                y_axis[1],                z_axis[1],                0.0,
            x_axis[2],                y_axis[2],                z_axis[2],                0.0,
            -dotProduct(x_axis, eye), -dotProduct(y_axis, eye), -dotProduct(z_axis, eye), 1.0,
        };
    }

    // Vector operations
    fn normalize(v: [3]f32) [3]f32 {
        const length = @sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
        return .{
            v[0] / length,
            v[1] / length,
            v[2] / length,
        };
    }

    fn subtractVectors(a: [3]f32, b: [3]f32) [3]f32 {
        return .{
            a[0] - b[0],
            a[1] - b[1],
            a[2] - b[2],
        };
    }

    fn crossProduct(a: [3]f32, b: [3]f32) [3]f32 {
        return .{
            a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0],
        };
    }

    fn dotProduct(a: [3]f32, b: [3]f32) f32 {
        return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
    }

    fn multiplyMatrices(a: [16]f32, b: [16]f32) [16]f32 {
        var result: [16]f32 = undefined;

        for (0..4) |row| {
            for (0..4) |col| {
                var sum: f32 = 0.0;
                for (0..4) |i| {
                    sum += a[row * 4 + i] * b[i * 4 + col];
                }
                result[row * 4 + col] = sum;
            }
        }

        return result;
    }
};

/// Perspective camera implementation
pub const PerspectiveCamera = struct {
    base: Camera,
    fov: f32,
    aspect: f32,

    pub fn init(fov: f32, aspect: f32, near: f32, far: f32) PerspectiveCamera {
        var camera = PerspectiveCamera{
            .base = Camera.init(.Perspective),
            .fov = fov,
            .aspect = aspect,
        };

        camera.base.near = near;
        camera.base.far = far;
        camera.updateProjectionMatrix();

        return camera;
    }

    pub fn updateProjectionMatrix(self: *PerspectiveCamera) void {
        const f = 1.0 / @tan(self.fov * 0.5);
        const nf = 1.0 / (self.base.near - self.base.far);

        self.base.projection_matrix = .{
            f / self.aspect, 0.0, 0.0,                                       0.0,
            0.0,             f,   0.0,                                       0.0,
            0.0,             0.0, (self.base.far + self.base.near) * nf,     -1.0,
            0.0,             0.0, 2.0 * self.base.far * self.base.near * nf, 0.0,
        };
    }

    pub fn setPosition(self: *PerspectiveCamera, x: f32, y: f32, z: f32) void {
        self.base.position = .{ x, y, z };
        self.base.updateViewMatrix();
    }

    pub fn lookAt(self: *PerspectiveCamera, x: f32, y: f32, z: f32) void {
        self.base.target = .{ x, y, z };
        self.base.updateViewMatrix();
    }
};

/// Orthographic camera implementation
pub const OrthographicCamera = struct {
    base: Camera,
    left: f32,
    right: f32,
    bottom: f32,
    top: f32,

    pub fn init(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) OrthographicCamera {
        var camera = OrthographicCamera{
            .base = Camera.init(.Orthographic),
            .left = left,
            .right = right,
            .bottom = bottom,
            .top = top,
        };

        camera.base.near = near;
        camera.base.far = far;
        camera.updateProjectionMatrix();

        return camera;
    }

    pub fn updateProjectionMatrix(self: *OrthographicCamera) void {
        const lr = 1.0 / (self.left - self.right);
        const bt = 1.0 / (self.bottom - self.top);
        const nf = 1.0 / (self.base.near - self.base.far);

        self.base.projection_matrix = .{
            -2.0 * lr,                     0.0,                           0.0,                                   0.0,
            0.0,                           -2.0 * bt,                     0.0,                                   0.0,
            0.0,                           0.0,                           2.0 * nf,                              0.0,
            (self.left + self.right) * lr, (self.top + self.bottom) * bt, (self.base.far + self.base.near) * nf, 1.0,
        };
    }

    pub fn setPosition(self: *OrthographicCamera, x: f32, y: f32, z: f32) void {
        self.base.position = .{ x, y, z };
        self.base.updateViewMatrix();
    }

    pub fn setSize(self: *OrthographicCamera, width: f32, height: f32) void {
        const half_width = width * 0.5;
        const half_height = height * 0.5;

        self.left = -half_width;
        self.right = half_width;
        self.bottom = -half_height;
        self.top = half_height;

        self.updateProjectionMatrix();
    }
};
