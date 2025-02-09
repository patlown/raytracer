const std = @import("std");
const Lexer = @import("tokenizer.zig").Lexer;
const TokenType = @import("tokenizer.zig").TokenType;
const Token = @import("tokenizer.zig").Token;
const testing = std.testing;
const print = std.debug.print;

test "get some feedback" {
    // Test input with leading whitespace to verify whitespace handling
    const input = " sphere {\n}\n()";
    var lexer = Lexer.new(input);

    // Get our tokens using the test allocator
    var tokens = try lexer.lex(testing.allocator);
    // Ensure we clean up our allocated memory
    defer testing.allocator.free(tokens);

    // The whitespace should have been skipped
    try testing.expectEqual(tokens.len, 6);

    // Get our token - this is a Token struct, not an optional
    const token = tokens[5];

    // If lexeme is an optional field in Token, we need to verify it exists
    // if (token.lexeme) |lexeme| {
    //     try testing.expectEqualStrings("{", lexeme);
    // } else {
    //     // If we get here, lexeme was null when it shouldn't have been
    //     try testing.expect(false);
    // }

    // Verify the token type directly - this isn't optional
    try testing.expectEqual(TokenType.eof, token.type);

    // If you want to test line number (assuming it's optional)
    // if (token.line) |line_number| {
    //     try testing.expectEqual(1, line_number);
    // }
}

test "numbers" {
    // Test input with leading whitespace to verify whitespace handling
    const input = "1.31\n 131\n 12.345\n";
    var lexer = Lexer.new(input);

    // Get our tokens using the test allocator
    var tokens = try lexer.lex(testing.allocator);
    // Ensure we clean up our allocated memory
    defer testing.allocator.free(tokens);

    // The whitespace should have been skipped
    try testing.expectEqual(tokens.len, 4);

    // Get our token - this is a Token struct, not an optional
    const token = tokens[2];

    // If lexeme is an optional field in Token, we need to verify it exists
    // if (token.lexeme) |lexeme| {
    //     try testing.expectEqualStrings("{", lexeme);
    // } else {
    //     // If we get here, lexeme was null when it shouldn't have been
    //     try testing.expect(false);
    // }

    // Verify the token type directly - this isn't optional
    try testing.expectEqual(TokenType.number, token.type);

    // If you want to test line number (assuming it's optional)
    // if (token.line) |line_number| {
    //     try testing.expectEqual(1, line_number);
    // }
}
