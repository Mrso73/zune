// math/vector.zig - vector functionalities

const eigen = @cImport({
    @cInclude("Eigen/eigen_wrapper.h");
});

const math = @import("std").math;
const eigen_interface = @import("eigen.zig");

const Mat4f = @import("matrix.zig").Mat4f;
const misc = @import("misc.zig");

// ============================================================
// Public API: Vec2 Implementations
// ============================================================

pub const Vec2f = struct {
    x: f32,
    y: f32,

    // Pure Zig implementations

    /// Create a Vec2f
    pub fn create(x: f32, y: f32) Vec2f {
        return Vec2f{ .x = x, .y = y };
    }

    /// Invert the Vec2f
    pub fn inv(v: Vec2f) Vec2f {
        return Vec2f{ .x = -v.x, .y = -v.y };
    }

    // Add two Vec2f's 
    pub fn add(a: Vec2f, b: Vec2f) Vec2f {
        return Vec2f{ .x = a.x + b.x, .y = a.y + b.y };
    }

    pub fn subtract(a: Vec2f, b: Vec2f) Vec2f {
        return Vec2f{ .x = a.x - b.x, .y = a.y - b.y };
    }

    pub fn scale(v: Vec2f, scalar: f32) Vec2f {
        return Vec2f{ .x = v.x * scalar, .y = v.y * scalar };
    }

    pub fn dot(a: Vec2f, b: Vec2f) f32 {
        return a.x * b.x + a.y * b.y;
    }

    /// Clamp Vec2f between min and max
    pub fn clamp(v: Vec2f, min: Vec2f, max: Vec2f) Vec2f {
        return Vec2f{
            .x = misc.clampf(v.x, min.x, max.x),
            .y = misc.clampf(v.y, min.y, max.y),
        };
    }

    // Lerp Vec2f between a and b using t
    pub fn lerp(a: Vec2f, b: Vec2f, t: f32) Vec2f {
        return Vec2f{
            .x = misc.lerpf(a.x, b.x, t),
            .y = misc.lerpf(a.y, b.y, t),
        };
    }
    



    // Eigen based functions - they benefit from its optimizations
    pub inline fn normalize(v: Vec2f) Vec2f {
        const eigen_v = eigen_interface.toEigenVec2f(v);
        const result = eigen.vec2fNormalize(eigen_v);
        return eigen_interface.fromEigenVec2f(result);
    }

    pub inline fn length(v: Vec2f) f32 {
        const eigen_v = eigen_interface.toEigenVec2f(v);
        return eigen.vec2fLength(eigen_v);
    }

    pub inline fn lengthSquared(v: Vec2f) f32 {
        const eigen_v = eigen_interface.toEigenVec2f(v);
        return eigen.vec2fLengthSquared(eigen_v);
    }
    
    pub inline fn distance(a: Vec2f, b: Vec2f) f32 {
        const eigen_a = eigen_interface.toEigenVec2f(a);
        const eigen_b = eigen_interface.toEigenVec2f(b);
        return eigen.vec2fDistance(eigen_a, eigen_b);
    }

    
};




// ============================================================
// Public API: Vec3 Implementations
// ============================================================

pub const Vec3f = struct {
    x: f32,
    y: f32,
    z: f32,

    // Pure Zig implementations
    pub fn create(x: f32, y: f32, z: f32) Vec3f {
        return Vec3f{ .x = x, .y = y, .z = z };
    }

    pub fn inv(v: Vec3f) Vec3f {
        return Vec3f{ .x = -v.x, .y = -v.y, .z = -v.z };
    }

    pub fn clamp(v: Vec3f, min: Vec3f, max: Vec3f) Vec3f {
        return .{
            .x = misc.clampf(v.x, min.x, max.x),
            .y = misc.clampf(v.y, min.y, max.y),
            .z = misc.clampf(v.z, min.z, max.z),
        };
    }

    pub fn lerp(a: Vec3f, b: Vec3f, t: f32) Vec3f {
        return .{
            .x = misc.lerpf(a.x, b.x, t),
            .y = misc.lerpf(a.y, b.y, t),
            .z = misc.lerpf(a.z, b.z, t),
        };
    }




    // Eigen based functions - they benefit from its optimizations
    pub inline fn add(a: Vec3f, b: Vec3f) Vec3f {
        const eigen_a = eigen_interface.toEigenVec3f(a);
        const eigen_b = eigen_interface.toEigenVec3f(b);
        const result = eigen.vec3fAdd(eigen_a, eigen_b);
        return eigen_interface.fromEigenVec3f(result);
    }

    pub inline fn subtract(a: Vec3f, b: Vec3f) Vec3f {
        const eigen_a = eigen_interface.toEigenVec3f(a);
        const eigen_b = eigen_interface.toEigenVec3f(b);
        const result = eigen.vec3fSubtract(eigen_a, eigen_b);
        return eigen_interface.fromEigenVec3f(result);
    }
    
    pub inline fn scale(v: Vec3f, scalar: f32) Vec3f {
        const eigen_v = eigen_interface.toEigenVec3f(v);
        const result = eigen.vec3fScale(eigen_v, scalar);
        return eigen_interface.fromEigenVec3f(result);
    }

    pub inline fn cross(a: Vec3f, b: Vec3f) Vec3f {
        const eigen_a = eigen_interface.toEigenVec3f(a);
        const eigen_b = eigen_interface.toEigenVec3f(b);
        const result = eigen.vec3fCross(eigen_a, eigen_b);
        return eigen_interface.fromEigenVec3f(result);
    }

    pub inline fn normalize(v: Vec3f) Vec3f {
        const eigen_v = eigen_interface.toEigenVec3f(v);
        const result = eigen.vec3fNormalize(eigen_v);
        return eigen_interface.fromEigenVec3f(result);
    }

    pub inline fn dot(a: Vec3f, b: Vec3f) f32 {
        const eigen_a = eigen_interface.toEigenVec3f(a);
        const eigen_b = eigen_interface.toEigenVec3f(b);
        return eigen.vec3fDot(eigen_a, eigen_b);
    }

    pub inline fn length(v: Vec3f) f32 {
        const eigen_v = eigen_interface.toEigenVec3f(v);
        return eigen.vec3fLength(eigen_v);
    }

    pub inline fn lengthSquared(v: Vec3f) f32 {
        const eigen_v = eigen_interface.toEigenVec3f(v);
        return eigen.vec3fLengthSquared(eigen_v);
    }

    pub inline fn distance(a: Vec3f, b: Vec3f) f32 {
        const eigen_a = eigen_interface.toEigenVec3f(a);
        const eigen_b = eigen_interface.toEigenVec3f(b);
        const diff = eigen.vec3fSubtract(eigen_a, eigen_b);
        return eigen.vec3fLength(diff);
    }

    // Dependent on a lot of Eigen function

    /// Function to perform spherical linear interpolation between two 3D vectors
    pub inline fn slerp(a: Vec3f, b: Vec3f, t: f32) Vec3f {
        const eigen_a = eigen_interface.toEigenVec3f(a);
        const eigen_b = eigen_interface.toEigenVec3f(b);
        const result = eigen.vec3fSlerp(eigen_a, eigen_b, t);
        return eigen_interface.fromEigenVec3f(result);
    }
};




// ============================================================
// Public API: Vec4 Implementations
// ============================================================

pub const Vec4f = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    // Pure Zig implementations
    pub fn create(x: f32, y: f32, z: f32, w: f32) Vec4f {
        return .{ .x = x, .y = y, .z = z, .w = w };
    }

    pub fn fromVec3(v: Vec3f, w: f32) Vec4f {
        return .{ .x = v.x, .y = v.y, .z = v.z, .w = w };
    }

    pub fn inv(v: Vec4f) Vec4f {
        return .{ .x = -v.x, .y = -v.y, .z = -v.z, .w = -v.w };
    }

    pub fn clamp(v: Vec4f, min: Vec4f, max: Vec4f) Vec4f {
        return .{
            .x = misc.clampf(v.x, min.x, max.x),
            .y = misc.clampf(v.y, min.y, max.y),
            .z = misc.clampf(v.z, min.z, max.z),
            .w = misc.clampf(v.w, min.w, max.w),
        };
    }

    pub fn lerp(a: Vec4f, b: Vec4f, t: f32) Vec4f {
        return .{
            .x = misc.lerpf(a.x, b.x, t),
            .y = misc.lerpf(a.y, b.y, t),
            .z = misc.lerpf(a.z, b.z, t),
            .w = misc.lerpf(a.w, b.w, t),
        };
    }

    pub fn xyz(v: Vec4f) Vec3f {
        return .{ .x = v.x, .y = v.y, .z = v.z };
    }




    // Eigen based functions - they benefit from its optimizations
    pub inline fn add(a: Vec4f, b: Vec4f) Vec4f {
        const eigen_a = eigen_interface.toEigenVec4f(a);
        const eigen_b = eigen_interface.toEigenVec4f(b);
        const result = eigen.vec4fAdd(eigen_a, eigen_b);
        return eigen_interface.fromEigenVec4f(result);
    }

    pub inline fn subtract(a: Vec4f, b: Vec4f) Vec4f {
        const eigen_a = eigen_interface.toEigenVec4f(a);
        const eigen_b = eigen_interface.toEigenVec4f(b);
        const result = eigen.vec4fSubtract(eigen_a, eigen_b);
        return eigen_interface.fromEigenVec4f(result);
    }

    pub inline fn scale(v: Vec4f, scalar: f32) Vec4f {
        const eigen_v = eigen_interface.toEigenVec4f(v);
        const result = eigen.vec4fScale(eigen_v, scalar);
        return eigen_interface.fromEigenVec4f(result);
    }

    pub inline fn normalize(v: Vec4f) Vec4f {
        const eigen_v = eigen_interface.toEigenVec4f(v);
        const result = eigen.vec4fNormalize(eigen_v);
        return eigen_interface.fromEigenVec4f(result);
    }

    pub inline fn dot(a: Vec4f, b: Vec4f) f32 {
        const eigen_a = eigen_interface.toEigenVec4f(a);
        const eigen_b = eigen_interface.toEigenVec4f(b);
        return eigen.vec4fDot(eigen_a, eigen_b);
    }

    pub inline fn length(v: Vec4f) f32 {
        const eigen_v = eigen_interface.toEigenVec4f(v);
        return eigen.vec4fLength(eigen_v);
    }

    pub inline fn lengthSquared(v: Vec4f) f32 {
        const eigen_v = eigen_interface.toEigenVec4f(v);
        return eigen.vec4fLengthSquared(eigen_v);
    }
};