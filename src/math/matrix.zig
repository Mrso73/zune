const Vec3 = @import("vector.zig").Vec3;

// 4x4 Matrix stored in column-major order (OpenGL convention)
pub const Mat4 = struct {
    data: [16]f32,

    const Self = @This();

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

    pub fn multiply(self: Self, other: Self) Self {
        var result: Self = undefined;
        for (0..4) |row| {
            for (0..4) |col| {
                var sum: f32 = 0.0;
                for (0..4) |i| {
                    sum += self.data[row * 4 + i] * other.data[i * 4 + col];
                }
                result.data[row * 4 + col] = sum;
            }
        }
        return result;
    }

    // Camera functions
    pub fn lookAt(eye: Vec3, target: Vec3, up: Vec3) Self {
        const z = eye.subtract(target).normalize();
        const x = up.cross(z).normalize();
        const y = z.cross(x);

        return .{
            .data = .{
                x.x,  x.y,  x.z,  0,
                y.x,  y.y,  y.z,  0,
                z.x,  z.y,  z.z,  0,
                -x.dot(eye), -y.dot(eye), -z.dot(eye), 1,
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