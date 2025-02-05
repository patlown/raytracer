const std = @import("std");
const Lexer = @import("parser.zig").Lexer;
const TokenType = @import("parser.zig").TokenType;
const Token = @import("parser.zig").Token;
const testing = std.testing;
const print = std.debug.print;

test "get some feedback" {
    // Test input with leading whitespace to verify whitespace handling
    const input = " sphere {\n}";
    var lexer = Lexer.new(input);

    // Get our tokens using the test allocator
    var tokens = try lexer.lex(testing.allocator);
    // Ensure we clean up our allocated memory
    defer tokens.deinit();

    // Verify we got exactly one token (the '' character)
    // The whitespace should have been skipped
    try testing.expectEqual(tokens.items.len, 4);

    // Get our token - this is a Token struct, not an optional
    const token = tokens.items[3];

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
