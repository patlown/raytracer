const std = @import("std");

pub const Parser = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Parser {
        return Parser{
            .allocator = allocator,
        };
    }

    pub fn parse(self: *Parser, filename: []const u8) !void {
        const file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();

        const contents = try file.readToEndAlloc(self.allocator, std.math.maxInt(usize));
        defer self.allocator.free(contents);

        // Do parsing work here
    }
};
