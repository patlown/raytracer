const Vec3 = @import("math.zig").Vec3;
const std = @import("std");

pub const Sphere = struct {
    color: Vec3,
    center: Vec3,
    radius: f32,

    pub fn new(color: Vec3, center: Vec3, radius: f32) Sphere {
        return Sphere{ .color = color, .center = center, .radius = radius };
    }

    pub fn equals(self: Sphere, other: Sphere) bool {
        return self.center.equals(other.center) and self.radius == other.radius;
    }

    pub fn print(self: Sphere) void {
        std.debug.print("Sphere \n", .{});
        std.debug.print("    color: ", .{});
        self.color.print();
        std.debug.print("    center: ", .{});
        self.center.print();
        std.debug.print("    radius: {d}\n", .{self.radius});
        std.debug.print("\n", .{});
    }
};
