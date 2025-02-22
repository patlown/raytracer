const std = @import("std");

pub const TokenType = enum {
    identifier,
    left_brace,
    right_brace,
    colon,
    number,
    left_paren,
    right_paren,
    eof,
    comma,
    minus,

    pub fn toString(self: TokenType) []const u8 {
        return switch (self) {
            .identifier => "identifier",
            .left_brace => "left_brace",
            .right_brace => "right_brace",
            .colon => "colon",
            .number => "number",
            .left_paren => "left_paren",
            .right_paren => "right_paren",
            .eof => "eof",
            .comma => "comma",
            .minus => "minus",
        };
    }
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

    pub fn lex(self: *Lexer, allocator: std.mem.Allocator) ![]const Token {
        var tokens = std.ArrayList(Token).init(allocator);
        errdefer tokens.deinit();

        while (self.current < self.source.len) {
            const c = self.source[self.current];

            switch (c) {
                'a'...'z', '_' => {
                    self.current += 1;
                },
                '0'...'9' => {
                    if (last_number(self)) {
                        try tokens.append(Token{
                            .type = .number,
                            .lexeme = self.source[self.start .. self.current + 1],
                            .line = self.line,
                        });

                        self.current += 1;
                        self.start = self.current;
                    } else {
                        self.current += 1;
                    }
                },
                ',' => {
                    try tokens.append(Token{
                        .type = .comma,
                        .lexeme = self.source[self.start .. self.current + 1],
                        .line = self.line,
                    });

                    self.current += 1;
                    self.start = self.current;
                },
                '-' => {
                    if (is_next_number(self)) {
                        try tokens.append(Token{
                            .type = .minus,
                            .lexeme = self.source[self.start .. self.current + 1],
                            .line = self.line,
                        });

                        self.current += 1;
                        self.start = self.current;
                    } else {
                        return error.InvalidData;
                    }
                },
                '.' => {
                    if (between_numbers(self)) {
                        self.current += 1;
                        continue;
                    }

                    return error.InvalidData;
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
                '(' => {
                    try tokens.append(Token{
                        .type = .left_paren,
                        .lexeme = self.source[self.start .. self.current + 1],
                        .line = self.line,
                    });

                    self.current += 1;
                    self.start = self.current;
                },
                ')' => {
                    try tokens.append(Token{
                        .type = .right_paren,
                        .lexeme = self.source[self.start .. self.current + 1],
                        .line = self.line,
                    });

                    self.current += 1;
                    self.start = self.current;
                },
                ':' => {
                    try tokens.append(Token{
                        .type = .colon,
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
                else => {
                    return error.InvalidData;
                },
            }
        }

        try tokens.append(Token.eof());
        return tokens.toOwnedSlice();
    }

    fn is_digit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn last_number(self: *Lexer) bool {
        if (peek_next(self)) |next| {
            if (!is_digit(next) and !(next == '.')) {
                return true;
            }
            // if the next is a digit, this is not the last number in this contiguous buffer
            return false;
        }
        // if there is no next, then this is the last number
        return true;
    }

    fn between_numbers(self: *Lexer) bool {
        if (peek_next(self)) |next| {
            if (peek_previous(self)) |prev| {
                if (is_digit(next) and is_digit(prev)) {
                    return true;
                }
            }
        }

        return false;
    }

    fn is_next_number(self: *Lexer) bool {
        if (peek_next(self)) |next| {
            if (is_digit(next)) {
                return true;
            }
        }

        return false;
    }

    fn peek_next(self: *Lexer) ?u8 {
        const next = self.current + 1;
        if (next < self.source.len) {
            return self.source[next];
        }

        return null;
    }

    fn peek_previous(self: *Lexer) ?u8 {
        const prev = self.current - 1;

        if (prev >= 0 and self.source.len > 0) {
            return self.source[prev];
        }

        return null;
    }
};
