const Vec3 = @import("math.zig").Vec3;
const Sphere = @import("shape.zig").Sphere;
const Block = @import("parser.zig").Block;
const Value = @import("parser.zig").Value;
const Property = @import("parser.zig").Property;
const std = @import("std");

pub const Scene = struct {
    camera: Camera,
    screen: Screen,
    light: Light,
    shapes: []Shape,
};

pub const Camera = struct {
    position: Vec3,
    direction: Vec3,
    focal_distance: f32,
};

pub const Screen = struct {
    width: f32,
    height: f32,
};

pub const Light = struct {
    position: Vec3,
    color: Vec3,
};

pub const Shape = union(enum) {
    Sphere: Sphere,
};

pub const InterpreterError = error{ MissingRequiredProperty, LightAlreadyDefined, ScreenAlreadyDefined, CameraAlreadyDefined, InvalidCamera, InvalidScreen, InvalidLight, InvalidShape, InvalidScene, UnknownBlockIdentifier, MissingRequiredBlock };

pub const Interpreter = struct {
    pub fn interpret(ast: Block, allocator: std.mem.Allocator) !Scene {
        var camera: ?Camera = null;
        var screen: ?Screen = null;
        var light: ?Light = null;
        var shapes = std.ArrayList(Shape).init(allocator);
        errdefer shapes.deinit();

        if (!stringEquals(ast.identifier.name, "Scene")) {
            return InterpreterError.InvalidScene;
        }

        for (ast.blocks) |block| {
            if (stringEquals(block.identifier.name, "camera")) {
                if (camera != null) {
                    return InterpreterError.CameraAlreadyDefined;
                }

                var position: ?Vec3 = null;
                var direction: ?Vec3 = null;
                var focal_distance: ?f32 = null;

                for (block.properties) |prop| {
                    if (stringEquals(prop.identifier.name, "position")) {
                        if (prop.value == .vector) {
                            const vec = prop.value.vector;
                            position = Vec3{ .x = vec.x, .y = vec.y, .z = vec.z };
                        }
                    } else if (stringEquals(prop.identifier.name, "direction")) {
                        if (prop.value == .vector) {
                            const vec = prop.value.vector;
                            direction = Vec3{ .x = vec.x, .y = vec.y, .z = vec.z };
                        }
                    } else if (stringEquals(prop.identifier.name, "focal_distance")) {
                        if (prop.value == .number) {
                            focal_distance = prop.value.number;
                        }
                    } else {
                        return InterpreterError.InvalidCamera;
                    }
                }

                if (position != null and direction != null and focal_distance != null) {
                    camera = Camera{
                        .position = position.?,
                        .direction = direction.?,
                        .focal_distance = focal_distance.?,
                    };
                } else {
                    return InterpreterError.InvalidCamera;
                }
            } else if (stringEquals(block.identifier.name, "screen")) {
                if (screen != null) {
                    return InterpreterError.ScreenAlreadyDefined;
                }

                if (block.properties.len == 0) {
                    return InterpreterError.InvalidScreen;
                }

                var width: ?f32 = null;
                var height: ?f32 = null;

                for (block.properties) |prop| {
                    if (stringEquals(prop.identifier.name, "width")) {
                        if (prop.value == .number) {
                            width = prop.value.number;
                        }
                    } else if (stringEquals(prop.identifier.name, "height")) {
                        if (prop.value == .number) {
                            height = prop.value.number;
                        }
                    } else {
                        return InterpreterError.InvalidScreen;
                    }
                }

                if (width != null and height != null) {
                    screen = Screen{
                        .width = width.?,
                        .height = height.?,
                    };
                } else {
                    return InterpreterError.InvalidScreen;
                }
            } else if (stringEquals(block.identifier.name, "light")) {
                if (light != null) {
                    return InterpreterError.LightAlreadyDefined;
                }

                var position: ?Vec3 = null;
                var color: ?Vec3 = null;

                for (block.properties) |prop| {
                    if (stringEquals(prop.identifier.name, "position")) {
                        if (prop.value == .vector) {
                            position = Vec3{ .x = prop.value.vector.x, .y = prop.value.vector.y, .z = prop.value.vector.z };
                        }
                    } else if (stringEquals(prop.identifier.name, "color")) {
                        if (prop.value == .vector) {
                            color = Vec3{ .x = prop.value.vector.x, .y = prop.value.vector.y, .z = prop.value.vector.z };
                        }
                    } else {
                        return InterpreterError.InvalidScreen;
                    }
                }

                if (position == null or color == null) {
                    return InterpreterError.MissingRequiredProperty;
                }

                light = Light{
                    .position = position.?,
                    .color = color.?,
                };
            } else if (stringEquals(block.identifier.name, "sphere")) {
                // Sphere parsing logic here (not implemented yet)
            } else {
                return InterpreterError.UnknownBlockIdentifier;
            }
        }

        // this needs to updated as this feature is built out
        if (camera == null or screen == null) {
            return InterpreterError.MissingRequiredBlock;
        }

        return Scene{
            .camera = camera.?,
            .screen = screen.?,
            .light = light.?,
            .shapes = try shapes.toOwnedSlice(),
        };
    }
};

pub fn stringEquals(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}
