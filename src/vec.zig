const std = @import("std");

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

        pub fn divide(self: Self, scalar: T) Self {
            return .{
                .x = self.x / scalar,
                .y = self.y / scalar,
                .z = self.z / scalar,
            };
        }

        pub fn length(self: Self) f32 {
            return @sqrt(self.length_squared());
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

        fn length_squared(self: Self) f32 {
            return self.x * self.x + self.y * self.y + self.z * self.z;
        }
    };
}
