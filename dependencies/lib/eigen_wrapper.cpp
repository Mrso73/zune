#include <Eigen/Core>
#include <Eigen/Geometry>
#include <cstdint>

extern "C" {
    #include "Eigen/eigen_wrapper.h"    

    # define M_E		2.7182818284590452354	/* e */
    # define M_LOG2E	1.4426950408889634074	/* log_2 e */
    # define M_LOG10E	0.43429448190325182765	/* log_10 e */
    # define M_LN2		0.69314718055994530942	/* log_e 2 */
    # define M_LN10		2.30258509299404568402	/* log_e 10 */
    # define M_PI		3.14159265358979323846	/* pi */
    # define M_PI_2		1.57079632679489661923	/* pi/2 */
    # define M_PI_4		0.78539816339744830962	/* pi/4 */
    # define M_1_PI		0.31830988618379067154	/* 1/pi */
    # define M_2_PI		0.63661977236758134308	/* 2/pi */
    # define M_2_SQRTPI	1.12837916709551257390	/* 2/sqrt(pi) */
    # define M_SQRT2	1.41421356237309504880	/* sqrt(2) */
    # define M_SQRT1_2	0.70710678118654752440	/* 1/sqrt(2) */




    // ============================================================
    // Public API: Vec2 Implementations
    // ============================================================

    // Ghost - needed for vec2Distance
    Vec2f vec2fSubtract(Vec2f a, Vec2f b) {
        Eigen::Vector2f ea(a.x, a.y);
        Eigen::Vector2f eb(b.x, b.y);
        Eigen::Vector2f result = ea - eb;
        return {result.x(), result.y()};
    }

    Vec2f vec2fNormalize(Vec2f v) {
        Eigen::Vector2f ev(v.x, v.y);
        Eigen::Vector2f result = ev.normalized();
        return {result.x(), result.y()};
    }
    
    float vec2fLength(Vec2f v){
        Eigen::Vector2f ev(v.x, v.y);
        return ev.norm();
    }

    float vec2fLengthSquared(Vec2f v) {
        Eigen::Vector2f ev(v.x, v.y);
        return ev.squaredNorm();
    }

    float vec2fDistance(Vec2f a, Vec2f b) {
        return vec2fLength(vec2fSubtract(a, b));
    }




    // ============================================================
    // Public API: Vec3 Implementations
    // ============================================================
    
    Vec3f vec3fAdd(Vec3f a, Vec3f b) {
        Eigen::Vector3f ea(a.x, a.y, a.z);
        Eigen::Vector3f eb(b.x, b.y, b.z);
        Eigen::Vector3f result = ea + eb;
        return {result.x(), result.y(), result.z()};
    }
    
    Vec3f vec3fSubtract(Vec3f a, Vec3f b) {
        Eigen::Vector3f ea(a.x, a.y, a.z);
        Eigen::Vector3f eb(b.x, b.y, b.z);
        Eigen::Vector3f result = ea - eb;
        return {result.x(), result.y(), result.z()};
    }
    
    Vec3f vec3fScale(Vec3f v, float scalar) {
        Eigen::Vector3f ev(v.x, v.y, v.z);
        Eigen::Vector3f result = ev * scalar;
        return {result.x(), result.y(), result.z()};
    }
    
    Vec3f vec3fCross(Vec3f a, Vec3f b) {
        Eigen::Vector3f ea(a.x, a.y, a.z);
        Eigen::Vector3f eb(b.x, b.y, b.z);
        Eigen::Vector3f result = ea.cross(eb);
        return {result.x(), result.y(), result.z()};
    }

    Vec3f vec3fNormalize(Vec3f v) {
        Eigen::Vector3f ev(v.x, v.y, v.z);
        Eigen::Vector3f result = ev.normalized();
        return {result.x(), result.y(), result.z()};
    }

    float vec3fDot(Vec3f a, Vec3f b) {
        Eigen::Vector3f ea(a.x, a.y, a.z);
        Eigen::Vector3f eb(b.x, b.y, b.z);
        return ea.dot(eb);
    }
    
    float vec3fLength(Vec3f v) {
        Eigen::Vector3f ev(v.x, v.y, v.z);
        return ev.norm();
    }
    
    float vec3fLengthSquared(Vec3f v) {
        Eigen::Vector3f ev(v.x, v.y, v.z);
        return ev.squaredNorm();
    }

    float vec3fDistance(Vec3f a, Vec3f b) {
        return vec3fLength(vec3fSubtract(a, b));
    }


    
    Vec3f vec3fSlerp(Vec3f a, Vec3f b, float t) {
        // Convert to Eigen vectors
        Eigen::Vector3f va(a.x, a.y, a.z);
        Eigen::Vector3f vb(b.x, b.y, b.z);
        
        // Get the magnitudes of the input vectors
        float mag_a = va.norm();
        float mag_b = vb.norm();
        
        // Normalize the vectors
        Eigen::Vector3f va_norm = va.normalized();
        Eigen::Vector3f vb_norm = vb.normalized();
        
        // Calculate the dot product
        float dotp = va_norm.dot(vb_norm);
        dotp = std::min(std::max(dotp, -1.0f), 1.0f); // Clamp to [-1, 1]
        
        // If vectors are nearly parallel, use linear interpolation
        if (dotp > 0.9995f) {
            // Linear interpolation for vectors and magnitudes
            Eigen::Vector3f result = va + t * (vb - va);
            return {result.x(), result.y(), result.z()};
        }
        
        // Calculate the angle between vectors
        float theta = std::acos(dotp) * t;
        
        // Create the orthogonal vector that's in the same plane
        Eigen::Vector3f relative = (vb_norm - va_norm * dotp).normalized();
        
        // Compute the result using the slerp formula
        Eigen::Vector3f result = va_norm * std::cos(theta) + relative * std::sin(theta);
        
        // Interpolate the magnitude
        float mag = mag_a + t * (mag_b - mag_a);
        result = result.normalized() * mag;
        
        // Return as C struct
        return {result.x(), result.y(), result.z()};
    }




    // ============================================================
    // Public API: Vec4 Implementations
    // ============================================================
    
    Vec4f vec4fAdd(Vec4f a, Vec4f b) {
        Eigen::Vector4f ea(a.x, a.y, a.z, a.w);
        Eigen::Vector4f eb(b.x, b.y, b.z, b.w);
        Eigen::Vector4f result = ea + eb;
        return {result.x(), result.y(), result.z(), result.w()};
    }
    
    Vec4f vec4fSubtract(Vec4f a, Vec4f b) {
        Eigen::Vector4f ea(a.x, a.y, a.z, a.w);
        Eigen::Vector4f eb(b.x, b.y, b.z, b.w);
        Eigen::Vector4f result = ea - eb;
        return {result.x(), result.y(), result.z(), result.w()};
    }
    
    Vec4f vec4fScale(Vec4f v, float scalar) {
        Eigen::Vector4f ev(v.x, v.y, v.z, v.w);
        Eigen::Vector4f result = ev * scalar;
        return {result.x(), result.y(), result.z(), result.w()};
    }

    Vec4f vec4fNormalize(Vec4f v) {
        Eigen::Vector4f ev(v.x, v.y, v.z, v.w);
        Eigen::Vector4f result = ev.normalized();
        return {result.x(), result.y(), result.z(), result.w()};
    }

    float vec4fDot(Vec4f a, Vec4f b) {
        Eigen::Vector4f ea(a.x, a.y, a.z, a.w);
        Eigen::Vector4f eb(b.x, b.y, b.z, b.w);
        return ea.dot(eb);
    }
    
    float vec4fLength(Vec4f v) {
        Eigen::Vector4f ev(v.x, v.y, v.z, v.w);
        return ev.norm();
    }
    
    float vec4fLengthSquared(Vec4f v) {
        Eigen::Vector4f ev(v.x, v.y, v.z, v.w);
        return ev.squaredNorm();
    }




    // ============================================================
    // Public API: Mat4 Implementations
    // ============================================================

    Mat4f mat4fIdentity() {
        Eigen::Matrix4f m = Eigen::Matrix4f::Identity();
        Mat4f result;
        std::memcpy(result.data, m.data(), 16 * sizeof(float)); // Copy the data
        return result;
    }
    
    Mat4f mat4fMultiply(Mat4f a, Mat4f b) {
        Eigen::Map<Eigen::Matrix4f> ea(a.data);  // Map the data directly
        Eigen::Map<Eigen::Matrix4f> eb(b.data);
        Eigen::Matrix4f result_eigen = ea * eb;
        Mat4f result;
        std::memcpy(result.data, result_eigen.data(), 16 * sizeof(float));
        return result;
    }

    Mat4f mat4fLookAt(Vec3f eye, Vec3f center, Vec3f up) {
        // Create Eigen vectors directly from Vec3f data
        Eigen::Map<const Eigen::Vector3f> eyeVec(&eye.x);
        Eigen::Map<const Eigen::Vector3f> centerVec(&center.x);
        Eigen::Map<const Eigen::Vector3f> upVec(&up.x);
        
        // Compute basis vectors
        Eigen::Vector3f f = (centerVec - eyeVec).normalized();  // forward
        Eigen::Vector3f s = f.cross(upVec).normalized();        // right
        Eigen::Vector3f u = s.cross(f);                         // up
        
        // Create the result matrix directly
        Mat4f result = mat4fIdentity();
        
        // Fill in the rotation part (sum black magic shit)
        result.data[0] = s.x();  
        result.data[1] = u.x();  
        result.data[2] = -f.x();  

        result.data[4] = s.y();
        result.data[5] = u.y();
        result.data[6] = -f.y();

        result.data[8] = s.z();  
        result.data[9] = u.z();  
        result.data[10] = -f.z();
        
        // Fill in the translation part
        result.data[12] = -s.dot(eyeVec);
        result.data[13] = -u.dot(eyeVec);
        result.data[14] = f.dot(eyeVec);
        
        return result;
    }

    Mat4f mat4fPerspective(float fov, float aspect, float near, float far) {
        Eigen::Matrix4f result = Eigen::Matrix4f::Identity();
        
        // Calculate perspective matrix
        float tanHalfFov = tan(fov / 2.0f);
        float range = far - near;
        
        // Zero out the matrix first
        result.setZero();
        
        // Set perspective transformation values for column-major
        result(0, 0) = 1.0f / (aspect * tanHalfFov);
        result(1, 1) = 1.0f / tanHalfFov;
        result(2, 2) = -(far + near) / range;
        result(3, 2) = -1.0f;
        result(2, 3) = -(2.0f * far * near) / range;
        result(3, 3) = 0.0f;
    
        // Convert to our format (also column-major)
        Mat4f mat;
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                // Direct copy without transposition since column-major
                mat.data[j * 4 + i] = result(i, j);
            }
        }
    
        return mat;
    }

    // Orthographic projection matrix
    Mat4f mat4fOrtho(float left, float right, float bottom, float top, float near, float far) {
        Eigen::Matrix4f result = Eigen::Matrix4f::Identity();
        
        float width = right - left;
        float height = top - bottom;
        float depth = far - near;
        
        result(0, 0) = 2.0f / width;
        result(1, 1) = 2.0f / height;
        result(2, 2) = -2.0f / depth;
        result(3, 0) = -(right + left) / width;
        result(3, 1) = -(top + bottom) / height;
        result(3, 2) = -(far + near) / depth;
        
        // Convert to our format
        Mat4f mat;
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                mat.data[i * 4 + j] = result(j, i);
            }
        }
        return mat;
    }

    // Transform a point by a matrix
    Vec3f mat4fTransformPoint(Mat4f mat, Vec3f point) {
        // Create Eigen matrix from our matrix format
        Eigen::Matrix4f matrix;
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                matrix(j, i) = mat.data[i * 4 + j];
            }
        }
        
        // Create Eigen vector and extend to homogeneous coordinates
        Eigen::Vector4f vec(point.x, point.y, point.z, 1.0f);
        
        // Transform
        Eigen::Vector4f result = matrix * vec;
        
        // Perspective division if needed
        if (result(3) != 1.0f && result(3) != 0.0f) {
            result = result / result(3);
        }
        
        // Return result as our vector type
        Vec3f returnVec;
        returnVec.x = result(0);
        returnVec.y = result(1);
        returnVec.z = result(2);
        return returnVec;
    }

    // Transform a direction by a matrix
    Vec3f mat4fTransformDirection(Mat4f mat, Vec3f dir) {
        // Create Eigen matrix from our matrix format
        Eigen::Matrix4f matrix;
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                matrix(j, i) = mat.data[i * 4 + j];
            }
        }
        
        // Create Eigen vector with w=0 for direction
        Eigen::Vector4f vec(dir.x, dir.y, dir.z, 0.0f);
        
        // Transform
        Eigen::Vector4f result = matrix * vec;
        
        // Return result as our vector type
        Vec3f returnVec;
        returnVec.x = result(0);
        returnVec.y = result(1);
        returnVec.z = result(2);
        return returnVec;
    }
}