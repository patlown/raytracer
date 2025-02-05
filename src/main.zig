const std = @import("std");
const expect = std.testing.expect;
const Scene = @import("scene_details.zig").Scene;
const Vec3 = @import("math.zig").Vec3;
const Sphere = @import("shape.zig").Sphere;
const tracer = @import("tracer.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const width: f32 = 640;
    const height: f32 = 480;
    const max_value: u16 = 255;

    try stdout.print("P3\n", .{});
    try stdout.print("{d} {d}\n", .{ width, height });
    try stdout.print("{d}\n", .{max_value});

    const red_sphere = Sphere.new(Vec3.new(1, 0, 0), Vec3.new(0, 0, 2), 3);
    const blue_sphere = Sphere.new(Vec3.new(0, 0, 1), Vec3.new(-2, -1, -5), 1);
    const green_sphere = Sphere.new(Vec3.new(0, 1, 0), Vec3.new(-3, 0, -7), 0.5);
    const spheres = [_]Sphere{ red_sphere, blue_sphere, green_sphere };

    const scene = Scene.init(Vec3.new(0, 0, -20), // camera
        10, // focal distance
        height, width, Vec3.new(0, 0, 1), // view direction
        Scene.Light.new(Scene.LightColors.white, Vec3.new(-5, 0, -20)), &spheres);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    // todo: calculating all pixels and storing them in memory is slowwww, make this better (streaming?)
    const pixels = try tracer.trace(allocator, &scene);
    defer allocator.free(pixels);

    for (pixels) |pixel| {
        try stdout.print("{d} {d} {d}\n", .{
            round_to_u8(pixel.x),
            round_to_u8(pixel.y),
            round_to_u8(pixel.z),
        });
    }
}

pub fn round_to_u8(value: f32) u8 {
    const clamped = std.math.clamp(value, 0.0, 1.0);

    const scaled = clamped * 255.0;

    const rounded = @floor(scaled + 0.5);

    return @intFromFloat(rounded);
}
