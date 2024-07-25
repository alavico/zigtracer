const std = @import("std");
const hittable = @import("hittable.zig");
const Hittable = hittable.Hittable;
const HitRecord = hittable.HitRecord;
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec.zig").Vec3;
const utils = @import("utils.zig");
const Interval = @import("interval.zig").Interval;

const INFINITY = std.math.inf(f32);

pub const Camera = struct {
    image_height: u32,
    image_width: u32,
    aspect_ratio: f32,

    center: Vec3(f32),
    pixel_delta_u: Vec3(f32),
    pixel_delta_v: Vec3(f32),
    pixel00_loc: Vec3(f32),

    //camera basis vectors
    u: Vec3(f32),
    v: Vec3(f32),
    w: Vec3(f32),

    //virtual bokeh
    defocus_angle: f32,
    focus_dist: f32,
    defocus_disk_u: Vec3(f32),
    defocus_disk_v: Vec3(f32),

    //defaults. not sure this is really doing anything rn
    max_depth: u32 = 10,
    vfov: f32 = 90,
    look_from: Vec3(f32) = Vec3(f32).init(0, 0, 0),
    look_at: Vec3(f32) = Vec3(f32).init(0, 0, -1),
    v_up: Vec3(f32) = Vec3(f32).init(0, 1, 0),

    const samples_per_pixel: u32 = 20;
    const pixel_samples_scale: f32 = 1.0 / @as(f32, @floatFromInt(samples_per_pixel));

    //TODO refactor to make it better with default width, ar, depth?
    pub fn init(
        image_width: u32,
        aspect_ratio: f32,
        max_depth: u32,
        vfov: f32,
        look_from: Vec3(f32),
        look_at: Vec3(f32),
        v_up: Vec3(f32),
        defocus_angle: f32,
        focus_dist: f32,
    ) Camera {
        const image_height = @as(u32, @intFromFloat(@as(f32, @floatFromInt(image_width)) / aspect_ratio));

        const center = look_from;

        // Calc viewport
        const theta = std.math.degreesToRadians(vfov);
        const h = @tan(theta / 2);
        const viewport_height: f32 = 2 * h * focus_dist;
        const viewport_width: f32 = viewport_height * (@as(f32, @floatFromInt(image_width)) / @as(f32, @floatFromInt(image_height)));

        // Calc the u,v,w unit basis vectors for camera coord frame
        const w = look_from.subtract(look_at).unitVector();
        const u = v_up.cross(w).unitVector();
        const v = w.cross(u);

        // Calc viewport vectors
        const viewport_u = u.mult(viewport_width);
        const viewport_v = v.negative().mult(viewport_height);

        const pixel_delta_u = viewport_u.divide(@as(f32, @floatFromInt(image_width)));
        const pixel_delta_v = viewport_v.divide(@as(f32, @floatFromInt(image_height)));

        const viewport_upper_left = center.subtract(w.mult(focus_dist)).subtract(viewport_u.divide(2)).subtract(viewport_v.divide(2));

        const defocus_radius: f32 = focus_dist * @tan(std.math.degreesToRadians(defocus_angle / 2));
        return .{
            .image_height = image_height,
            .image_width = image_width,
            .aspect_ratio = aspect_ratio,
            .center = center,
            .pixel_delta_u = viewport_u.divide(@as(f32, @floatFromInt(image_width))),
            .pixel_delta_v = viewport_v.divide(@as(f32, @floatFromInt(image_height))),
            .pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).mult(0.5)),
            .u = u,
            .v = v,
            .w = w,
            .max_depth = max_depth,
            .vfov = vfov,
            .look_at = look_at,
            .look_from = look_from,
            .v_up = v_up,
            .defocus_angle = defocus_angle,
            .focus_dist = focus_dist,
            .defocus_disk_u = u.mult(defocus_radius),
            .defocus_disk_v = v.mult(defocus_radius),
        };
    }

    pub fn render(self: *const Camera, world: *std.ArrayList(Hittable), writer: *std.io.AnyWriter) anyerror!void {
        const w = writer.*;
        try w.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });
        for (0..self.image_height) |j| {
            // add buffer here to make writing faster?
            for (0..self.image_width) |i| {
                var pixel_color = Vec3(f32).init(0, 0, 0);
                for (0..samples_per_pixel) |_| {
                    const ray = self.*.getRay(@intCast(i), @intCast(j));
                    pixel_color = pixel_color.add(rayColor(&ray, self.max_depth, world));
                }
                const pixel_bytes = utils.colorHelper(pixel_color.mult(pixel_samples_scale));
                try writer.print("{d} {d} {d}\n", .{ pixel_bytes.x, pixel_bytes.y, pixel_bytes.z });
            }
        }
    }

    fn getRay(self: *const Camera, i: u32, j: u32) Ray {
        //get ray originating at the defocus disk and directed at random point sampled from i,j
        const offset = sampleSquare();
        const offset_x: f32 = @as(f32, @floatFromInt(i)) + offset.x;
        const offset_y: f32 = @as(f32, @floatFromInt(j)) + offset.y;
        const pixel_sample = self.pixel00_loc.add(self.pixel_delta_u.mult(offset_x))
            .add(self.pixel_delta_v.mult(offset_y));
        const ray_origin = if (self.defocus_angle <= 0) self.center else self.defocusDiskSample();
        const ray_direction = pixel_sample.subtract(ray_origin);

        return Ray.init(ray_origin, ray_direction);
    }

    fn rayColor(ray: *const Ray, depth: u32, world: *std.ArrayList(Hittable)) Vec3(f32) {
        if (depth <= 0) {
            return Vec3(f32).init(0, 0, 0);
        }
        const interval = Interval{ .min = 0.001, .max = INFINITY };
        var hit_record = HitRecord{ .point = undefined, .normal = undefined, .t = undefined, .material = undefined };

        if (getClosestHit(world, ray, interval, &hit_record)) {
            var scattered: Ray = undefined;
            var attenuation: Vec3(f32) = undefined;
            if (hit_record.material.*.scatter(ray, &hit_record, &attenuation, &scattered)) {
                return attenuation.multElem(rayColor(&scattered, depth - 1, world));
            }
            return Vec3(f32).init(0, 0, 0);
        }
        const unit_dir: Vec3(f32) = ray.dir.unitVector();
        const alpha: f32 = 0.5 * (unit_dir.y + 1.0);
        const res_color = Vec3(f32).init(1, 1, 1);
        return res_color.mult(1 - alpha).add(Vec3(f32).init(0.5, 0.7, 1.0).mult(alpha));
    }

    fn getClosestHit(world: *std.ArrayList(Hittable), ray: *const Ray, interval: Interval, hit_record: *HitRecord) bool {
        var temp_record: HitRecord = undefined;
        var hit = false;
        var closest = interval.max;
        for (world.items) |item| {
            if (item.hit(ray, .{ .min = interval.min, .max = closest }, &temp_record)) {
                closest = temp_record.t;
                hit = true;
                @memcpy(std.mem.asBytes(hit_record), std.mem.asBytes(&temp_record));
            }
        }

        return hit;
    }

    fn sampleSquare() Vec3(f32) {
        const rand1 = utils.getRandomFloat() catch unreachable;
        const rand2 = utils.getRandomFloat() catch unreachable;
        return Vec3(f32).init(rand1 - 0.5, rand2 - 0.5, 0);
    }

    fn defocusDiskSample(self: *const Camera) Vec3(f32) {
        const p: Vec3(f32) = Vec3(f32).randomInUnitDisk();
        const offset = self.defocus_disk_u.mult(p.x).add(self.defocus_disk_v.mult(p.y));
        return self.center.add(offset);
    }
};
