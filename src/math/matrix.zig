//

const eigen = @cImport({
    @cInclude("Eigen/eigen_wrapper.h");
});

const eigen_interface = @import("eigen.zig");
const Vec3f = @import("vector.zig").Vec3f;

// ============================================================
// Public API: Mat4 Implementations
// ============================================================

pub const Mat4f = struct {  
    data: [16]f32,

    // Eigen-dependent functions - wrappers around C functions
    pub inline fn identity() Mat4f {
        return eigen_interface.fromEigenMat4f(eigen.mat4fIdentity());
    }
    
    /// Multiply two matrices to get a new one
    pub inline fn multiply(a: Mat4f, b: Mat4f) Mat4f {
        const eigen_a = eigen_interface.toEigenMat4f(a);
        const eigen_b = eigen_interface.toEigenMat4f(b);
        const result = eigen.mat4fMultiply(eigen_a, eigen_b);
        return eigen_interface.fromEigenMat4f(result);
    }

    /// Create a look-at view matrix
    /// Eye: The position of the camera
    /// Center: The point the camera is looking at
    /// Up: The up direction vector
    pub inline fn lookAt(eye: Vec3f, center: Vec3f, up: Vec3f) Mat4f {
        const eigen_eye = eigen_interface.toEigenVec3f(eye);
        const eigen_center = eigen_interface.toEigenVec3f(center);
        const eigen_up = eigen_interface.toEigenVec3f(up);
        const result = eigen.mat4fLookAt(eigen_eye, eigen_center, eigen_up);
        return eigen_interface.fromEigenMat4f(result);
    }
    
    /// Create a perspective projection matrix
    /// fov: Field of view in radians
    /// aspect: Aspect ratio (width / height)
    /// near: Distance to near plane
    /// far: Distance to far plane
    pub inline fn perspective(fov: f32, aspect: f32, near: f32, far: f32) Mat4f {
        const result = eigen.mat4fPerspective(fov, aspect, near, far);
        return eigen_interface.fromEigenMat4f(result);
    }
    
    /// Create an orthographic projection matrix
    /// left, right: Left and right boundaries
    /// bottom, top: Bottom and top boundaries
    /// near, far: Near and far plane distances
    pub inline fn ortho(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) Mat4f {
        const result = eigen.mat4fOrtho(left, right, bottom, top, near, far);
        return eigen_interface.fromEigenMat4f(result);
    }
    
    /// Transform a point by this matrix
    /// This performs perspective division if needed
    pub inline fn transformPoint(mat: Mat4f, point: Vec3f) Vec3f {
        const eigen_mat = eigen_interface.toEigenMat4f(mat);
        const eigen_point = eigen_interface.toEigenVec3f(point);
        const result = eigen.mat4fTransformPoint(eigen_mat, eigen_point);
        return eigen_interface.fromEigenVec3f(result);
    }
    
    /// Transform a direction vector by this matrix
    /// No perspective division is performed (w=0)
    pub inline fn transformDirection(mat: Mat4f, dir: Vec3f) Vec3f {
        const eigen_mat = eigen_interface.toEigenMat4f(mat);
        const eigen_dir = eigen_interface.toEigenVec3f(dir);
        const result = eigen.mat4fTransformDirection(eigen_mat, eigen_dir);
        return eigen_interface.fromEigenVec3f(result);
    }
};