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
    // const sphere_center = Vec3.new(0, 0, 0);
    // const sphere_radius: f32 = 2;
    const screen_up = Vec3.new(0, 1, 0);
    const screen_right = Vec3.new(1, 0, 0);

    const view_direction = Vec3.new(0, 0, 1);

    const red_sphere = Sphere.new("255 0 0", Vec3.new(0, 0, 0), 2);
    const blue_sphere = Sphere.new("0 0 255", Vec3.new(3, -2, 0), 2);

    const spheres = [_]Sphere{ blue_sphere, red_sphere };

    // iterate y from height-1 down to 0 so that in the final image, the top row
    // corresponds to a higher y-value in world space (i.e. "up" is actually up).
    var y: f32 = height;
    while (y >= 0) : (y -= 1) {
        var x: f32 = 0;
        while (x < width) : (x += 1) {
            const step = Vec3.new(x, y, 0);

            const pixel = get_3d_space_pixel(step, camera, view_direction, focal_dist, width, height, screen_up, screen_right);

            const dir = get_ray_direction(pixel, camera);

            // find the closest sphere in the set
            var sphere_to_draw: ?Sphere = null;
            for (spheres) |sphere| {
                var closest: ?f32 = null;
                if (sphere_intersection(camera, dir, sphere.radius, sphere.center)) |t| {
                    if (closest) |c| {
                        closest = if (t < c) t else c;
                        sphere_to_draw = sphere;
                    } else {
                        closest = t;
                        sphere_to_draw = sphere;
                    }
                }
            }

            if (sphere_to_draw) |sphere| {
                try stdout.print("{s}\n", .{sphere.color});
            } else {
                try stdout.print("0 255 0\n", .{});
            }
        }
    }
}

pub fn sphere_intersection(camera: Vec3, ray_direction: Vec3, sphere_radius: f32, sphere_center: Vec3) ?f32 {
    const r_squared = sphere_radius * sphere_radius;
    const L = camera.subtract(sphere_center);

    const a = ray_direction.dot(ray_direction);
    const b = 2.0 * L.dot(ray_direction);
    const c = L.dot(L) - r_squared;

    // Compute discriminant
    const discriminant = (b * b) - (4.0 * a * c);
    if (discriminant < 0) {
        return null; // No intersection
    }

    const sqrt_discriminant = std.math.sqrt(discriminant);
    const t1 = (-b - sqrt_discriminant) / (2.0 * a);
    const t2 = (-b + sqrt_discriminant) / (2.0 * a);

    // Find the smallest positive t
    if (t1 > 0 and t2 > 0) {
        return if (t1 < t2) t1 else t2;
    } else if (t1 > 0) {
        return t1;
    } else if (t2 > 0) {
        return t2;
    } else {
        return null; // Both intersections are behind the camera
    }
}

pub fn get_ray_direction(pixel: Vec3, camera: Vec3) Vec3 {
    return pixel.subtract(camera);
}

pub fn get_3d_space_pixel(step: Vec3, camera: Vec3, view_direction: Vec3, focal_distance: f32, screen_width: f32, screen_height: f32, screen_up: Vec3, screen_right: Vec3) Vec3 {
    const screen_midpoint = Vec3.add(camera, view_direction.apply_scalar(focal_distance));

    // center x and y in negative space
    const centered_x = step.x - (screen_width / 2.0);
    const centered_y = step.y - (screen_height / 2.0);

    const aspect_ratio = screen_width / screen_height;

    // Convert "centered_x" and "centered_y" to a real-world offset on the plane.
    //    - "focal_distance / screen_width" is a simple scale factor. The bigger
    //      the screen_width, the less each pixel moves you in real space.
    //    - We multiply the horizontal offset by "aspect" to avoid distortion.
    const scale_x = (focal_distance / screen_width) * aspect_ratio;
    const scale_y = (focal_distance / screen_width);

    const x_step = screen_right.apply_scalar(centered_x * scale_x);
    const y_step = screen_up.apply_scalar(centered_y * scale_y);

    return screen_midpoint.add(x_step.add(y_step));
}

const Sphere = struct {
    color: []const u8,
    center: Vec3,
    radius: f32,

    pub fn new(color: []const u8, center: Vec3, radius: f32) Sphere {
        return Sphere{ .color = color, .center = center, .radius = radius };
    }
};

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
