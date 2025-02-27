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

    const scene = try Parser.parse(tokens, allocator);

    // Check that the scene has no blocks
    try std.testing.expectEqual(scene.blocks.len, 0);
}

test "parse_single_block" {
    const input = "scene { block { } }";
    var lexer = Lexer.new(input);
    const tokens = try lexer.lex(allocator);

    const scene = try Parser.parse(tokens, allocator);

    // Check that the scene has one block
    try std.testing.expectEqual(scene.blocks.len, 1);
}

test "parse_block_with_property" {
    const input = "scene { block { property : 1.0 } }";
    var lexer = Lexer.new(input);
    const tokens = try lexer.lex(allocator);

    const scene = try Parser.parse(tokens, allocator);

    // Check that the scene has one block
    try std.testing.expectEqual(scene.blocks.len, 1);

    // Check that the block has one property
    try std.testing.expectEqual(scene.blocks[0].properties.len, 1);

    // Check the property value
    try std.testing.expectEqual(scene.blocks[0].properties[0].value.number, 1.0);
}

test "parse_multiple_blocks" {
    const input = "scene { block { property : 1.0 } block { property : 2.0 } }";
    var lexer = Lexer.new(input);
    const tokens = try lexer.lex(allocator);

    const scene = try Parser.parse(tokens, allocator);

    // Check that the scene has two blocks
    try std.testing.expectEqual(scene.blocks.len, 2);

    // Check the property values in each block
    // try std.testing.expectEqual(f32, scene.blocks[0].properties[0].value.number, 1.0);
    // try std.testing.expectEqual(f32, scene.blocks[1].properties[0].value.number, 2.0);
}

test "parse_vectors" {
    const input = "scene { block { property : (1.0, 1.0, 1.0) } block { property : 2.0 } }";
    var lexer = Lexer.new(input);
    const tokens = try lexer.lex(allocator);

    const scene = try Parser.parse(tokens, allocator);

    // Check that the scene has two blocks
    try std.testing.expectEqual(scene.blocks.len, 2);

    // Check the property values in each block
    try std.testing.expectEqual(scene.blocks[0].properties[0].value.vector.x, 1.0);
}

test "parse_basic_scene_file" {
    // Get the directory of the current source file
    const flags = std.fs.File.OpenFlags{ .mode = .read_only };
    const file_path = "scenes/basic_scene.pat";
    const file = try std.fs.cwd().openFile(file_path, flags);
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024);
    defer allocator.free(content);

    // parse the content
    var lexer = Lexer.new(content);
    const tokens = try lexer.lex(allocator);
    const block = try Parser.parse(tokens, allocator);

    block.print();

    // Check that the scene has the expected number of blocks
    try std.testing.expectEqual(block.blocks.len, 4);
}
