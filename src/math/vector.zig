const std = @import("std");

/// Vector with 2 components
pub const Vec2 = struct {
    x: f32 = 0,
    y: f32 = 0,

    const Self = @This();


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    pub fn new(x: f32, y: f32) Self {
        return .{ .x = x, .y = y };
    }

    pub fn zero() Self {
        return .{ .x = 0, .y = 0 };
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    pub fn add(self: Self, other: Self) Self {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn subtract(self: Self, other: Self) Self {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    pub fn inv(self: Self) Self {
        return .{
            .x = -self.x,
            .y = -self.y,
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
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    const Self = @This();


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    pub fn new(x: f32, y: f32, z: f32) Self {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn zero() Self {
        return .{ .x = 0, .y = 0, .z = 0 };
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

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

    pub fn inv(self: Self) Self {
        return .{
            .x = -self.x,
            .y = -self.y,
            .z = -self.z,
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

    // Add this new function
    pub fn scale(self: Self, scalar: f32) Self {
        return .{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
        };
    }
};


/// Vector with 4 components
pub const Vec4 = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    w: f32 = 0,

    const Self = @This();


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    pub fn new(x: f32, y: f32, z: f32, w: f32) Self {
        return .{ .x = x, .y = y, .z = z, .w = w };
    }

    pub fn zero() Self {
        return .{ .x = 0, .y = 0, .z = 0, .w = 0 };
    }

    /// Create a Vec4 from a Vec3 and a w component
    pub fn fromVec3(v3: Vec3, w: f32) Self {
        return .{ .x = v3.x, .y = v3.y, .z = v3.z, .w = w };
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    pub fn add(self: Self, other: Self) Self {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
            .w = self.w + other.w,
        };
    }

    pub fn subtract(self: Self, other: Self) Self {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
            .w = self.w - other.w,
        };
    }

    pub fn normalize(self: Self) Self {
        const len = self.length();
        return .{
            .x = self.x / len,
            .y = self.y / len,
            .z = self.z / len,
            .w = self.w / len,
        };
    }

    pub fn inv(self: Self) Self {
        return .{
            .x = -self.x,
            .y = -self.y,
            .z = -self.z,
            .w = -self.w,
        };
    }

    pub fn dot(self: Self, other: Self) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w;
    }

    pub fn length(self: Self) f32 {
        return @sqrt(self.lengthSquared());
    }

    pub fn lengthSquared(self: Self) f32 {
        return self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w;
    }

    pub fn scale(self: Self, scalar: f32) Self {
        return .{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
            .w = self.w * scalar,
        };
    }

    /// Get the Vec3 part of this Vec4
    pub fn xyz(self: Self) Vec3 {
        return Vec3.new(self.x, self.y, self.z);
    }
};