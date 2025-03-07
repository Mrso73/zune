#ifndef EIGEN_WRAPPER_H
#define EIGEN_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif




// ============================================================
// Public API: Vec2 Defenitions
// ============================================================

typedef struct {
    float x, y;
} Vec2f;

Vec2f vec2fNormalize(Vec2f v);
float vec2fLength(Vec2f v);
float vec2fLengthSquared(Vec2f v);
float vec2fDistance(Vec2f a, Vec2f b);




// ============================================================
// Public API: Vec3 Defenitions
// ============================================================

typedef struct {
    float x, y, z;
} Vec3f;


Vec3f vec3fAdd(Vec3f a, Vec3f b);
Vec3f vec3fSubtract(Vec3f a, Vec3f b);
Vec3f vec3fScale(Vec3f v, float scalar);
Vec3f vec3fCross(Vec3f a, Vec3f b);
Vec3f vec3fNormalize(Vec3f v);
float vec3fDot(Vec3f a, Vec3f b);
float vec3fLength(Vec3f v);
float vec3fLengthSquared(Vec3f v);
float vec3fDistance(Vec3f a, Vec3f b);

Vec3f vec3fSlerp(Vec3f a, Vec3f b, float t);




// ============================================================
// Public API: Vec4 Defenitions
// ============================================================

typedef struct {
    float x, y, z, w;
} Vec4f;

Vec4f vec4fAdd(Vec4f a, Vec4f b);
Vec4f vec4fSubtract(Vec4f a, Vec4f b);
Vec4f vec4fScale(Vec4f v, float scalar);
Vec4f vec4fNormalize(Vec4f v);
float vec4fDot(Vec4f a, Vec4f b);
float vec4fLength(Vec4f v);
float vec4fLengthSquared(Vec4f v);




// ============================================================
// Public API: Mat4 (Column-Major) Defenitions
// ============================================================

typedef struct {
    float data[16];
} Mat4f;

Mat4f mat4fIdentity();
Mat4f mat4fMultiply(Mat4f a, Mat4f b);

Mat4f mat4fLookAt(Vec3f eye, Vec3f center, Vec3f up);
Mat4f mat4fPerspective(float fov, float aspect, float near, float far);
Mat4f mat4fOrtho(float left, float right, float bottom, float top, float near, float far);
Vec3f mat4fTransformPoint(Mat4f mat, Vec3f point);
Vec3f mat4fTransformDirection(Mat4f mat, Vec3f dir);




#ifdef __cplusplus
}
#endif

#endif // EIGEN_WRAPPER_H