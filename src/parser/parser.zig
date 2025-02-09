const std = @import("std");
const Token = @import("tokenizer.zig").Token;
const TokenType = @import("tokenizer.zig").TokenType;

pub const Result = error{ DOES_NOT_START_WITH_SCENE, UNEXPECTED_LEXEME };

pub const Vector = struct { x: f32, y: f32, z: f32 };

pub const Value = union { number: f32, vector: Vector };

pub const Identifier = struct { name: []const u8 };

pub const Property = struct { identifier: Identifier, value: Value };

pub const Block = struct { identifier: Identifier, properties: []const Property };

pub const Scene = struct {
    identifier: Identifier,
    blocks: []const Block,
};

pub const ParseError = error{ NO_TOKENS, SCENE_NOT_OPENED, SCENE_NOT_CLOSED };

pub const Parser = struct {
    const State = struct {
        tokens: std.ArrayList(Token),
        scene: Scene,
        current: usize,
        allocator: std.mem.Allocator,

        pub fn init(tokens: std.ArrayList(Token), allocator: std.mem.Allocator) State {
            return State{ .tokens = tokens, .scene = undefined, .current = 0, .allocator = allocator };
        }

        pub fn increment(self: *State) void {
            self.current += 1;
        }

        pub fn current_token(self: *State) ?*Token {
            if (self.current >= self.tokens.items.len) {
                return null;
            }

            return &self.tokens.items[self.current];
        }

        pub fn jump_next(self: *State) ?*Token {
            self.increment();
            return self.current_token();
        }
    };

    pub fn parse(tokens: std.ArrayList(Token), allocator: std.mem.Allocator) !*Scene {
        if (tokens.items.len == 0) {
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

            // Initialize the scene (e.g., parse blocks and properties)
            // For now, we'll just set it up with dummy data
            scene.blocks = &[_]Block{
                Block{
                    .identifier = Identifier{ .name = "block1" },
                    .properties = &[_]Property{
                        Property{
                            .identifier = Identifier{ .name = "property1" },
                            .value = Value{ .number = 1.0 },
                        },
                    },
                },
            };

            // parseBlock();

            const close = state.jump_next() orelse return ParseError.SCENE_NOT_CLOSED;
            if (close.type != TokenType.right_brace) {
                return ParseError.SCENE_NOT_CLOSED;
            }
            std.debug.print("\nlexeme: {s}\n", .{close.lexeme.?});

            return scene;
        }

        return ParseError.SCENE_NOT_OPENED;
    }
};
