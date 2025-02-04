const std = @import("std");

pub const Transform = struct {
    position: [3]f32 = .{0, 0, 0},
    rotation: [3]f32 = .{0, 0, 0},
    scale: [3]f32 = .{1, 1, 1},
    local_matrix: [16]f32 = undefined,
    world_matrix: [16]f32 = undefined,
    
    /// Create identity transform
    pub fn identity() Transform {
        return Transform{};
    }
    
    /// Convert transform components to 4x4 matrix
    pub fn toMatrix(self: Transform) [16]f32 {
        // Create result matrix (column-major as OpenGL expects)
        var result: [16]f32 = .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        };

        // Pre-calculate trigonometric values
        const cx = @cos(self.rotation[0]);
        const sx = @sin(self.rotation[0]);
        const cy = @cos(self.rotation[1]);
        const sy = @sin(self.rotation[1]);
        const cz = @cos(self.rotation[2]);
        const sz = @sin(self.rotation[2]);

        // Rotation matrix components
        // Combine X, Y, Z rotations (order: Y * X * Z)
        result[0] = cy * cz * self.scale[0];
        result[1] = (sx * sy * cz + cx * sz) * self.scale[0];
        result[2] = (-cx * sy * cz + sx * sz) * self.scale[0];
        result[3] = 0;

        result[4] = -cy * sz * self.scale[1];
        result[5] = (-sx * sy * sz + cx * cz) * self.scale[1];
        result[6] = (cx * sy * sz + sx * cz) * self.scale[1];
        result[7] = 0;

        result[8] = sy * self.scale[2];
        result[9] = -sx * cy * self.scale[2];
        result[10] = cx * cy * self.scale[2];
        result[11] = 0;

        // Translation
        result[12] = self.position[0];
        result[13] = self.position[1];
        result[14] = self.position[2];
        result[15] = 1;

        return result;
    }


    /// Move relative to its current position
    pub fn translate(self: *Transform, x: f32, y: f32, z: f32) void {
        self.position[0] += x;
        self.position[1] += y;
        self.position[2] += z;
        self.updateMatrices();
    }


    /// Rotate the model by given angles (in radians)
    pub fn rotate(self: *Transform, x: f32, y: f32, z: f32) void {
        self.rotation[0] += x;
        self.rotation[1] += y;
        self.rotation[2] += z;
        self.updateMatrices();
    }


    /// Scale the model relative to its current scale
    pub fn scale(self: *Transform, x: f32, y: f32, z: f32) void {
        self.scale[0] *= x;
        self.scale[1] *= y;
        self.scale[2] *= z;
        self.updateMatrices();
    }


    /// Set absolute position
    pub fn setPosition(self: *Transform, x: f32, y: f32, z: f32) void {
        self.position = .{x, y, z};
        self.updateMatrices();
    }


    /// Set absolute rotation (angles in radians)
    pub fn setRotation(self: *Transform, x: f32, y: f32, z: f32) void {
        self.rotation = .{x, y, z};
        self.updateMatrices();
    }


    /// Set absolute scale
    pub fn setScale(self: *Transform, x: f32, y: f32, z: f32) void {
        self.scale = .{x, y, z};
        self.updateMatrices();
    }


    /// Update both local and world matrices
    pub fn updateMatrices(self: *Transform) void {
        self.local_matrix = self.toMatrix();
        // World matrix will be updated by scene graph if implemented
        self.world_matrix = self.local_matrix;
    }


    /// Reset transform to identity
    pub fn reset(self: *Transform) void {
        self.position = .{0, 0, 0};
        self.rotation = .{0, 0, 0};
        self.scale = .{1, 1, 1};
        self.updateMatrices();
    }


    /// Make object look at a point (useful for cameras)
    pub fn lookAt(self: *Transform, target_x: f32, target_y: f32, target_z: f32) void {
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