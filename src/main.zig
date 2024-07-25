const std = @import("std");
const Vec3 = @import("vec.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const Interval = @import("interval.zig").Interval;
const Camera = @import("camera.zig").Camera;
const hittable = @import("hittable.zig");
const Hittable = hittable.Hittable;
const Sphere = hittable.Sphere;
const mats = @import("material.zig");
const Material = mats.Material;
const Lambertian = mats.Lambertian;
const Metal = mats.Metal;
const Dialectric = mats.Dialectric;

pub fn main() !void {
    const cwd = std.fs.cwd();
    const file = try cwd.createFile("render.ppm", .{ .read = true });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var world = std.ArrayList(Hittable).init(allocator);
    defer world.deinit();

    var material_ground = Material{ .lambertian = Lambertian.init(Vec3(f32).init(0.8, 0.8, 0.0)) };
    var material_center = Material{ .lambertian = Lambertian.init(Vec3(f32).init(0.1, 0.2, 0.5)) };
    var material_left = Material{ .dialectric = Dialectric.init(1.50) };
    var material_bubble = Material{ .dialectric = Dialectric.init(1.0 / 1.50) };
    var materail_right = Material{ .metal = Metal.init(Vec3(f32).init(0.8, 0.6, 0.2), 1.0) };

    try world.append(.{ .sphere = Sphere.init(Vec3(f32).init(0, -100.5, -1), 100, &material_ground) });
    try world.append(.{ .sphere = Sphere.init(Vec3(f32).init(0, 0, -1.2), 0.5, &material_center) });
    try world.append(.{ .sphere = Sphere.init(Vec3(f32).init(-1.0, 0, -1.0), 0.5, &material_left) });
    try world.append(.{ .sphere = Sphere.init(Vec3(f32).init(-1.0, 0, -1.0), 0.4, &material_bubble) });
    try world.append(.{ .sphere = Sphere.init(Vec3(f32).init(1.0, 0, -1.0), 0.5, &materail_right) });

    var writer = file.writer().any();

    // camera init
    const image_width = 960;
    const aspect_ratio = 16.0 / 9.0;
    const max_depth = 50;
    const vfov = 20.0;
    const look_from = Vec3(f32).init(-2, 2, 1);
    const look_at = Vec3(f32).init(0, 0, -1);
    const v_up = Vec3(f32).init(0, 1, 0);
    const defocus_angle = 10.0;
    const focus_dist = 3.4;

    const camera = Camera.init(
        image_width,
        aspect_ratio,
        max_depth,
        vfov,
        look_from,
        look_at,
        v_up,
        defocus_angle,
        focus_dist,
    );

    try camera.render(&world, &writer);
}
