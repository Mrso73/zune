// math/misc.zig - tings that don't go into the other files

pub fn clampf(v: f32, min: f32, max: f32) f32 {
    if (v < min) return min;
    if (v > max) return max;
    return v;
}

pub fn lerpf(a: f32, b: f32, t: f32) f32 {
    return a + t * (b - a);
}  

pub fn inverseLerpf(a: f32, b: f32, value: f32) f32 {
    if (@abs(b - a) < 1e-6) {
        return 0.0; // Avoid division by zero
    }
    return (value - a) / (b - a);
}

pub fn remapf(value: f32, inMin: f32, inMax: f32, outMin: f32, outMax: f32) f32 {
    const t = inverseLerpf(inMin, inMax, value);
    return lerpf(outMin, outMax, t);
}

pub fn smoothstepf(edge0: f32, edge1: f32, x: f32) f32 {
    // Clamp x to [0,1]
    const t = clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    // Evaluate polynomial: 3t² - 2t³
    return t * t * (3.0 - 2.0 * t);
}