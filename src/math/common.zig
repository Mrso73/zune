// math.zig
const std = @import("std");
const assert = std.debug.assert;

pub fn lerp(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

pub fn clamp(value: f32, min: f32, max: f32) f32 {
    return @min(@max(value, min), max);
}



