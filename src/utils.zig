const std = @import("std");
const Interval = @import("interval.zig").Interval;
const RndGen = std.rand.DefaultPrng;

const Vec3 = @import("vec.zig").Vec3;

fn linearToGamma(linear_component: f32) f32 {
    return @sqrt(linear_component);
}

pub fn colorHelper(color: Vec3(f32)) Vec3(u8) {
    const intensity = Interval{ .min = 0.0, .max = 0.999 };
    const r_f32 = linearToGamma(color.x);
    const g_f32 = linearToGamma(color.y);
    const b_f32 = linearToGamma(color.z);
    const r: u8 = @intFromFloat(intensity.clamp(r_f32) * 256);
    const g: u8 = @intFromFloat(intensity.clamp(g_f32) * 256);
    const b: u8 = @intFromFloat(intensity.clamp(b_f32) * 256);
    return Vec3(u8).init(r, g, b);
}

pub fn degreesToRadians(degrees: f32) f32 {
    return degrees * std.math.pi / 180.0;
}

pub fn getRandomFloat() !f32 {
    var seed: u64 = undefined;
    std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
    var prng = RndGen.init(seed);
    return prng.random().float(f32);
}

pub fn getRandomFloatRange(min: f32, max: f32) f32 {
    const n = try getRandomFloat();
    return min + (max - min) * n;
}
