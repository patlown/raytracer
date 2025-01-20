const std = @import("std");
const expect = std.testing.expect;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const width: f32 = 64;
    const height: f32 = 48;
    const max_value: u16 = 255;

    try stdout.print("P3\n", .{});
    try stdout.print("{d} {d}\n", .{ width, height });
    try stdout.print("{d}\n", .{max_value});

    const camera = Vec3.new(0, 0, -20);
    const focal_dist: f32 = 10;
    const sphere_center = Vec3.new(0, 0, 0);
    const sphere_radius: f32 = 5;
    const screen_up = Vec3.new(0, 1, 0);
    const screen_right = Vec3.new(1, 0, 0);

    const view_direction = Vec3.new(0, 0, 1);

    var y: f32 = 0;
    while (y < height) : (y += 1) {
        var x: f32 = 0;
        while (x < width) : (x += 1) {
            const step = Vec3.new(x, y, 0);
            if (x == 32 and y == 24) {
                std.debug.print("print step: ", .{});
                step.print();
            }

            const pixel = get_pixel(step, camera, view_direction, focal_dist, width, height, screen_up, screen_right);
            if (x == 32 and y == 24) {
                std.debug.print("print pixel: ", .{});
                pixel.print();
            }

            const dir = get_ray_direction(pixel, camera);
            if (x == 32 and y == 24) {
                std.debug.print("print dir: ", .{});
                dir.print();
                std.debug.print("\n", .{});
            }

            if (sphere_intersection(camera, dir, sphere_radius, sphere_center)) {
                try stdout.print("255 0 0\n", .{});
            } else {
                try stdout.print("0 255 0\n", .{});
            }
        }
    }
}

pub fn sphere_intersection(camera: Vec3, ray_direction: Vec3, sphere_radius: f32, sphere_center: Vec3) bool {
    const r_squared = sphere_radius * sphere_radius;
    const L = camera.subtract(sphere_center);

    const a = ray_direction.dot(ray_direction); // Length squared of ray direction
    const b = 2.0 * L.dot(ray_direction); // 2 times alignment of L with ray
    const c = L.dot(L) - r_squared; // Length squared of L minus radius squared

    // std.debug.print("print a:{d}, b:{d}, c:{d} ", .{ a, b, c });

    // Compute discriminant
    const discriminant = (b * b) - (4.0 * a * c);
    // If discriminant is negative, no intersection
    if (discriminant < 0) {
        return false;
    }
    return true; // Intersection exists
}

pub fn get_ray_direction(pixel: Vec3, camera: Vec3) Vec3 {
    return pixel.subtract(camera);
}

pub fn get_pixel(step: Vec3, camera: Vec3, view_direction: Vec3, focal_distance: f32, screen_width: f32, screen_height: f32, screen_up: Vec3, screen_right: Vec3) Vec3 {
    const screen_midpoint = Vec3.add(camera, Vec3.apply_scalar(view_direction, focal_distance));

    // Convert pixel coordinates to be centered around 0:
    // First, move origin to center by subtracting half width/height
    const centered_x = step.x - (screen_width / 2.0);
    const centered_y = step.y - (screen_height / 2.0);

    // Then scale to our desired world size, accounting for aspect ratio
    const x_step = screen_right.apply_scalar(centered_x * (focal_distance / screen_width));
    const y_step = screen_up.apply_scalar(centered_y * (focal_distance / screen_width));

    return screen_midpoint.add(x_step.add(y_step));
}

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn new(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{ .x = x, .y = y, .z = z };
    }

    pub fn apply_scalar(self: Vec3, s: f32) Vec3 {
        return Vec3.new(self.x * s, self.y * s, self.z * s);
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

    pub fn print(self: Vec3) void {
        std.debug.print("Vec3(x: {d}, y: {d}, z: {d})\n", .{ self.x, self.y, self.z });
    }
};
