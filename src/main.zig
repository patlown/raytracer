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

    // const screen_up = Vec3.new(0, 1, 0);
    // const screen_right = Vec3.new(1, 0, 0);

    const view_direction = Vec3.new(0, 0, 1);

    const red_sphere = Sphere.new(Vec3.new(1, 0, 0), Vec3.new(2, 5, 0), 2);
    const blue_sphere = Sphere.new(Vec3.new(0, 0, 1), Vec3.new(1, 0, 0), 2);

    const spheres = [_]Sphere{ blue_sphere, red_sphere };

    // const light = Vec3.new(0, 0, -30);

    // const light_color = "236 232 101";

    // iterate y from height-1 down to 0 so that in the final image, the top row
    // corresponds to a higher y-value in world space (i.e. "up" is actually up).
    var y: f32 = height;
    while (y >= 0) : (y -= 1) {
        var x: f32 = 0;
        while (x < width) : (x += 1) {
            const screen_pixel = Vec3.new(x, y, 0);
            const pixel_in_world_space = translate_pixel_to_world_space(camera, width, height, view_direction, focal_dist, screen_pixel);

            const ray_direction = pixel_in_world_space.subtract(camera).normalize();

            // find the closest sphere in the set
            var sphere_to_draw: ?Sphere = null;
            var closest: ?f32 = null;
            for (spheres) |sphere| {
                if (sphere_intersection(camera, ray_direction, sphere.radius, sphere.center)) |t| {
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
                try stdout.print("{s}\n", .{sphere.get_8_bit_color()});
            } else {
                try stdout.print("0 255 0\n", .{});
            }

            // // todo: figure out how to somewhat efficiently check for light blocking from any other spheres
            // // figure out how to apply lighting intensity based on the angle
            // if (sphere_to_draw) |sphere| {
            //     // check for light intersection
            //     const intersection_point = camera.add(ray_direction.apply_scalar(closest));

            //     const point_to_light = light.subtract(intersection_point);
            //     const pl_normal = point_to_light.normalize();
            //     const pl_mag = point_to_light.length();
            //     const normal_to_point = point_to_light.subtract(sphere.center);

            //     // check for other spheres blocking light
            //     for (spheres) |sphere| {
            //         // how does equality work?
            //         if (sphere_to_draw == sphere) {
            //             continue;
            //         }

            //         const light_angle = pl_normal.dot(normal_to_point);

            //         if (sphere_intersection(intersection_point, pl_normal, sphere.radius, sphere.center)) |t| {
            //             // intersection with obstruction
            //             if (t > 0 and t < pl_mag) {
            //                 // cast in shadow
            //                 try stdout.print("0 0 0\n", .{});
            //             }
            //         }

            //     }

            //     try stdout.print("{s}\n", .{sphere.color});
            // } else {
            //     try stdout.print("0 255 0\n", .{});
            // }
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

pub fn translate_pixel_to_world_space(camera: Vec3, screen_pixels_width: f32, screen_pixels_height: f32, view_direction: Vec3, focal_distance: f32, pixel: Vec3) Vec3 {
    const aspect_ratio = screen_pixels_width / screen_pixels_height;

    // get the physical size of the screen in world space
    const screen_world_height = 10;
    const screen_world_width = screen_world_height * aspect_ratio;

    const screen_center = camera.add(view_direction.apply_scalar(focal_distance));

    // calculate the pixel size (in world space), use that for precise ray casting
    const pixel_width = screen_world_width / screen_pixels_width;
    const pixel_height = screen_world_height / screen_pixels_height;

    // calculate (x,y) to (dx, dy, dz) in world space (pixel center)
    // (0,0) pixel should map to (-x_max, y_max) in world
    // (63, 47) pixel should ~roughly map to (x_max, -y_max) in world
    // (32, 24) pixel should  map to (0, 0) in world

    // map x -> dx
    const x_world_space = ((pixel.x - (screen_pixels_width / 2)) * pixel_width) + (pixel_width / 2);

    // map y -> dy
    const y_world_space = ((pixel.y - (screen_pixels_height / 2)) * (pixel_height)) + pixel_height / 2;

    // calculated x,y in world, now place on z axis by using z position from screen center
    const pixel_in_world_space = Vec3.new(x_world_space, y_world_space, screen_center.z);

    if (pixel.x == 63 and pixel.y == 47) {
        std.debug.print("screen pixel x: 63, y:47\n", .{});
        pixel_in_world_space.print();
    }

    if (pixel.x == 0 and pixel.y == 0) {
        std.debug.print("screen pixel x: 0, y:0\n", .{});
        pixel_in_world_space.print();
    }

    if (pixel.x == 32 and pixel.y == 24) {
        std.debug.print("screen pixel x: 32, y:24\n", .{});
        pixel_in_world_space.print();
    }

    return pixel_in_world_space;
}

// pub fn calculate_sphere_color_from_light(sphere: Sphere, intersection_point: Vec3, light: Light) Vec3 {

//     const normal_to_point = intersection_point.subtract(sphere.center).normalize();

//     const light_to_point = light.source.subtract(intersection_point).normalize();

//     const light_coefficient = light_to_point.dot(normal_to_point);

// }

// const Light = struct {
//     color: Vec3,
//     source: Vec3
// };

const Sphere = struct {
    color: Vec3,
    center: Vec3,
    radius: f32,

    pub fn new(color: Vec3, center: Vec3, radius: f32) Sphere {
        return Sphere{ .color = color, .center = center, .radius = radius };
    }

    pub fn get_8_bit_color(self: Sphere) []const u8 {
        var buffer: [12]u8 = undefined;
        const slice = std.fmt.bufPrint(&buffer, "{d} {d} {d}", .{ @as(u8, @intFromFloat(self.color.x * 255.0)), @as(u8, @intFromFloat(self.color.y * 255.0)), @as(u8, @intFromFloat(self.color.z * 255.0)) }) catch unreachable;
        return buffer[0..slice.len];
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

    pub fn length(self: Vec3) f32 {
        return std.math.sqrt(self.dot(self));
    }

    pub fn normalize(self: Vec3) Vec3 {
        const len = self.length();
        return Vec3.new(self.x / len, self.y / len, self.z / len);
    }

    pub fn print(self: Vec3) void {
        std.debug.print("Vec3(x: {d}, y: {d}, z: {d})\n", .{ self.x, self.y, self.z });
    }
};
