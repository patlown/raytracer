const std = @import("std");

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn new(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{ .x = x, .y = y, .z = z };
    }

    pub fn apply_scalar(self: Vec3, s: f32) Vec3 {
        return Vec3.new(self.x * s, self.y * s, self.z * s);
    }

    pub fn product(self: Vec3, other: Vec3) Vec3 {
        return Vec3.new(self.x * other.x, self.y * other.y, self.z * other.z);
    }

    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return Vec3.new(self.x + other.x, self.y + other.y, self.z + other.z);
    }

    pub fn subtract(self: Vec3, other: Vec3) Vec3 {
        return Vec3.new(self.x - other.x, self.y - other.y, self.z - other.z);
    }

    pub fn dot(self: Vec3, other: Vec3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn length(self: Vec3) f32 {
        return std.math.sqrt(self.dot(self));
    }

    pub fn normalize(self: Vec3) Vec3 {
        const len = self.length();
        const epsilon: f32 = 1e-6;
        if (len < epsilon) {
            std.debug.print("Warning: Zero or near-zero length vector encountered during normalization\n", .{});
            return Vec3.new(0.0, 0.0, 0.0);
        }
        return Vec3.new(self.x / len, self.y / len, self.z / len);
    }

    pub fn equals(self: Vec3, other: Vec3) bool {
        return self.x == self.x and self.y == other.y and self.z == other.z;
    }

    pub fn print(self: Vec3) void {
        std.debug.print("Vec3(x: {d}, y: {d}, z: {d})\n", .{ self.x, self.y, self.z });
    }
};
