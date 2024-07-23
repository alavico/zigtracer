const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
pub const Ray = struct {
    orig: Vec3(f32),
    dir: Vec3(f32),

    pub fn init(origin: Vec3(f32), direction: Vec3(f32)) Ray {
        return .{ .orig = origin, .dir = direction };
    }

    pub fn pointAt(self: Ray, t: f32) Vec3(f32) {
        return self.orig.add(self.dir.mult(t));
    }
};
