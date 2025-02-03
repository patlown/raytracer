const Vec3 = @import("math.zig").Vec3;

pub const Scene = struct {
    pub const Light = struct {
        color: Vec3,
        source: Vec3,

        pub fn new(color: Vec3, source: Vec3) Light {
            return Light{ .color = color, .source = source };
        }
    };

    pub const LightColors = struct {
        pub const white = Vec3{ .x = 1.0, .y = 1.0, .z = 1.0 };
        pub const warm = Vec3{ .x = 1.0, .y = 0.85, .z = 0.6 };
        pub const cool = Vec3{ .x = 0.6, .y = 0.75, .z = 1.0 };
    };

    pub const Details = struct { camera_source: Vec3, focal_distance: f32, screen_height: f32, screen_width: f32, view_direction: Vec3, light: Light };
};
