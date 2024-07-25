const Vec3 = @import("vec.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const Interval = @import("interval.zig").Interval;
const Material = @import("material.zig").Material;

pub const HitRecord = struct {
    point: Vec3(f32),
    normal: Vec3(f32),
    t: f32,
    material: *Material,
    front_face: bool = false,

    // note: outward norm must have unit length
    pub fn setFaceNormal(self: *HitRecord, ray: *const Ray, outward_norm: Vec3(f32)) void {
        self.front_face = ray.dir.dot(outward_norm) < 0.0;
        self.normal = if (self.front_face) outward_norm else outward_norm.negative();
    }
};

pub const Sphere = struct {
    center: Vec3(f32),
    radius: f32,
    material: *Material,

    pub fn init(center: Vec3(f32), radius: f32, materal: *Material) Sphere {
        //TODO init material pointer
        return .{ .center = center, .radius = @max(radius, 0), .material = materal };
    }

    pub fn hit(self: Sphere, ray: *const Ray, ray_t: Interval, hit_record: *HitRecord) bool {
        const orig_center_vec = self.center.subtract(ray.orig);
        const a: f32 = ray.dir.lengthSquared();
        const h: f32 = ray.dir.dot(orig_center_vec);
        const c: f32 = orig_center_vec.lengthSquared() - self.radius * self.radius;

        const discriminant = h * h - a * c;
        if (discriminant <= 0) {
            return false;
        } else {
            const sqrt_disc = @sqrt(discriminant);
            // find nearest root thats within t
            var root = (h - sqrt_disc) / a;
            if (!ray_t.surrounds(root)) {
                root = (h + sqrt_disc) / a;
                if (!ray_t.surrounds(root)) {
                    return false;
                }
            }
            hit_record.t = root;
            hit_record.point = ray.pointAt(hit_record.*.t);
            const outward_normal: Vec3(f32) = hit_record.*.point.subtract(self.center).divide(self.radius);
            hit_record.setFaceNormal(ray, outward_normal);
            hit_record.material = self.material;
            return true;
        }
    }
};

pub const Hittable = union(enum) {
    sphere: Sphere,

    pub fn hit(self: Hittable, ray: *const Ray, ray_t: Interval, hit_record: *HitRecord) bool {
        switch (self) {
            inline else => |case| return case.hit(ray, ray_t, hit_record),
        }
    }
};
