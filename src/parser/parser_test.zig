const std = @import("std");
const Lexer = @import("tokenizer.zig").Lexer;
const Token = @import("tokenizer.zig").Token;
const TokenType = @import("tokenizer.zig").TokenType;
const Scene = @import("parser.zig").Scene;
const Parser = @import("parser.zig").Parser;

const allocator = std.heap.page_allocator;

pub fn main() !void {
    const test_runner = std.testing.registrar.init();
    try test_runner.runAllTests();
}

test "parse_empty_scene" {
    const input = "scene { }";
    var lexer = Lexer.new(input);
    const tokens = try lexer.lex(allocator);

    const scene = try Parser.parse(tokens);

    // Check that the scene has no blocks
    try std.testing.expectEqual(scene.blocks.len, 2);
}

// test "parse_single_block" {
//     const input = "scene { block { } }";
//     var lexer = Lexer.new(input);
//     const tokens = try lexer.lex(allocator);

//     const parser = Parser{};
//     const scene = try parser.parse(tokens, allocator);

//     // Check that the scene has one block
//     try std.testing.expectEqual(usize, scene.blocks.len, 1);

//     // Check that the block has no properties
//     try std.testing.expectEqual(usize, scene.blocks[0].properties.len, 0);
// }

// test "parse_block_with_property" {
//     const input = "scene { block { property: 1.0 } }";
//     var lexer = Lexer.new(input);
//     const tokens = try lexer.lex(allocator);

//     const parser = Parser{};
//     const scene = try parser.parse(tokens, allocator);

//     // Check that the scene has one block
//     try std.testing.expectEqual(usize, scene.blocks.len, 1);

//     // Check that the block has one property
//     try std.testing.expectEqual(usize, scene.blocks[0].properties.len, 1);

//     // Check the property value
//     try std.testing.expectEqual(f32, scene.blocks[0].properties[0].value.number, 1.0);
// }

// test "parse_multiple_blocks" {
//     const input = "scene { block { property: 1.0 } block { property: 2.0 } }";
//     var lexer = Lexer.new(input);
//     const tokens = try lexer.lex(allocator);

//     const parser = Parser{};
//     const scene = try parser.parse(tokens, allocator);

//     // Check that the scene has two blocks
//     try std.testing.expectEqual(usize, scene.blocks.len, 2);

//     // Check the property values in each block
//     try std.testing.expectEqual(f32, scene.blocks[0].properties[0].value.number, 1.0);
//     try std.testing.expectEqual(f32, scene.blocks[1].properties[0].value.number, 2.0);
// }

// test "parse_invalid_scene" {
//     const input = "invalid { block { property: 1.0 } }";
//     var lexer = Lexer.new(input);
//     const tokens = try lexer.lex(allocator);

//     const parser = Parser{};
//     const scene_result = parser.parse(tokens, allocator);

//     // Check that parsing fails with an error
//     try std.testing.expectError(scene_result);
// }
