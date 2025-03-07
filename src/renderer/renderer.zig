// graphics/renderer.zig
const std = @import("std");
const c = @import("../bindings/c.zig");
const err = @import("../core/gl.zig");

const Model = @import("model.zig").Model;
const Mesh = @import("mesh.zig").Mesh;
const Material = @import("material.zig").Material;

const Mat4f = @import("../math/matrix.zig").Mat4f;


/// Configuration struct for renderer initialization
pub const RendererConfig = struct {
    clear_color: [4]f32 = .{ 0.0, 0.0, 0.0, 1.0 },
    
    polygon_mode: PolygonMode = .fill,

    depth_function: DepthFunc = .less,
    cull_face_mode: CullFaceMode = .back, 
    front_face_winding: FrontFaceWinding = .ccw,
    
    // Default viewport
    initial_viewport: ?struct {
        x: i32,
        y: i32, 
        width: i32,
        height: i32,
    } = null,
};


pub const Renderer = struct {
    allocator: std.mem.Allocator,

    config: RendererConfig,


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    /// Initialize a new renderer with configuration
    pub fn create(allocator: std.mem.Allocator, config: RendererConfig) !*Renderer {
        const render_ptr = try allocator.create(Renderer);
        render_ptr.* = .{
            .allocator = allocator,
            .config = config,
        };
        
        // Apply initial configuration
        try render_ptr.applyConfig();
        
        return render_ptr;
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    /// Apply the current configuration to OpenGL state
    pub fn applyConfig(self: *Renderer) !void {

        // Set clear color
        self.setClearColor(self.config.clear_color);

        // Configure depth testing
        self.setDepthFunc(self.config.depth_function);

        // Configure face culling
        self.setCullFaceMode(self.config.cull_face_mode);
        self.setFrontFaceWinding(self.config.front_face_winding);

        // Set polygon mode
        self.setPolygonMode(self.config.polygon_mode);

        // Set initial viewport if specified
        if (self.config.initial_viewport) |viewport| {
            self.setViewport(viewport.x, viewport.y, viewport.width, viewport.height);
        }
    }


    /// Set the polygon rendering mode
    pub fn setPolygonMode(self: *Renderer, mode: PolygonMode) void {
        self.config.polygon_mode = mode;
        c.glPolygonMode(c.GL_FRONT_AND_BACK, mode.toGLConstant());
        err.checkGLError("setPolygonMode");
    }


    /// Set the depth test function
    pub fn setDepthFunc(self: *Renderer, func: DepthFunc) void {
        self.config.depth_function = func;

        if (func != .none) {
            c.glEnable(c.GL_DEPTH_TEST);
            c.glDepthFunc(func.toGLConstant());
        } else {
            c.glDisable(c.GL_DEPTH_TEST);
        }

        err.checkGLError("setDepthFunc");
    }


    /// Set which faces to cull
    pub fn setCullFaceMode(self: *Renderer, mode: CullFaceMode) void {
        self.config.cull_face_mode = mode;

        if (mode != .none) {
            c.glEnable(c.GL_CULL_FACE);
            c.glCullFace(mode.toGLConstant());
        } else {
            c.glDisable(c.GL_CULL_FACE);
        }
        err.checkGLError("setCullFaceMode");
    }


    /// Set the front face winding order
    pub fn setFrontFaceWinding(self: *Renderer, winding: FrontFaceWinding) void {
        self.config.front_face_winding = winding;
        c.glFrontFace(winding.toGLConstant());
        err.checkGLError("setFrontFaceWinding");
    }


    pub fn clear(self: *Renderer) void {
        _ = self;
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        err.checkGLError("glClear");
    }


    pub fn setClearColor(self: *Renderer, color: [4]f32) void {
        self.config.clear_color = color;
        c.glClearColor(color[0], color[1], color[2], color[3]);
        err.checkGLError("glClearColor");
    }


    pub fn setViewport(self: *Renderer, x: i32, y: i32, width: i32, height: i32) void {
        _ = self;
        c.glViewport(x, y, width, height);
        err.checkGLError("glViewport");
    }


    // Updated draw function to accept Mesh
    pub fn drawMesh(self: *Renderer, mesh: *Mesh, material: *Material, model_matrix: *Mat4f, view_matrix: *Mat4f, projection_matrix: *Mat4f) !void {
        _ = self;

        try material.use();

        if (material.shader.uniform_cache.contains("model")) {
            const model_matrix_cnst = &model_matrix.data;
            try material.shader.setUniformMat4("model", model_matrix_cnst);
        }
        if (material.shader.uniform_cache.contains("view")) {
            const view_matrix_cnst = &view_matrix.data;
            try material.shader.setUniformMat4("view", view_matrix_cnst);
        }
        if (material.shader.uniform_cache.contains("projection")) {
            const projection_matrix_cnst = &projection_matrix.data;
            try material.shader.setUniformMat4("projection", projection_matrix_cnst);
        }

        mesh.bind(); // Bind Mesh

        // (Optional) If you need to retrieve the current program, do it correctly:
        var current_program_id: c.GLint = 0;
        c.glGetIntegerv(c.GL_CURRENT_PROGRAM, &current_program_id);
        err.checkGLError("glGetIntegerv");

        mesh.draw(); // Draw Mesh
    }


    pub fn drawModel(self: *Renderer, model: *Model, model_matrix: *Mat4f, view_matrix: *Mat4f, projection_matrix: *Mat4f) !void {

        // Iterate over each mesh-material pair
        for (model.pairs.items) |pair| {

            // Draw the mesh using the model's world matrix
            try self.drawMesh(pair.mesh, pair.material, model_matrix, view_matrix, projection_matrix);
        }
    }


    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    pub fn release(self: *Renderer) void {
        self.allocator.destroy(self);
    }
};


/// Polygon rendering modes
pub const PolygonMode = enum {
    fill,
    line,
    point,
    
    /// Convert enum to OpenGL constants
    pub fn toGLConstant(self: PolygonMode) c.GLenum {
        return switch (self) {
            .fill => c.GL_FILL,
            .line => c.GL_LINE,
            .point => c.GL_POINT,
        };
    }
};


/// Depth test function options
pub const DepthFunc = enum {
    none,
    less,
    less_equal,
    greater,
    greater_equal,
    equal,
    not_equal,
    always,
    never,
    
    /// Convert enum to OpenGL constants
    pub fn toGLConstant(self: DepthFunc) c.GLenum {
        return switch (self) {
            .none => 0,
            .less => c.GL_LESS,
            .less_equal => c.GL_LEQUAL,
            .greater => c.GL_GREATER,
            .greater_equal => c.GL_GEQUAL,
            .equal => c.GL_EQUAL,
            .not_equal => c.GL_NOTEQUAL,
            .always => c.GL_ALWAYS,
            .never => c.GL_NEVER,
        };
    }
};


/// Enum for face culling modes
pub const CullFaceMode = enum {
    none,
    front,
    back,
    front_and_back,
    
    /// Convert to OpenGL constants
    pub fn toGLConstant(self: CullFaceMode) c.GLenum {
        return switch (self) {
            .none => 0, // Special case, will disable culling
            .front => c.GL_FRONT,
            .back => c.GL_BACK,
            .front_and_back => c.GL_FRONT_AND_BACK,
        };
    }
};



pub const FrontFaceWinding = enum {
    ccw,
    cw,

    pub fn toGLConstant(self: FrontFaceWinding) c.GLenum {
        return switch (self) {
            .ccw => c.GL_CCW, // Counter-clockwise
            .cw => c.GL_CW, // Clockwise
        };
    }
};

