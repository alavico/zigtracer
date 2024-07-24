const std = @import("std");
const Vec3 = @import("vec.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const Interval = @import("interval.zig").Interval;
const Camera = @import("camera.zig").Camera;
const hittable = @import("hittable.zig");
const Hittable = hittable.Hittable;
const Sphere = hittable.Sphere;

pub fn main() !void {
    const cwd = std.fs.cwd();
    const file = try cwd.createFile("render.ppm", .{ .read = true });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var world = std.ArrayList(Hittable).init(allocator);
    defer world.deinit();

    try world.append(.{ .sphere = Sphere.init(Vec3(f32).init(0, 0, -1), 0.5) });
    try world.append(.{ .sphere = Sphere.init(Vec3(f32).init(0, -100.5, -1), 100) });

    var writer = file.writer().any();
    const image_width = 96;
    const aspect_ratio = 16.0 / 9.0;
    const camera = Camera.init(image_width, aspect_ratio);
    try camera.render(&world, &writer);
}
