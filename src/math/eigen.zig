// math/eigen.zig - eigen from and to conversion

const eigen = @cImport({
    @cInclude("Eigen/eigen_wrapper.h");
});

const Vec2f = @import("vector.zig").Vec2f;
const Vec3f = @import("vector.zig").Vec3f;
const Vec4f = @import("vector.zig").Vec4f;
const Mat4f = @import("matrix.zig").Mat4f;



// ============================================================
// Type conversion functions between Zig structs and C structs
// ============================================================

// Vec2f conversions
pub inline fn toEigenVec2f(v: Vec2f) eigen.Vec2f {
    return eigen.Vec2f{ .x = v.x, .y = v.y };
}

pub inline fn fromEigenVec2f(v: eigen.Vec2f) Vec2f {
    return Vec2f{ .x = v.x, .y = v.y };
}

// Vec3f conversions
pub inline fn toEigenVec3f(v: Vec3f) eigen.Vec3f {
    return eigen.Vec3f{ .x = v.x, .y = v.y, .z = v.z };
}

pub inline fn fromEigenVec3f(v: eigen.Vec3f) Vec3f {
    return Vec3f{ .x = v.x, .y = v.y, .z = v.z };
}

// Vec4f conversions
pub inline fn toEigenVec4f(v: Vec4f) eigen.Vec4f {
    return eigen.Vec4f{ .x = v.x, .y = v.y, .z = v.z, .w = v.w };
}

pub inline fn fromEigenVec4f(v: eigen.Vec4f) Vec4f {
    return Vec4f{ .x = v.x, .y = v.y, .z = v.z, .w = v.w };
}

// Mat4f conversions
pub inline fn toEigenMat4f(m: Mat4f) eigen.Mat4f {
    var result: eigen.Mat4f = undefined;
    @memcpy(&result.data, &m.data);
    return result;
}

pub inline fn fromEigenMat4f(m: eigen.Mat4f) Mat4f {
    var result: Mat4f = undefined;
    @memcpy(&result.data, &m.data);
    return result;
}