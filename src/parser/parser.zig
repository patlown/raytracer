const std = @import("std");
const Token = @import("tokenizer.zig").Token;
const TokenType = @import("tokenizer.zig").TokenType;

pub const Vector = struct { x: f32, y: f32, z: f32 };

pub const Value = union { number: f32, vector: Vector };

pub const Identifier = struct {
    name: []const u8,
    pub fn new(name: []const u8) Identifier {
        return Identifier{ .name = name };
    }
};

pub const Property = struct { identifier: Identifier, value: Value };

pub const Block = struct { identifier: Identifier, properties: []const Property };

pub const Scene = struct {
    identifier: Identifier,
    blocks: []const Block,
};

pub const ParseError = error{ NO_TOKENS, SCENE_NOT_OPENED, SCENE_NOT_CLOSED, EXPECTED_IDENTIFIER, BlOCK_NOT_OPENED, BLOCK_NOT_CLOSED };

pub const Parser = struct {
    const State = struct {
        tokens: []const Token,
        scene: Scene,
        current: usize,
        allocator: std.mem.Allocator,

        pub fn init(tokens: []const Token, allocator: std.mem.Allocator) State {
            return State{ .tokens = tokens, .scene = undefined, .current = 0, .allocator = allocator };
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

            return &self.tokens[self.current];
        }
    };

    pub fn parse(tokens: []const Token, allocator: std.mem.Allocator) !*Scene {
        if (tokens.len == 0) {
            return ParseError.NO_TOKENS;
        }

        var state = Parser.State.init(tokens, allocator);

        const first = state.current_token();

        if (first) |f| {
            if (f.type != TokenType.identifier) {
                return ParseError.SCENE_NOT_OPENED;
            }

            std.debug.print("\nlexeme: {s}\n", .{f.lexeme.?});

            if (!std.mem.eql(u8, f.lexeme orelse unreachable, "scene")) {
                return ParseError.SCENE_NOT_OPENED;
            }

            const open = state.jump_next() orelse return ParseError.SCENE_NOT_OPENED;
            std.debug.print("\nlexeme: {s}\n", .{open.lexeme.?});

            if (open.type != TokenType.left_brace) {
                return ParseError.SCENE_NOT_OPENED;
            }

            const scene = try allocator.create(Scene);
            scene.identifier = Identifier.new("scene");

            state.increment();
            scene.blocks = try Parser.parseBlocks(&state);

            const close = state.current_token() orelse return ParseError.SCENE_NOT_CLOSED;
            if (close.type != TokenType.right_brace) {
                return ParseError.SCENE_NOT_CLOSED;
            }
            std.debug.print("\nlexeme: {s}\n", .{close.lexeme.?});

            return scene;
        }

        return ParseError.SCENE_NOT_OPENED;
    }

    fn parseBlocks(state: *Parser.State) ![]const Block {
        var token = state.current_token();
        var blocks = std.ArrayList(Block).init(state.allocator);
        errdefer blocks.deinit();

        while (token) |t| : (token = null) {
            std.debug.print("\ntoken in parse blocks: {s}\n", .{t.lexeme.?});
            switch (t.type) {
                TokenType.identifier => {
                    if (state.jump_next()) |next| {
                        if (next.type != TokenType.left_brace) {
                            return ParseError.BlOCK_NOT_OPENED;
                        }
                    } else {
                        return ParseError.BlOCK_NOT_OPENED;
                    }

                    // parse inner block
                    const block = Block{
                        .identifier = Identifier.new(t.lexeme orelse return ParseError.EXPECTED_IDENTIFIER),
                        .properties = &[_]Property{},
                    };

                    try blocks.append(block);

                    if (state.jump_next()) |next| {
                        if (next.type != TokenType.right_brace) {
                            return ParseError.BLOCK_NOT_CLOSED;
                        }
                    } else {
                        return ParseError.BLOCK_NOT_CLOSED;
                    }
                },
                else => {
                    std.debug.print("\nthis should run\n", .{});
                    // we only expect identifiers, if we don't see one,
                    return blocks.toOwnedSlice();
                },
            }

            if (state.peek_next()) |p| {
                switch (p.type) {
                    TokenType.identifier => {
                        token = state.jump_next();
                    },
                    else => {
                        return blocks.toOwnedSlice();
                    },
                }
            }
        }

        return blocks.toOwnedSlice();
    }
};
