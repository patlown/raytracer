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
    blocks: []const Block,
};

pub const Parser = struct {
    pub fn parse(tokens: std.ArrayList(Token)) !Scene {

        // for now, return a dummy scene with predefined blocks and properties
        std.debug.print("tokens len: {}", .{tokens.items.len});
        return Scene{
            .blocks = &[_]Block{
                Block{
                    .identifier = Identifier{ .name = "block1" },
                    .properties = &[_]Property{
                        Property{
                            .identifier = Identifier{ .name = "property1" },
                            .value = Value{ .number = 1.0 },
                        },
                    },
                },
                Block{
                    .identifier = Identifier{ .name = "block2" },
                    .properties = &[_]Property{
                        Property{
                            .identifier = Identifier{ .name = "property2" },
                            .value = Value{ .number = 2.0 },
                        },
                    },
                },
            },
        };
    }
};
