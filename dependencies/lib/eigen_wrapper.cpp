#include <Eigen/Dense>
#include <cstdint>

extern "C" {
    // Matrix operations
    void eigen_mat4_inverse(const float* in, float* out) {
        Eigen::Map<const Eigen::Matrix4f> inMat(in);
        Eigen::Map<Eigen::Matrix4f> outMat(out);
        outMat = inMat.inverse();
    }
    
    void eigen_mat4_multiply(const float* a, const float* b, float* out) {
        Eigen::Map<const Eigen::Matrix4f> matA(a);
        Eigen::Map<const Eigen::Matrix4f> matB(b);
        Eigen::Map<Eigen::Matrix4f> outMat(out);
        outMat = matA * matB;
    }
    
    // Vector operations
    void eigen_vec4_multiply(const float* mat, const float* vec, float* out) {
        Eigen::Map<const Eigen::Matrix4f> matrix(mat);
        Eigen::Map<const Eigen::Vector4f> vector(vec);
        Eigen::Map<Eigen::Vector4f> result(out);
        result = matrix * vector;
    }
    
    // Add more functions as needed
}