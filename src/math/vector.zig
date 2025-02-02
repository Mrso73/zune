const std = @import("std");

/// Vector with 2 components
pub const Vec2 = struct {
    x: f32,
    y: f32,

    const Self = @This();

    pub fn new(x: f32, y: f32) Self {
        return .{ .x = x, .y = y };
    }

    pub fn zero() Self {
        return .{ .x = 0, .y = 0 };
    }

    pub fn add(self: Self, other: Self) Self {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn length(self: Self) f32 {
        return @sqrt(self.lengthSquared());
    }

    pub fn lengthSquared(self: Self) f32 {
        return self.x * self.x + self.y * self.y;
    }
};



/// Vector with 3 components
pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    const Self = @This();

    pub fn new(x: f32, y: f32, z: f32) Self {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn zero() Self {
        return .{ .x = 0, .y = 0, .z = 0 };
    }

    pub fn add(self: Self, other: Self) Self {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    pub fn subtract(self: Self, other: Self) Self {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    pub fn normalize(self: Self) Self {
        const len = self.length();
        return .{
            .x = self.x / len,
            .y = self.y / len,
            .z = self.z / len,
        };
    }

    pub fn cross(self: Self, other: Self) Self {
        return .{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }

    pub fn dot(self: Self, other: Self) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn length(self: Self) f32 {
        return @sqrt(self.lengthSquared());
    }

    pub fn lengthSquared(self: Self) f32 {
        return self.x * self.x + self.y * self.y + self.z * self.z;
    }
};