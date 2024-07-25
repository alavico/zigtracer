const std = @import("std");
const utils = @import("utils.zig");

pub fn Vec3(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        const Self = @This();
        pub fn init(x: T, y: T, z: T) Self {
            return .{
                .x = x,
                .y = y,
                .z = z,
            };
        }

        pub fn print(self: Self) void {
            std.debug.print("x:{d} y:{d} z:{d}\n", .{ self.x, self.y, self.z });
        }

        pub fn add(self: Self, vec: Self) Self {
            return .{ .x = self.x + vec.x, .y = self.y + vec.y, .z = self.z + vec.z };
        }

        pub fn subtract(self: Self, vec: Self) Self {
            return .{ .x = self.x - vec.x, .y = self.y - vec.y, .z = self.z - vec.z };
        }

        pub fn negative(self: Self) Self {
            return .{
                .x = -1 * self.x,
                .y = -1 * self.y,
                .z = -1 * self.z,
            };
        }

        pub fn mult(self: Self, scalar: T) Self {
            return .{
                .x = self.x * scalar,
                .y = self.y * scalar,
                .z = self.z * scalar,
            };
        }

        // multiplies element wise with another vector
        pub fn multElem(self: Self, vec: Self) Self {
            return .{
                .x = self.x * vec.x,
                .y = self.y * vec.y,
                .z = self.z * vec.z,
            };
        }

        pub fn divide(self: Self, scalar: T) Self {
            return .{
                .x = self.x / scalar,
                .y = self.y / scalar,
                .z = self.z / scalar,
            };
        }

        pub fn length(self: Self) f32 {
            return @sqrt(self.lengthSquared());
        }

        pub fn dot(self: Self, vec: Self) f32 {
            return (self.x * vec.x + self.y * vec.y + self.z * vec.z);
        }

        pub fn cross(self: Self, vec: Self) Self {
            return .{
                .x = self.y * vec.z - self.z * vec.y,
                .y = self.z * vec.x - self.x * vec.z,
                .z = self.x * vec.y - self.y * vec.x,
            };
        }

        pub fn unitVector(self: Self) Self {
            return .{
                .x = self.x / self.length(),
                .y = self.y / self.length(),
                .z = self.z / self.length(),
            };
        }

        pub fn lengthSquared(self: Self) f32 {
            return self.x * self.x + self.y * self.y + self.z * self.z;
        }

        pub fn members(self: Self) [3]T {
            return .{ self.x, self.y, self.z };
        }

        pub fn random() Self {
            const x = try utils.getRandomFloat();
            const y = try utils.getRandomFloat();
            const z = try utils.getRandomFloat();
            return .{
                .x = x,
                .y = y,
                .z = z,
            };
        }

        pub fn randomRange(min: f32, max: f32) Self {
            const x = utils.getRandomFloatRange(min, max);
            const y = utils.getRandomFloatRange(min, max);
            const z = utils.getRandomFloatRange(min, max);
            return .{
                .x = x,
                .y = y,
                .z = z,
            };
        }

        pub fn randomInUnitSphere() Self {
            while (true) {
                const p = Vec3(f32).randomRange(-1.0, 1.0);
                if (p.lengthSquared() < 1.0) {
                    return p;
                }
            }
        }

        pub fn randomUnitVector() Self {
            return randomInUnitSphere().unitVector();
        }

        pub fn randomOnHemisphere(normal: Self) Self {
            const onUnitSphere = randomUnitVector();
            if (onUnitSphere.dot(normal) > 0.0) {
                return onUnitSphere;
            } else {
                return onUnitSphere.negative();
            }
        }

        pub fn nearZero(self: Self) bool {
            const eps = 1e-8;
            return (@abs(self.x) < eps and @abs(self.y) < eps and @abs(self.z) < eps);
        }

        pub fn reflect(self: Self, n: Self) Self {
            return self.subtract(n.mult(self.dot(n) * 2));
        }

        pub fn refract(self: Self, n: Self, etai_over_etat: f32) Self {
            const cos_theta = @min(self.dot(n) * -1, 1.0);
            const vec_out_perp = self.add(n.mult(cos_theta)).mult(etai_over_etat);
            const vec_out_parallel = n.mult(-@sqrt(@abs(1.0 - vec_out_perp.lengthSquared())));
            return vec_out_perp.add(vec_out_parallel);
        }

        // pub fn asBytes(self: *const Self) []const u8 {
        //     const buffer = struct {
        //         var data: [64]u8 = undefined;
        //     };
        //     return std.fmt.bufPrint(&buffer.data, "{d} {d} {d}\n", .{ self.x, self.y, self.z }) catch unreachable;
        // }
    };
}
