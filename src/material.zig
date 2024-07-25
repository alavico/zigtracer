const std = @import("std");
const utils = @import("utils.zig");
const Ray = @import("ray.zig").Ray;
const HitRecord = @import("hittable.zig").HitRecord;
const Vec3 = @import("vec.zig").Vec3;

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    dialectric: Dialectric,

    pub fn scatter(self: Material, ray_in: *const Ray, hit_record: *const HitRecord, attenuation: *Vec3(f32), scattered: *Ray) bool {
        // switch (self) {
        //     .lambertian => {
        //         std.debug.print("lambertian albedo: \n", .{});
        //         self.lambertian.albedo.print();
        //     },
        //     .metal => {
        //         std.debug.print("metal albedo, fuzz: \n", .{});
        //         self.metal.albedo.print();
        //         std.debug.print("{d}\n", .{self.metal.fuzz});
        //     },
        //     .dialectric => {
        //         std.debug.print("glass: \n", .{});
        //         std.debug.print("{d}\n", .{self.dialectric.refraction_index});
        //     },
        // }
        switch (self) {
            inline else => |case| return case.scatter(ray_in, hit_record, attenuation, scattered),
        }
    }
};

pub const Lambertian = struct {
    albedo: Vec3(f32),

    pub fn init(albedo: Vec3(f32)) Lambertian {
        return .{ .albedo = albedo };
    }

    pub fn scatter(self: Lambertian, ray_in: *const Ray, hit_record: *const HitRecord, attenuation: *Vec3(f32), scattered: *Ray) bool {
        _ = ray_in;
        var scatter_direction = hit_record.normal.add(Vec3(f32).randomUnitVector());

        // catch degen scatters
        if (scatter_direction.nearZero()) scatter_direction = hit_record.normal;

        const ray = Ray.init(hit_record.point, scatter_direction);
        @memcpy(std.mem.asBytes(scattered), std.mem.asBytes(&ray));
        @memcpy(std.mem.asBytes(attenuation), std.mem.asBytes(&self.albedo));
        return true;
    }
};

pub const Metal = struct {
    albedo: Vec3(f32),
    fuzz: f32,

    pub fn init(albedo: Vec3(f32), fuzz: f32) Metal {
        return .{ .albedo = albedo, .fuzz = if (fuzz < 1) fuzz else 1 };
    }

    pub fn scatter(self: Metal, ray_in: *const Ray, hit_record: *const HitRecord, attenuation: *Vec3(f32), scattered: *Ray) bool {
        var reflected = ray_in.*.dir.reflect(hit_record.normal);
        reflected = reflected.unitVector().add(Vec3(f32).randomUnitVector().mult(self.fuzz));
        const ray = Ray.init(hit_record.point, reflected);
        @memcpy(std.mem.asBytes(scattered), std.mem.asBytes(&ray));
        @memcpy(std.mem.asBytes(attenuation), std.mem.asBytes(&self.albedo));
        return scattered.*.dir.dot(hit_record.normal) > 0;
    }
};

pub const Dialectric = struct {
    refraction_index: f32,

    pub fn init(refraction_index: f32) Dialectric {
        return .{ .refraction_index = refraction_index };
    }

    pub fn scatter(self: Dialectric, ray_in: *const Ray, hit_record: *const HitRecord, attenuation: *Vec3(f32), scattered: *Ray) bool {
        const ri = if (hit_record.front_face) 1.0 / self.refraction_index else self.refraction_index;
        const unit_direction = ray_in.*.dir.unitVector();
        const cos_theta = @min(unit_direction.negative().dot(hit_record.normal), 1.0);
        const sin_theta = @sqrt(1 - cos_theta * cos_theta);
        const cannot_refract = ri * sin_theta > 1;
        var ray_direction: Vec3(f32) = undefined;
        const rand_num = try utils.getRandomFloat();
        if (cannot_refract or reflectance(cos_theta, ri) > rand_num) {
            ray_direction = unit_direction.reflect(hit_record.normal);
        } else {
            ray_direction = unit_direction.refract(hit_record.normal, ri);
        }
        const ray = Ray.init(hit_record.point, ray_direction);
        @memcpy(std.mem.asBytes(scattered), std.mem.asBytes(&ray));
        @memcpy(std.mem.asBytes(attenuation), std.mem.asBytes(&Vec3(f32).init(1, 1, 1)));
        return true;
    }

    fn reflectance(cos: f32, refraction_index: f32) f32 {
        // use Schlick's approximation for reflectance
        var r0 = (1 - refraction_index) / (1 + refraction_index);
        r0 *= r0;
        return r0 + (1 - r0) * std.math.pow(f32, 1 - cos, 5);
    }
};
