// math/math.zig
pub const Vec2 = [2]f32;
pub const Vec3 = [3]f32;
pub const Vec4 = [4]f32;
pub const Mat4 = [16]f32;




// ==== CAMERA FUNTIONS ==== \\

pub fn lookAt(eye: Vec3, target: Vec3, up: Vec3) Mat4 {
    const z = normalize(sub(eye, target));
    const x = normalize(cross(up, z));
    const y = cross(z, x);

    return .{
        x[0],  x[1],  x[2],  0,
        y[0],  y[1],  y[2],  0,
        z[0],  z[1],  z[2],  0,
        -dot(x, eye), -dot(y, eye), -dot(z, eye), 1,
    };
}

pub fn perspective(fov_y: f32, aspect: f32, near: f32, far: f32) Mat4 {
    const f = 1.0 / @tan(fov_y / 2.0);
    const nf = 1.0 / (near - far);

    return .{
        f / aspect, 0,   0,                        0,
        0,          f,   0,                        0,
        0,          0,   (far + near) * nf,        -1,
        0,          0,   2 * far * near * nf,      0,
    };
}

pub fn ortho(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) Mat4 {
    const lr = 1.0 / (left - right);
    const bt = 1.0 / (bottom - top);
    const nf = 1.0 / (near - far);

    return .{
        -2 * lr,  0,      0,      0,
        0,        -2 * bt,0,      0,
        0,        0,      2 * nf, 0,
        (left + right) * lr,
        (top + bottom) * bt,
        (far + near) * nf,
        1,
    };
}


// ==== VECOTR OPPERATIONS ==== \\

pub fn normalize(v: Vec3) Vec3 {
    const len = @sqrt(dot(v, v));
    return .{v[0]/len, v[1]/len, v[2]/len};
}

pub fn sub(a: Vec3, b: Vec3) Vec3 {
    return .{a[0]-b[0], a[1]-b[1], a[2]-b[2]};
}

pub fn cross(a: Vec3, b: Vec3) Vec3 {
    return .{
        a[1]*b[2] - a[2]*b[1],
        a[2]*b[0] - a[0]*b[2],
        a[0]*b[1] - a[1]*b[0],
    };
}

pub fn dot(a: Vec3, b: Vec3) f32 {
    return a[0]*b[0] + a[1]*b[1] + a[2]*b[2];
}

pub fn multiplyMatrices(a: [16]f32, b: [16]f32) [16]f32 {
    var result: [16]f32 = undefined;

    for (0..4) |row| {
        for (0..4) |col| {
            var sum: f32 = 0.0;
            for (0..4) |i| {
                sum += a[row * 4 + i] * b[i * 4 + col];
            }
            result[row * 4 + col] = sum;
        }
    }

    return result;
}

pub const identity_mat4: Mat4 = .{
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
};
