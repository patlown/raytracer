const std = @import("std");

pub const TokenType = enum {
    identifier,
    left_brace,
    right_brace,
    colon,
    number,
    left_paren,
    right_paren,
    comma,
    whitespace,
    eof,
};

pub const Token = struct {
    type: TokenType,
    lexeme: ?[]const u8,
    line: ?usize,

    pub fn eof() Token {
        return Token{ .type = .eof, .lexeme = null, .line = null };
    }
};

pub const Lexer = struct {
    source: []const u8,
    start: usize,
    current: usize,
    line: usize,

    pub fn new(source: []const u8) Lexer {
        return Lexer{
            .source = source,
            .start = 0,
            .current = 0,
            .line = 0,
        };
    }

    pub fn lex(self: *Lexer, allocator: std.mem.Allocator) !std.ArrayList(Token) {
        var tokens = std.ArrayList(Token).init(allocator);
        errdefer tokens.deinit();

        while (self.current < self.source.len) {
            const c = self.source[self.current];
            std.debug.print("char: {c}, start: {d}, curr: {d}, len: {d}\n\n", .{ c, self.start, self.current, self.source.len });

            switch (c) {
                'a'...'z' => {
                    self.current += 1;
                },
                '}' => {
                    try tokens.append(Token{
                        .type = .right_brace,
                        .lexeme = self.source[self.start .. self.current + 1],
                        .line = self.line,
                    });

                    self.current += 1;
                    self.start = self.current;
                },
                '{' => {
                    try tokens.append(Token{
                        .type = .left_brace,
                        .lexeme = self.source[self.start .. self.current + 1],
                        .line = self.line,
                    });

                    self.current += 1;
                    self.start = self.current;
                },
                ' ', '\n', '\t', 0 => {
                    if (self.current == self.start) {
                        self.current += 1;
                        self.start = self.current;
                        continue;
                    }

                    if (self.current > self.start) {
                        // we have some characters stored, let's grab the token
                        try tokens.append(Token{
                            .type = .identifier,
                            .lexeme = self.source[self.start..self.current],
                            .line = self.line,
                        });

                        self.current += 1;
                        self.start = self.current;
                        continue;
                    }

                    return error.InvalidData;
                },
                else => return error.InvalidData,
            }
        }

        try tokens.append(Token.eof());
        return tokens;
    }
};
