const std = @import("std");

const Vec3f = @import("../../math/vector.zig").Vec3f;
const Mat4f = @import("../../math/matrix.zig").Mat4f;


pub const TransformComponent = struct {
    position: Vec3f = Vec3f.create(0, 0, 0),
    rotation: Vec3f = Vec3f.create(0, 0, 0),
    scale: Vec3f = Vec3f.create(1, 1, 1),
    local_matrix: Mat4f = undefined,
    world_matrix: Mat4f = undefined,

    pub fn identity() TransformComponent {
        return TransformComponent{};
    }
    
    /// Convert transform components to 4x4 matrix
    pub fn toMatrix(self: TransformComponent) Mat4f {
        // Create result matrix (column-major as OpenGL expects)
        var result = Mat4f.identity();

        // Pre-calculate trigonometric values
        const cx = @cos(self.rotation.x);
        const sx = @sin(self.rotation.x);
        const cy = @cos(self.rotation.y);
        const sy = @sin(self.rotation.y);
        const cz = @cos(self.rotation.z);
        const sz = @sin(self.rotation.z);

        // Rotation matrix components
        // Combine X, Y, Z rotations (order: Y * X * Z)
        result.data[0] = cy * cz * self.scale.x;
        result.data[1] = (sx * sy * cz + cx * sz) * self.scale.x;
        result.data[2] = (-cx * sy * cz + sx * sz) * self.scale.x;
        result.data[3] = 0;

        result.data[4] = -cy * sz * self.scale.y;
        result.data[5] = (-sx * sy * sz + cx * cz) * self.scale.y;
        result.data[6] = (cx * sy * sz + sx * cz) * self.scale.y;
        result.data[7] = 0;

        result.data[8] = sy * self.scale.z;
        result.data[9] = -sx * cy * self.scale.z;
        result.data[10] = cx * cy * self.scale.z;
        result.data[11] = 0;

        // Translation
        result.data[12] = self.position.x;
        result.data[13] = self.position.y;
        result.data[14] = self.position.z;
        result.data[15] = 1;

        return result;
    }


    /// Move relative to its current position
    pub fn translate(self: *TransformComponent, x: f32, y: f32, z: f32) void {
        self.position[0] += x;
        self.position[1] += y;
        self.position[2] += z;
        self.updateMatrices();
    }


    /// Rotate the model by given angles (in radians)
    pub fn rotate(self: *TransformComponent, x: f32, y: f32, z: f32) void {
        self.rotation.x += x;
        self.rotation.y += y;
        self.rotation.z += z;
        self.updateMatrices();
    }


    /// Scale the model relative to its current scale
    pub fn relScale(self: *TransformComponent, x: f32, y: f32, z: f32) void {
        self.scale.x *= x;
        self.scale.y *= y;
        self.scale.z *= z;
        self.updateMatrices();
    }


    /// Set absolute position
    pub fn setPosition(self: *TransformComponent, x: f32, y: f32, z: f32) void {
        self.position = .{ .x = x, .y = y, .z = z };
        self.updateMatrices();
    }


    /// Set absolute rotation (angles in radians)
    pub fn setRotation(self: *TransformComponent, x: f32, y: f32, z: f32) void {
        self.rotation = .{ .x = x, .y = y, .z = z };
        self.updateMatrices();
    }


    /// Set absolute scale
    pub fn setScale(self: *TransformComponent, x: f32, y: f32, z: f32) void {
        self.scale = .{ .x = x, .y = y, .z = z };
        self.updateMatrices();
    }


    /// Update both local and world matrices
    pub fn updateMatrices(self: *TransformComponent) void {
        self.local_matrix = self.toMatrix();
        // World matrix will be updated by scene graph if implemented
        self.world_matrix = self.local_matrix;
    }


    /// Reset transform to identity
    pub fn reset(self: *TransformComponent) void {
        self.position = .{0, 0, 0};
        self.rotation = .{0, 0, 0};
        self.scale = .{1, 1, 1};
        self.updateMatrices();
    }


    /// Make object look at a point (useful for cameras)
    pub fn lookAt(self: *TransformComponent, target_x: f32, target_y: f32, target_z: f32) void {
        const dx = target_x - self.position[0];
        const dy = target_y - self.position[1];
        const dz = target_z - self.position[2];
        
        // Calculate yaw (y-axis rotation)
        self.rotation[1] = std.math.atan2(dx, dz);
        
        // Calculate pitch (x-axis rotation)
        const ground_dist = @sqrt(dx * dx + dz * dz);
        self.rotation[0] = -std.math.atan2(dy, ground_dist);
        
        self.updateMatrices();
    }
};