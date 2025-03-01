const std = @import("std");
const expect = std.testing.expect;
const Scene = @import("scene_details.zig").Scene;
const Vec3 = @import("math.zig").Vec3;
const Sphere = @import("shape.zig").Sphere;
const tracer = @import("tracer.zig");
const Lexer = @import("tokenizer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const Interpreter = @import("interpreter.zig").Interpreter;
const ParsedScene = @import("interpreter.zig").ParsedScene;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    //parse the scene from the scenes/basic_scene.pat file
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // This will free ALL memory allocated with arena.allocator()
    const allocator = arena.allocator();

    // read the file scene/basic_scene.pat into a string in memory
    const file_path = "scenes/basic_scene.pat";
    const file_contents: []const u8 = try std.fs.cwd().readFileAlloc(allocator, file_path, std.math.maxInt(usize));
    defer allocator.free(file_contents);

    var lexer = Lexer.new(file_contents);
    const tokens = try lexer.lex(allocator);
    const scene_block = try Parser.parse(tokens, allocator);
    const parsed_scene = try Interpreter.interpret(scene_block, allocator);

    const width: f32 = parsed_scene.screen.width;
    const height: f32 = parsed_scene.screen.height;
    const max_value: u16 = 255;

    try stdout.print("P3\n", .{});
    try stdout.print("{d} {d}\n", .{ width, height });
    try stdout.print("{d}\n", .{max_value});

    // const red_sphere = Sphere.new(Vec3.new(1, 0, 0), Vec3.new(0, 0, 2), 3);
    // const blue_sphere = Sphere.new(Vec3.new(0, 0, 1), Vec3.new(-2, -1, -5), 1);
    // const green_sphere = Sphere.new(Vec3.new(0, 1, 0), Vec3.new(-3, 0, -7), 0.5);
    // const spheres = [_]Sphere{ red_sphere, blue_sphere, green_sphere };

    var spheres = try allocator.alloc(Sphere, parsed_scene.shapes.len);
    defer allocator.free(spheres);

    for (parsed_scene.shapes, 0..) |shape, i| {
        spheres[i] = shape.sphere;
        std.debug.print("Sphere {d}: color={d},{d},{d} center={d},{d},{d} radius={d}\n", .{
            i,
            shape.sphere.color.x,
            shape.sphere.color.y,
            shape.sphere.color.z,
            shape.sphere.center.x,
            shape.sphere.center.y,
            shape.sphere.center.z,
            shape.sphere.radius,
        });
    }

    const scene = Scene.init(parsed_scene.camera.position, // camera
        parsed_scene.camera.focal_distance, // focal distance
        height, width, parsed_scene.camera.direction, // view direction
        Scene.Light.new(parsed_scene.light.color, parsed_scene.light.position), spheres);

    // print my scene
    std.debug.print("Scene: camera={d},{d},{d} focal_distance={d} width={d} height={d} light={d},{d},{d} lightSource={d},{d},{d}\n", .{
        scene.camera.x,
        scene.camera.y,
        scene.camera.z,
        scene.focal_distance,
        width,
        height,
        scene.light.color.x,
        scene.light.color.y,
        scene.light.color.z,
        scene.light.source.x,
        scene.light.source.y,
        scene.light.source.z,
    });

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
