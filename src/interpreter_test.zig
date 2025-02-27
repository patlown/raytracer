const std = @import("std");
const Lexer = @import("tokenizer.zig").Lexer;
const Token = @import("tokenizer.zig").Token;
const TokenType = @import("tokenizer.zig").TokenType;
const Parser = @import("parser.zig").Parser;
const Block = @import("parser.zig").Block;
const Property = @import("parser.zig").Property;
const Value = @import("parser.zig").Value;
const Vector = @import("parser.zig").Vector;
const Interpreter = @import("interpreter.zig").Interpreter;
const InterpreterError = @import("interpreter.zig").InterpreterError;
const Camera = @import("interpreter.zig").Camera;
const Vec3 = @import("math.zig").Vec3;

const allocator = std.heap.page_allocator;

pub fn main() !void {
    const test_runner = std.testing.registrar.init();
    try test_runner.runAllTests();
}

test "interpret_camera_block" {
    // Create a test block directly
    const camera_block = Block{
        .identifier = .{ .name = "camera" },
        .properties = &[_]Property{
            .{
                .identifier = .{ .name = "position" },
                .value = Value{ .vector = Vector{ .x = 0.0, .y = 0.0, .z = 5.0 } },
            },
            .{
                .identifier = .{ .name = "direction" },
                .value = Value{ .vector = Vector{ .x = 0.0, .y = 0.0, .z = -1.0 } },
            },
            .{
                .identifier = .{ .name = "focal_distance" },
                .value = Value{ .number = 1.0 },
            },
        },
        .blocks = &[_]Block{},
    };

    const scene_block = Block{
        .identifier = .{ .name = "Scene" },
        .properties = &[_]Property{},
        .blocks = &[_]Block{camera_block},
    };

    // Interpret the block
    const scene = try Interpreter.interpret(scene_block, allocator);

    // Check the camera properties
    try std.testing.expectEqual(@as(f32, 0.0), scene.camera.position.x);
    try std.testing.expectEqual(@as(f32, 0.0), scene.camera.position.y);
    try std.testing.expectEqual(@as(f32, 5.0), scene.camera.position.z);

    try std.testing.expectEqual(@as(f32, 0.0), scene.camera.direction.x);
    try std.testing.expectEqual(@as(f32, 0.0), scene.camera.direction.y);
    try std.testing.expectEqual(@as(f32, -1.0), scene.camera.direction.z);

    try std.testing.expectEqual(@as(f32, 1.0), scene.camera.focal_distance);
}

// test "interpret_camera_from_string" {
//     const input = "Scene { camera { position: (0.0, 1.0, 5.0) direction: (0.0, 0.0, -1.0) focal_distance: 1.5 } }";
//     var lexer = Lexer.new(input);
//     const tokens = try lexer.lex(allocator);
//     defer allocator.free(tokens);

//     const block = try Parser.parse(tokens, allocator);
//     defer allocator.destroy(block);

//     const scene = try Interpreter.interpret(block.*);

//     // Check the camera properties
//     try std.testing.expectEqual(@as(f32, 0.0), scene.camera.position.x);
//     try std.testing.expectEqual(@as(f32, 1.0), scene.camera.position.y);
//     try std.testing.expectEqual(@as(f32, 5.0), scene.camera.position.z);

//     try std.testing.expectEqual(@as(f32, 0.0), scene.camera.direction.x);
//     try std.testing.expectEqual(@as(f32, 0.0), scene.camera.direction.y);
//     try std.testing.expectEqual(@as(f32, -1.0), scene.camera.direction.z);

//     try std.testing.expectEqual(@as(f32, 1.5), scene.camera.focal_distance);
// }

// test "interpret_invalid_camera" {
//     // Missing focal_distance
//     const input = "Scene { camera { position: (0.0, 1.0, 5.0) direction: (0.0, 0.0, -1.0) } }";
//     var lexer = Lexer.new(input);
//     const tokens = try lexer.lex(allocator);
//     defer allocator.free(tokens);

//     const block = try Parser.parse(tokens, allocator);
//     defer allocator.destroy(block);

//     // Should return an error
//     const result = Interpreter.interpret(block.*);
//     try std.testing.expectError(InterpreterError.InvalidCamera, result);
// }
