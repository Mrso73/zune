const Vec3 = @import("vector.zig").Vec3;

// 4x4 Matrix stored in column-major order (OpenGL convention)
pub const Mat4 = struct {
    data: [16]f32,

    const Self = @This();
    

    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    pub fn identity() Self {
        return .{
            .data = .{
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            },
        };
    }

    pub fn multiply(self: Mat4, other: Mat4) Mat4 {
    var result: Mat4 = undefined;
    for (0..4) |col| {
        for (0..4) |row| {
            var sum: f32 = 0.0;
            for (0..4) | k | {
                // self[i + k*4] corresponds to self[row][k]
                // other[k + col*4] corresponds to other[k][col]
                sum += self.data[row + k * 4] * other.data[k + col * 4];
            }
            result.data[row + col * 4] = sum;
        }
    }
    return result;
}

    /// Creates a view matrix using a standard look-at formulation.
    pub fn lookAt(eye: Vec3(f32), target: Vec3(f32), up: Vec3(f32)) Mat4 {
        // Compute forward vector (from eye to target)
        const f = target.subtract(eye).normalize();
        // Compute right vector
        const s = f.cross(up).normalize();
        // Compute new up vector
        const u = s.cross(f);

        // Return in column-major order (OpenGL convention)
        return Mat4{
            .data = .{
                s.x,       u.x,        -f.x,      0,
                s.y,       u.y,        -f.y,      0,
                s.z,       u.z,        -f.z,      0,
                -s.dot(eye), -u.dot(eye), f.dot(eye), 1,
            },
        };
    }

    pub fn perspective(fov_y: f32, aspect: f32, near: f32, far: f32) Self {
        const f = 1.0 / @tan(fov_y / 2.0);
        const nf = 1.0 / (near - far);

        return .{
            .data = .{
                f / aspect, 0,   0,                        0,
                0,          f,   0,                        0,
                0,          0,   (far + near) * nf,        -1,
                0,          0,   2 * far * near * nf,      0,
            },
        };
    }

    pub fn ortho(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) Self {
        const lr = 1.0 / (left - right);
        const bt = 1.0 / (bottom - top);
        const nf = 1.0 / (near - far);

        return .{
            .data = .{
                -2 * lr,  0,      0,      0,
                0,        -2 * bt,0,      0,
                0,        0,      2 * nf, 0,
                (left + right) * lr,
                (top + bottom) * bt,
                (far + near) * nf,
                1,
            },
        };
    }
};