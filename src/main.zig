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
const utils = @import("utils.zig");

const Timer = std.time.Timer;

pub fn main() !void {
    var start = try Timer.start();
    const cwd = std.fs.cwd();
    const file = try cwd.createFile("render.ppm", .{ .read = true });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("LEAK\n", .{});
        }
    }

    var world = try std.ArrayList(Hittable).initCapacity(allocator, 100);
    defer world.deinit();

    var materials = try std.ArrayList(Material).initCapacity(allocator, 100);
    defer materials.deinit();

    // create materials and add to world list for big elements
    const material_ground = Material{ .lambertian = Lambertian.init(Vec3(f32).init(0.5, 0.5, 0.5)) };
    try materials.append(material_ground);
    try world.append(.{ .sphere = Sphere.init(Vec3(f32).init(0, -1000, 0), 1000, materials.items.len - 1) });

    const material_glass = Material{ .dialectric = Dialectric.init(1.5) };
    try materials.append(material_glass);
    try world.append(.{ .sphere = Sphere.init(Vec3(f32).init(0, 1, 0), 1.0, materials.items.len - 1) });

    const material_lambertian = Material{ .lambertian = Lambertian.init(Vec3(f32).init(0.4, 0.2, 0.1)) };
    try materials.append(material_lambertian);
    try world.append(.{ .sphere = Sphere.init(Vec3(f32).init(-4, 1, 0), 1.0, materials.items.len - 1) });

    const material_metal = Material{ .metal = Metal.init(Vec3(f32).init(0.7, 0.6, 0.5), 0.0) };
    try materials.append(material_metal);
    try world.append(.{ .sphere = Sphere.init(Vec3(f32).init(4, 1, 0), 1.0, materials.items.len - 1) });

    var a: i32 = -11;
    // add many objs
    while (a < 11) : (a += 1) {
        var b: i32 = -11;
        while (b < 11) : (b += 1) {
            const a_f32 = @as(f32, @floatFromInt(a));
            const b_f32 = @as(f32, @floatFromInt(b));
            const rand_mat = try utils.getRandomFloat();
            const rand_offset_x = try utils.getRandomFloat();
            const rand_offset_z = try utils.getRandomFloat();

            const center = Vec3(f32).init(a_f32 + 0.9 * rand_offset_x, 0.2, b_f32 + 0.9 * rand_offset_z);

            if (center.subtract(Vec3(f32).init(4, 0.2, 0)).length() > 0.9) {
                var material_sphere: Material = undefined;
                if (rand_mat < 0.8) {
                    // diffuse
                    const rand_color_1 = Vec3(f32).random();
                    const rand_color_2 = Vec3(f32).random();
                    const albedo = rand_color_1.multElem(rand_color_2);
                    material_sphere = .{ .lambertian = Lambertian.init(albedo) };
                } else if (rand_mat < 0.95) {
                    // metal
                    const albedo = Vec3(f32).randomRange(0.5, 1);
                    const fuzz = utils.getRandomFloatRange(0, 0.5);
                    material_sphere = .{ .metal = Metal.init(albedo, fuzz) };
                } else {
                    // glass
                    material_sphere = .{ .dialectric = Dialectric.init(1.5) };
                }
                try materials.append(material_sphere);
                try world.append(.{ .sphere = Sphere.init(center, 0.2, materials.items.len - 1) });
            }
        }
    }

    var writer = file.writer().any();

    // camera init
    const image_width = 1200;
    const aspect_ratio = 16.0 / 9.0;
    const max_depth = 50;

    const vfov = 20.0;
    const look_from = Vec3(f32).init(13, 2, 3);
    const look_at = Vec3(f32).init(0, 0, 0);
    const v_up = Vec3(f32).init(0, 1, 0);
    const defocus_angle = 0.6;
    const focus_dist = 10.0;

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

    try camera.render(&world, &materials, &writer);
    const run_time = start.lap();
    std.debug.print("Time to run: {d}s\n", .{run_time / std.time.ns_per_s});
}
