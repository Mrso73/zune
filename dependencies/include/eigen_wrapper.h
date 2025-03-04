#ifndef EIGEN_WRAPPER_H
#define EIGEN_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Matrix operations
void eigen_mat4_inverse(const float* in, float* out);
void eigen_mat4_multiply(const float* a, const float* b, float* out);

// Vector operations
void eigen_vec4_multiply(const float* mat, const float* vec, float* out);

// Add more function declarations as needed

#ifdef __cplusplus
}
#endif

#endif // EIGEN_WRAPPER_H