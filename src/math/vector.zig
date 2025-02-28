const std = @import("std");


const VecError = error{InvalidType};

/// Vector with 2 components
pub fn Vec2(T: type) type {
    return struct {
        x: T = 0,
        y: T = 0,

        const Self = @This();


        // ============================================================
        // Public API: Creation Functions
        // ============================================================


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
            const val: f32 = switch (@typeInfo(T)) {
                .int =>             @as(f32, @floatFromInt(self.lengthSquared())),
                .comptime_int =>    @as(f32, @floatFromInt(self.lengthSquared())),
                .float =>           self.lengthSquared(),
                .comptime_float =>  self.lengthSquared(),
                else => return VecError.InvalidType,
            };
            return @sqrt(val);
        }

        pub fn lengthSquared(self: Self) T {
            return self.x * self.x + self.y * self.y;
        }
    };
}



/// Vector with 3 components
pub fn Vec3(T: type) type {
    return struct {
        x: T = 0,
        y: T = 0,
        z: T = 0,

        const Self = @This();


        // ============================================================
        // Public API: Creation Functions
        // ============================================================


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

        pub fn normalize(self: Self) Vec3(f32) {
            const len = self.length();
            return switch (@typeInfo(T)) {
                .int => .{
                    .x = @as(f32, @floatFromInt(self.x))/len,
                    .y = @as(f32, @floatFromInt(self.y))/len,
                    .z = @as(f32, @floatFromInt(self.z))/len,
                    },
                .comptime_int =>    .{
                    .x = @as(f32, @floatFromInt(self.x))/len,
                    .y = @as(f32, @floatFromInt(self.y))/len,
                    .z = @as(f32, @floatFromInt(self.z))/len,
                    },
                .float =>   .{
                    .x = self.x/len,
                    .y = self.y/len,
                    .z = self.z/len,
                    },
                .comptime_float =>  .{
                    .x = self.x/len,
                    .y = self.y/len,
                    .z = self.z/len,
                    },
                else => return VecError.InvalidType,
            };
        }

        pub fn inv(self: Self) Self {
            return switch (@typeInfo(T)) {
                .int => | int |             switch (int.signedness == @TypeOf(int.signedness).signed) {
                        true => .{
                            .x = -self.x,
                            .y = -self.y,
                            .z = -self.z,
                        },
                        false => return VecError.InvalidType,
                },
                // .comptime_int => Has no `Int` property to check signedness
                .float =>           .{.x = -self.x, .y = -self.y, .z = -self.z},
                .comptime_float =>  .{.x = -self.x, .y = -self.y, .z = -self.z},
                else => return VecError.InvalidType,
            };
        }

        /// For unsigned integer vectors might return error for negative values of cross product
        pub fn cross(self: Self, other: Self) Self {
            return .{
                .x = self.y * other.z - self.z * other.y,
                .y = self.z * other.x - self.x * other.z,
                .z = self.x * other.y - self.y * other.x,
            };
        }

        pub fn dot(self: Self, other: Self) T {
            return self.x * other.x + self.y * other.y + self.z * other.z;
        }

        pub fn length(self: Self) f32 {
            const val: f32 = switch (@typeInfo(T)) {
                .int =>             @as(f32, @floatFromInt(self.lengthSquared())),
                .comptime_int =>    @as(f32, @floatFromInt(self.lengthSquared())),
                .float =>           self.lengthSquared(),
                .comptime_float =>  self.lengthSquared(),
                else => return VecError.InvalidType,
            };
            return @sqrt(val);
        }

        pub fn lengthSquared(self: Self) T {
            return self.x * self.x + self.y * self.y + self.z * self.z;
        }

        // Add this new function
        pub fn scale(self: Self, scalar: f32) Vec3(f32) {
            return switch(@typeInfo(T)) {
                .int =>             .{
                    .x = @as(f32, @floatFromInt(self.x))*scalar,
                    .y = @as(f32, @floatFromInt(self.y))*scalar,
                    .z = @as(f32, @floatFromInt(self.z))*scalar,
                },
                .comptime_int =>    .{
                    .x = @as(f32, @floatFromInt(self.x))*scalar,
                    .y = @as(f32, @floatFromInt(self.y))*scalar,
                    .z = @as(f32, @floatFromInt(self.z))*scalar,
                },
                .float =>           .{
                    .x = self.x*scalar,
                    .y = self.y*scalar,
                    .z = self.z*scalar,
                },
                .comptime_float =>  .{
                    .x = self.x*scalar,
                    .y = self.y*scalar,
                    .z = self.z*scalar,
                },
                else => return VecError.InvalidType,
            };
        }
    };
}

/// Vector with 4 components
pub fn Vec4(T: type) type {
    return struct {
        x: T = 0,
        y: T = 0,
        z: T = 0,
        w: T = 0,

        const Self = @This();


        // ============================================================
        // Public API: Creation Functions
        // ============================================================

        /// Create a Vec4 from a Vec3 and a w component
        pub fn fromVec3(v3: Vec3(T), w: T) Self {
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

        pub fn normalize(self: Self) Vec4(f32) {
            const len = self.length();
            return switch (@typeInfo(T)) {
                .int => .{
                    .x = @as(f32, @floatFromInt(self.x))/len,
                    .y = @as(f32, @floatFromInt(self.y))/len,
                    .z = @as(f32, @floatFromInt(self.z))/len,
                    .w = @as(f32, @floatFromInt(self.w))/len,
                    },
                .comptime_int =>    .{
                    .x = @as(f32, @floatFromInt(self.x))/len,
                    .y = @as(f32, @floatFromInt(self.y))/len,
                    .z = @as(f32, @floatFromInt(self.z))/len,
                    .w = @as(f32, @floatFromInt(self.w))/len,
                    },
                .float =>   .{
                    .x = self.x/len,
                    .y = self.y/len,
                    .z = self.z/len,
                    .w = self.w/len,
                    },
                .comptime_float =>  .{
                    .x = self.x/len,
                    .y = self.y/len,
                    .z = self.z/len,
                    .w = self.w/len,
                    },
                else => return VecError.InvalidType,
            };
        }

        pub fn inv(self: Self) Self {
            return switch (@typeInfo(T)) {
                .int => | int |             switch (int.signedness == @TypeOf(int.signedness).signed) {
                        true => .{
                            .x = -self.x,
                            .y = -self.y,
                            .z = -self.z,
                            .w = -self.w,
                        },
                        false => return VecError.InvalidType,
                },
                // .comptime_int => Has no `Int` property to check signedness
                .float =>           .{.x = -self.x, .y = -self.y, .z = -self.z, .w = -self.w},
                .comptime_float =>  .{.x = -self.x, .y = -self.y, .z = -self.z, .w = -self.w},
                else => return VecError.InvalidType,
            };
        }

        pub fn dot(self: Self, other: Self) T {
            return self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w;
        }

        pub fn length(self: Self) f32 {
            const val: f32 = switch (@typeInfo(T)) {
                .int =>             @as(f32, @floatFromInt(self.lengthSquared())),
                .comptime_int =>    @as(f32, @floatFromInt(self.lengthSquared())),
                .float =>           self.lengthSquared(),
                .comptime_float =>  self.lengthSquared(),
                else => return VecError.InvalidType,
            };
            return @sqrt(val);
        }

        pub fn lengthSquared(self: Self) T {
            return self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w;
        }

        pub fn scale(self: Self, scalar: f32) Vec4(f32) {
            return switch(@typeInfo(T)) {
                .int =>             .{
                    .x = @as(f32, @floatFromInt(self.x))*scalar,
                    .y = @as(f32, @floatFromInt(self.y))*scalar,
                    .z = @as(f32, @floatFromInt(self.z))*scalar,
                    .w = @as(f32, @floatFromInt(self.w))*scalar,
                },
                .comptime_int =>    .{
                    .x = @as(f32, @floatFromInt(self.x))*scalar,
                    .y = @as(f32, @floatFromInt(self.y))*scalar,
                    .z = @as(f32, @floatFromInt(self.z))*scalar,
                    .w = @as(f32, @floatFromInt(self.w))*scalar,
                },
                .float =>           .{
                    .x = self.x*scalar,
                    .y = self.y*scalar,
                    .z = self.z*scalar,
                    .w = self.w*scalar,
                },
                .comptime_float =>  .{
                    .x = self.x*scalar,
                    .y = self.y*scalar,
                    .z = self.z*scalar,
                    .w = self.w*scalar,
                },
                else => return VecError.InvalidType,
            };
        }

        /// Get the Vec3 part of this Vec4
        pub fn xyz(self: Self) Vec3(T) {
            return Vec3(T){.x = self.x, .y = self.y, .z = self.z};
        }
    };
}