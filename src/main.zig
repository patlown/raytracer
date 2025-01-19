const std = @import("std");
const expect = std.testing.expect;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("ray tracer initialization...\n", .{});
    // to print a text circle, we'll need to do the following
    // will represent . for white pixels and x for black pixels
    // we'll represent a picture as an array (?) of arrays filled with either character x or .
    // let's start by just creating and printing an array

    // var pixels: [64][48]u8 = undefined;

    // & get address of pixels
    // * means row is a pointer type
    // for (&pixels) |*row| {
    //     // this function sets all the elements of a memory region to elem.
    //     @memset(row, 'x');
    // }

    const width: i32 = 64;
    const height: i32 = 48;
    const circle_radius: i32 = 5;

    const circle_center_x: i32 = @divFloor(width, 2);
    const circle_center_y: i32 = @divFloor(height, 2);

    var y: i32 = 0;
    while (y < height) : (y += 1) {
        var x: i32 = 0;
        while (x < width) : (x += 1) {
            const dx = x - circle_center_x;
            const dy = y - circle_center_y;
            if (dx * dx + dy * dy < circle_radius * circle_radius) {
                try stdout.print(".", .{});
            } else {
                try stdout.print("x", .{});
            }
        }
        try stdout.print("\n", .{});
    }
}
