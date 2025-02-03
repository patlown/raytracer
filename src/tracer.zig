const Scene = @import("scene_details.zig").Scene;
const Vec3 = @import("math.zig").Vec3;
const Sphere = @import("shape.zig").Sphere;
const std = @import("std");

const IntersectedSphere = struct {
    sphere: Sphere,
    intersection_point: Vec3,
    distance: f32,

    pub fn new(sphere: Sphere, ip: Vec3, d: f32) IntersectedSphere {
        return IntersectedSphere{ .sphere = sphere, .intersection_point = ip, .distance = d };
    }
};

pub fn trace(allocator: std.mem.Allocator, scene: *const Scene.Details) ![]const Vec3 {
    const pixels = try allocator.alloc(Vec3, @intFromFloat(scene.screen_height * scene.screen_width));
    errdefer allocator.free(pixels);

    // iterate y from height-1 down to 0 so that in the final image, the top row
    // corresponds to a higher y-value in world space (i.e. "up" is actually up).
    var y: f32 = scene.screen_height;
    while (y > 0) : (y -= 1) {
        var x: f32 = 0;
        while (x < scene.screen_width) : (x += 1) {

            // this might be wrong, off by one???
            const pixel_index = @as(usize, @intFromFloat(((scene.screen_height - y) * scene.screen_width) + x));

            const screen_pixel = Vec3.new(x, y, 0);
            const pixel_in_world_space = translate_pixel_to_world_space(scene.camera, scene.screen_width, scene.screen_height, scene.view_direction, scene.focal_distance, screen_pixel);

            const ray_direction = pixel_in_world_space.subtract(scene.camera).normalize();

            var intersected_sphere: ?IntersectedSphere = null;
            for (scene.spheres, 0..) |sphere, index| {
                const distance = sphere_intersection(scene.camera, ray_direction, sphere.radius, sphere.center);

                if (distance) |d| {
                    var closest = d;
                    var sphere_to_draw = sphere;
                    for (scene.spheres[index + 1 ..]) |other_sphere| {
                        if (sphere_intersection(scene.camera, ray_direction, other_sphere.radius, other_sphere.center)) |t| {
                            if (t < closest) { // we hit the other sphere first
                                closest = t;
                                sphere_to_draw = other_sphere;
                            }
                        }
                    }

                    // save intersected sphere
                    intersected_sphere = IntersectedSphere.new(sphere_to_draw, scene.camera.add(ray_direction.apply_scalar(closest)), closest);
                }
            }

            if (intersected_sphere) |is| {
                const point_to_light = scene.light.source.subtract(is.intersection_point).normalize();

                var in_shadow = false;
                for (scene.spheres) |other_sphere| {
                    if (other_sphere.equals(is.sphere)) continue;
                    if (sphere_intersection(is.intersection_point, point_to_light, other_sphere.radius, other_sphere.center)) |_| {
                        // hit another sphere, this point is in shadow
                        in_shadow = true;
                        break;
                    }
                }
                if (in_shadow) {
                    const color = is.sphere.color.apply_scalar(0.05);
                    pixels[pixel_index] = color;
                } else {
                    const color = calculate_sphere_color_from_light(is.sphere, is.intersection_point, scene.light);
                    pixels[pixel_index] = color;
                }
            } else {
                pixels[pixel_index] = Vec3.new(0, 0, 0);
            }
        }
    }

    return pixels;
}

fn sphere_intersection(camera: Vec3, ray_direction: Vec3, sphere_radius: f32, sphere_center: Vec3) ?f32 {
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
    const epsilon: f32 = 1e-4;
    if (t1 > epsilon and t2 > epsilon) {
        return if (t1 < t2) t1 else t2;
    } else if (t1 > epsilon) {
        return t1;
    } else if (t2 > epsilon) {
        return t2;
    } else {
        return null; // Ignore intersections too close to the origin
    }
}

fn translate_pixel_to_world_space(camera: Vec3, screen_pixels_width: f32, screen_pixels_height: f32, view_direction: Vec3, focal_distance: f32, pixel: Vec3) Vec3 {
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

    return pixel_in_world_space;
}

fn calculate_sphere_color_from_light(sphere: Sphere, intersection_point: Vec3, light: Scene.Light) Vec3 {
    const normal_to_point = intersection_point.subtract(sphere.center).normalize();

    const light_to_point = light.source.subtract(intersection_point).normalize();

    const light_coefficient = light_to_point.dot(normal_to_point);

    const clamped_light_coefficient = std.math.clamp(light_coefficient, 0.0, 1.0);

    return light.color.product(sphere.color).apply_scalar(clamped_light_coefficient);
}
