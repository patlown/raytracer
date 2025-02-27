const std = @import("std");
const Token = @import("tokenizer.zig").Token;
const TokenType = @import("tokenizer.zig").TokenType;

pub const Vector = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn print(self: Vector) void {
        std.debug.print("({d}, {d}, {d})", .{ self.x, self.y, self.z });
    }
};

pub const Value = union(enum) {
    number: f32,
    vector: Vector,

    pub fn print(self: Value) void {
        switch (self) {
            .number => |n| std.debug.print("{d}", .{n}),
            .vector => |v| v.print(),
        }
    }
};

pub const Identifier = struct {
    name: []const u8,
    pub fn new(name: []const u8) Identifier {
        return Identifier{ .name = name };
    }
    pub fn print(self: Identifier) void {
        std.debug.print("{s}", .{self.name});
    }
};

pub const Property = struct {
    identifier: Identifier,
    value: Value,

    pub fn print(self: Property) void {
        self.identifier.print();
        std.debug.print(": ", .{});
        self.value.print();
        std.debug.print("\n", .{});
    }
};

pub const Block = struct {
    identifier: Identifier,
    properties: []const Property,
    blocks: []const Block,

    pub fn print(self: Block) void {
        self.print_internal(0);
    }

    // indentation matters for the output
    fn print_internal(self: Block, indent: usize) void {
        self.identifier.print();
        std.debug.print(" {{\n", .{});
        for (self.properties) |property| {
            for (0..indent + 1) |_| {
                std.debug.print("    ", .{});
            }
            property.print();
        }
        for (self.blocks) |block| {
            for (0..indent + 1) |_| {
                std.debug.print("    ", .{});
            }
            block.print_internal(indent + 1);
        }
        for (0..indent) |_| {
            std.debug.print("    ", .{});
        }
        std.debug.print("}}\n", .{});
    }
};

pub const ParseError = error{ FLOAT_TOO_MANY_DIGITS, NO_TOKENS, EXPECTED_IDENTIFIER, BlOCK_NOT_OPENED, BLOCK_NOT_CLOSED, EMPTY_BLOCK, UNEXPECTED_TOKEN };

pub const Parser = struct {
    const State = struct {
        tokens: []const Token,
        current: usize,
        allocator: std.mem.Allocator,

        pub fn init(tokens: []const Token, allocator: std.mem.Allocator) State {
            return State{ .tokens = tokens, .current = 0, .allocator = allocator };
        }

        pub fn increment(self: *State) void {
            self.current += 1;
        }

        pub fn current_token(self: *State) ?*const Token {
            if (self.current >= self.tokens.len) {
                return null;
            }
            return &self.tokens[self.current];
        }

        pub fn jump_next(self: *State) ?*const Token {
            self.increment();
            return self.current_token();
        }

        pub fn peek_next(self: *State) ?*const Token {
            const next_index = self.current + 1;
            if (next_index >= self.tokens.len) {
                return null;
            }
            return &self.tokens[next_index];
        }
    };

    /// Entry point: parses a block from tokens.
    pub fn parse(tokens: []const Token, allocator: std.mem.Allocator) !*Block {
        if (tokens.len == 0) {
            return ParseError.NO_TOKENS;
        }
        var state = Parser.State.init(tokens, allocator);
        // Parse the top-level block.
        const blockVal = try Parser.parseBlock(&state);
        const blockPtr = try allocator.create(Block);
        blockPtr.* = blockVal;
        return blockPtr;
    }

    /// Parses a list of blocks until a right brace is encountered.
    fn parseBlocks(state: *State) ![]const Block {
        var blockList = std.ArrayList(Block).init(state.allocator);
        // We intentionally do not call blockList.deinit() here,
        // because we are “transferring” ownership of the allocated slice.
        while (true) {
            const token = state.current_token();
            if (token) |tok| {
                if (tok.type == TokenType.right_brace) break;
                // Each block begins with an identifier.
                const block = try Parser.parseBlock(state);
                try blockList.append(block);
            } else {
                break;
            }
        }
        return blockList.toOwnedSlice();
    }

    /// Parses a single block:
    /// block := identifier "{" ( property | block )* "}"
    fn parseBlock(state: *State) !Block {
        // Expect an identifier for the block's name.
        const idToken = state.current_token() orelse return ParseError.EXPECTED_IDENTIFIER;
        if (idToken.type != TokenType.identifier) {
            return ParseError.EXPECTED_IDENTIFIER;
        }
        const blockName = idToken.lexeme orelse unreachable;
        state.current += 1; // consume the identifier

        // Expect the opening brace.
        const left = state.current_token() orelse return ParseError.BlOCK_NOT_OPENED;
        if (left.type != TokenType.left_brace) {
            return ParseError.BlOCK_NOT_OPENED;
        }
        state.current += 1; // consume '{'

        var propertyList = std.ArrayList(Property).init(state.allocator);
        var blockList = std.ArrayList(Block).init(state.allocator);

        // Parse contents until the closing brace.
        while (true) {
            const curr = state.current_token() orelse return ParseError.BLOCK_NOT_CLOSED;
            if (curr.type == TokenType.right_brace) {
                state.current += 1; // consume '}'
                break;
            }

            // Every entry in a block should start with an identifier.
            if (curr.type != TokenType.identifier) {
                return ParseError.UNEXPECTED_TOKEN;
            }

            // Peek to decide whether this is a property or a nested block.
            const next = state.peek_next() orelse return ParseError.UNEXPECTED_TOKEN;
            if (next.type == TokenType.colon) {
                // Parse a property.
                const prop = try Parser.parseProperty(state);
                try propertyList.append(prop);
            } else if (next.type == TokenType.left_brace) {
                // Parse a nested block.
                const nested = try Parser.parseBlock(state);
                try blockList.append(nested);
            } else {
                return ParseError.UNEXPECTED_TOKEN;
            }
        }

        var properties: []const Property = &[_]Property{};
        if (propertyList.items.len > 0) {
            properties = try propertyList.toOwnedSlice();
        }
        var blocks: []const Block = &[_]Block{};
        if (blockList.items.len > 0) {
            blocks = try blockList.toOwnedSlice();
        }

        return Block{
            .identifier = Identifier.new(blockName),
            .properties = properties,
            .blocks = blocks,
        };
    }

    /// Parses a property:
    /// property := identifier ":" value
    fn parseProperty(state: *State) !Property {
        // Expect property name (identifier).
        const idToken = state.current_token() orelse return ParseError.EXPECTED_IDENTIFIER;
        if (idToken.type != TokenType.identifier) {
            return ParseError.EXPECTED_IDENTIFIER;
        }
        const propName = idToken.lexeme orelse unreachable;
        state.current += 1; // consume identifier

        // Expect colon.
        const colon = state.current_token() orelse return ParseError.UNEXPECTED_TOKEN;
        if (colon.type != TokenType.colon) {
            return ParseError.UNEXPECTED_TOKEN;
        }
        state.current += 1; // consume ':'

        // Parse the property value.
        const value = try Parser.parseValue(state);
        return Property{
            .identifier = Identifier.new(propName),
            .value = value,
        };
    }

    /// Parses a value:
    /// value := number | vec3
    /// vec3 := "(" number "," number "," number ")"
    fn parseValue(state: *State) !Value {
        const token = state.current_token() orelse return ParseError.UNEXPECTED_TOKEN;

        // Helper function to parse a potentially negative number
        const parseNumber = struct {
            fn parse(s: *State) !f32 {
                var neg = false;
                if (s.current_token()) |t| {
                    if (t.type == TokenType.minus) {
                        neg = true;
                        s.current += 1; // consume minus
                    }
                }

                const numToken = s.current_token() orelse return ParseError.UNEXPECTED_TOKEN;
                if (numToken.type != TokenType.number) return ParseError.UNEXPECTED_TOKEN;
                const num = try parseFloat(numToken.lexeme orelse unreachable);
                s.current += 1; // consume number

                return if (neg) -num else num;
            }
        }.parse;

        if (token.type == TokenType.left_paren) {
            // Parse as a vec3.
            state.current += 1; // consume '('

            // Parse three numbers separated by commas
            const x = try parseNumber(state);

            // Expect comma.
            const comma1 = state.current_token() orelse return ParseError.UNEXPECTED_TOKEN;
            if (comma1.type != TokenType.comma) return ParseError.UNEXPECTED_TOKEN;
            state.current += 1; // consume comma

            const y = try parseNumber(state);

            // Expect comma.
            const comma2 = state.current_token() orelse return ParseError.UNEXPECTED_TOKEN;
            if (comma2.type != TokenType.comma) return ParseError.UNEXPECTED_TOKEN;
            state.current += 1; // consume comma

            const z = try parseNumber(state);

            // Expect closing parenthesis
            const right = state.current_token() orelse return ParseError.UNEXPECTED_TOKEN;
            if (right.type != TokenType.right_paren) return ParseError.UNEXPECTED_TOKEN;
            state.current += 1; // consume ')'

            return Value{ .vector = Vector{ .x = x, .y = y, .z = z } };
        } else if (token.type == TokenType.number or token.type == TokenType.minus) {
            // Parse as a single number
            const num = try parseNumber(state);
            return Value{ .number = num };
        } else {
            return ParseError.UNEXPECTED_TOKEN;
        }
    }

    /// Helper function to parse a floating-point number from a token’s lexeme.
    fn parseFloat(s: []const u8) !f32 {
        return try std.fmt.parseFloat(f32, s);
    }
};
