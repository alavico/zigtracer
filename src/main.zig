const std = @import("std");
const Vec3 = @import("vec.zig").Vec3;
const Ray = @import("ray.zig").Ray;

pub fn main() !void {
    const cwd = std.fs.cwd();
    const file = try cwd.createFile("render.ppm", .{ .read = true });
    defer file.close();

    const writer = file.writer();
    try renderPpm(&writer);

    const vec_test = Vec3(u8).init(1, 1, 1);
    vec_test.print();
}

pub fn hitSphere(center: Vec3(f32), radius: f32, ray: *const Ray) f32 {
    const oc = center.subtract(ray.orig);
    const a: f32 = ray.dir.dot(ray.dir);
    const b: f32 = ray.dir.dot(oc) * -2.0;
    const c: f32 = oc.dot(oc) - (radius * radius);
    const discriminant = b * b - 4 * a * c;
    if (discriminant <= 0) {
        return -1.0;
    } else {
        return (-b - @sqrt(discriminant)) / (2.0 * a);
    }
}

pub fn colorHelper(color: Vec3(f32)) Vec3(u8) {
    const r: u8 = @intFromFloat(color.x * 255.99);
    const g: u8 = @intFromFloat(color.y * 255.99);
    const b: u8 = @intFromFloat(color.z * 255.99);
    return Vec3(u8).init(r, g, b);
}

pub fn rayColor(ray: *const Ray) Vec3(f32) {
    const t = hitSphere(Vec3(f32).init(0, 0, -1), 0.5, ray);
    if (t > 0.0) {
        const norm = ray.pointAt(t).subtract(Vec3(f32).init(0, 0, -1)).unitVector();
        return norm.add(Vec3(f32).init(1, 1, 1)).mult(0.5);
    }
    const unit_dir: Vec3(f32) = ray.dir.unitVector();
    const alpha: f32 = 0.5 * (unit_dir.y + 1.0);
    const res_color = Vec3(f32).init(1, 1, 1);
    return res_color.mult(1 - alpha).add(Vec3(f32).init(0.5, 0.7, 1.0).mult(alpha));
}

pub fn renderPpm(writer: anytype) !void {
    const aspect_ratio: f32 = 16.0 / 9.0;
    const image_width = 960;
    const image_height = @as(u32, @intFromFloat(image_width / aspect_ratio));

    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * (@as(f32, @floatFromInt(image_width)) / @as(f32, @floatFromInt(image_height)));

    const camera_center = Vec3(f32).init(0, 0, 0);

    const viewport_u = Vec3(f32).init(viewport_width, 0, 0);
    const viewport_v = Vec3(f32).init(0, -viewport_height, 0);
    const pixel_delta_u = viewport_u.divide(image_width);
    const pixel_delta_v = viewport_v.divide(image_height);

    const viewport_upper_left = camera_center.subtract(Vec3(f32).init(0, 0, focal_length)).subtract(viewport_u.divide(2)).subtract(viewport_v.divide(2));

    const pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).mult(0.5));
    const w = writer.*;
    try w.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        // add buffer here to make writing faster?
        for (0..image_width) |i| {
            const pixel_center = pixel00_loc.add(pixel_delta_u.mult(@floatFromInt(i)))
                .add(pixel_delta_v.mult(@floatFromInt(j)));
            const ray_direction = pixel_center.subtract(camera_center);
            const ray = Ray.init(camera_center, ray_direction);
            const ray_color = rayColor(&ray);
            const pixel_color = colorHelper(ray_color);
            try writer.print("{d} {d} {d}\n", .{ pixel_color.x, pixel_color.y, pixel_color.z });
        }
    }
}
