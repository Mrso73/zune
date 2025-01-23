const std = @import("std");

// Constants
pub const PI: f32 = 3.14159265358979323846264338327950288;
pub const DEG2RAD: f32 = PI / 180.0;
pub const RAD2DEG: f32 = 180.0 / PI;
pub const EPSILON: f32 = 1e-6;

// Vector types
pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Vec2 {
        return .{ .x = x, .y = y };
    }

    pub fn zero() Vec2 {
        return .{ .x = 0, .y = 0 };
    }

    pub fn one() Vec2 {
        return .{ .x = 1, .y = 1 };
    }

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn sub(self: Vec2, other: Vec2) Vec2 {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    pub fn scale(self: Vec2, scalar: f32) Vec2 {
        return .{
            .x = self.x * scalar,
            .y = self.y * scalar,
        };
    }

    pub fn dot(self: Vec2, other: Vec2) f32 {
        return self.x * other.x + self.y * other.y;
    }

    pub fn length(self: Vec2) f32 {
        return @sqrt(self.dot(self));
    }

    pub fn normalize(self: Vec2) Vec2 {
        const len = self.length();
        if (len > EPSILON) {
            return self.scale(1.0 / len);
        }
        return self;
    }
};

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn zero() Vec3 {
        return .{ .x = 0, .y = 0, .z = 0 };
    }

    pub fn one() Vec3 {
        return .{ .x = 1, .y = 1, .z = 1 };
    }

    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    pub fn sub(self: Vec3, other: Vec3) Vec3 {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    pub fn scale(self: Vec3, scalar: f32) Vec3 {
        return .{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
        };
    }

    pub fn dot(self: Vec3, other: Vec3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn cross(self: Vec3, other: Vec3) Vec3 {
        return .{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }

    pub fn length(self: Vec3) f32 {
        return @sqrt(self.dot(self));
    }

    pub fn normalize(self: Vec3) Vec3 {
        const len = self.length();
        if (len > EPSILON) {
            return self.scale(1.0 / len);
        }
        return self;
    }
};

pub const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn init(x: f32, y: f32, z: f32, w: f32) Vec4 {
        return .{ .x = x, .y = y, .z = z, .w = w };
    }

    pub fn fromVec3(v: Vec3, w: f32) Vec4 {
        return .{ .x = v.x, .y = v.y, .z = v.z, .w = w };
    }

    pub fn add(self: Vec4, other: Vec4) Vec4 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
            .w = self.w + other.w,
        };
    }

    pub fn scale(self: Vec4, scalar: f32) Vec4 {
        return .{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
            .w = self.w * scalar,
        };
    }
};

// 4x4 Matrix type
pub const Mat4 = struct {
    data: [16]f32,

    pub fn identity() Mat4 {
        return .{ .data = .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        } };
    }

    pub fn mul(self: Mat4, other: Mat4) Mat4 {
        var result: Mat4 = undefined;

        inline for (0..4) |row| {
            inline for (0..4) |col| {
                var sum: f32 = 0;
                inline for (0..4) |i| {
                    sum += self.data[row * 4 + i] * other.data[i * 4 + col];
                }
                result.data[row * 4 + col] = sum;
            }
        }

        return result;
    }

    pub fn translate(self: Mat4, v: Vec3) Mat4 {
        var result = self;
        result.data[12] = self.data[0] * v.x + self.data[4] * v.y + self.data[8] * v.z + self.data[12];
        result.data[13] = self.data[1] * v.x + self.data[5] * v.y + self.data[9] * v.z + self.data[13];
        result.data[14] = self.data[2] * v.x + self.data[6] * v.y + self.data[10] * v.z + self.data[14];
        result.data[15] = self.data[3] * v.x + self.data[7] * v.y + self.data[11] * v.z + self.data[15];
        return result;
    }

    pub fn scale(self: Mat4, v: Vec3) Mat4 {
        var result = self;
        result.data[0] *= v.x;
        result.data[1] *= v.x;
        result.data[2] *= v.x;
        result.data[3] *= v.x;
        result.data[4] *= v.y;
        result.data[5] *= v.y;
        result.data[6] *= v.y;
        result.data[7] *= v.y;
        result.data[8] *= v.z;
        result.data[9] *= v.z;
        result.data[10] *= v.z;
        result.data[11] *= v.z;
        return result;
    }

    pub fn rotate(self: Mat4, angle: f32, axis: Vec3) Mat4 {
        const normalized_axis = axis.normalize();
        const x = normalized_axis.x;
        const y = normalized_axis.y;
        const z = normalized_axis.z;
        const sin_theta = @sin(angle * DEG2RAD);
        const cos_theta = @cos(angle * DEG2RAD);
        const one_minus_cos = 1.0 - cos_theta;

        const rotation = Mat4{
            .data = .{
                // Row 1
                cos_theta + x * x * one_minus_cos,
                x * y * one_minus_cos + z * sin_theta,
                x * z * one_minus_cos - y * sin_theta,
                0,
                // Row 2
                y * x * one_minus_cos - z * sin_theta,
                cos_theta + y * y * one_minus_cos,
                y * z * one_minus_cos + x * sin_theta,
                0,
                // Row 3
                z * x * one_minus_cos + y * sin_theta,
                z * y * one_minus_cos - x * sin_theta,
                cos_theta + z * z * one_minus_cos,
                0,
                // Row 4
                0,
                0,
                0,
                1,
            },
        };

        return self.mul(rotation);
    }

    pub fn perspective(fov: f32, aspect: f32, near: f32, far: f32) Mat4 {
        var result = Mat4.identity();
        const f = 1.0 / @tan(fov * DEG2RAD * 0.5);

        result.data[0] = f / aspect;
        result.data[5] = f;
        result.data[10] = (far + near) / (near - far);
        result.data[11] = -1;
        result.data[14] = (2 * far * near) / (near - far);
        result.data[15] = 0;

        return result;
    }

    pub fn ortho(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) Mat4 {
        var result = Mat4.identity();

        result.data[0] = 2 / (right - left);
        result.data[5] = 2 / (top - bottom);
        result.data[10] = -2 / (far - near);
        result.data[12] = -(right + left) / (right - left);
        result.data[13] = -(top + bottom) / (top - bottom);
        result.data[14] = -(far + near) / (far - near);

        return result;
    }

    pub fn lookAt(eye: Vec3, target: Vec3, up: Vec3) Mat4 {
        const z = eye.sub(target).normalize();
        const x = up.cross(z).normalize();
        const y = z.cross(x);

        return Mat4{ .data = .{
            x.x,         y.x,         z.x,         0,
            x.y,         y.y,         z.y,         0,
            x.z,         y.z,         z.z,         0,
            -x.dot(eye), -y.dot(eye), -z.dot(eye), 1,
        } };
    }
};

// Utility functions
pub fn lerp(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

pub fn clamp(value: f32, min: f32, max: f32) f32 {
    return @min(@max(value, min), max);
}

// Angle conversion utilities
pub fn toRadians(degrees: f32) f32 {
    return degrees * DEG2RAD;
}

pub fn toDegrees(radians: f32) f32 {
    return radians * RAD2DEG;
}

// Quaternion type for 3D rotations
pub const Quaternion = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn identity() Quaternion {
        return .{ .x = 0, .y = 0, .z = 0, .w = 1 };
    }

    pub fn fromAxisAngle(axis: Vec3, angle: f32) Quaternion {
        const half_angle = angle * 0.5 * DEG2RAD;
        const sin_half = @sin(half_angle);
        const normalized_axis = axis.normalize();

        return .{
            .x = normalized_axis.x * sin_half,
            .y = normalized_axis.y * sin_half,
            .z = normalized_axis.z * sin_half,
            .w = @cos(half_angle),
        };
    }

    pub fn mul(self: Quaternion, other: Quaternion) Quaternion {
        return .{
            .x = self.w * other.x + self.x * other.w + self.y * other.z - self.z * other.y,
            .y = self.w * other.y + self.y * other.w + self.z * other.x - self.x * other.z,
            .z = self.w * other.z + self.z * other.w + self.x * other.y - self.y * other.x,
            .w = self.w * other.w - self.x * other.x - self.y * other.y - self.z * other.z,
        };
    }

    pub fn toMat4(self: Quaternion) Mat4 {
        const x2 = self.x * self.x;
        const y2 = self.y * self.y;
        const z2 = self.z * self.z;
        const xy = self.x * self.y;
        const xz = self.x * self.z;
        const yz = self.y * self.z;
        const wx = self.w * self.x;
        const wy = self.w * self.y;
        const wz = self.w * self.z;

        return Mat4{ .data = .{
            1 - 2 * (y2 + z2), 2 * (xy - wz),     2 * (xz + wy),     0,
            2 * (xy + wz),     1 - 2 * (x2 + z2), 2 * (yz - wx),     0,
            2 * (xz - wy),     2 * (yz + wx),     1 - 2 * (x2 + y2), 0,
            0,                 0,                 0,                 1,
        } };
    }

    pub fn normalize(self: Quaternion) Quaternion {
        const len = @sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w);
        if (len > EPSILON) {
            const inv_len = 1.0 / len;
            return .{
                .x = self.x * inv_len,
                .y = self.y * inv_len,
                .z = self.z * inv_len,
                .w = self.w * inv_len,
            };
        }
        return self;
    }
};
