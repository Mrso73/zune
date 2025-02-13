const std = @import("std");
const Model = @import("../../graphics/model.zig").Model;

pub const ModelComponent = struct {
    model: *Model,
    visible: bool, // Can be extended later with render flags/options
    
    pub fn init(model: *Model) ModelComponent {
        return .{
            .model = model,
            .visible = true,
        };
    }
};
