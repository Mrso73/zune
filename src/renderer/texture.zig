// graphics/texture.zig

const std = @import("std");
const c = @import("../bindings/c.zig");
const err = @import("../core/gl.zig");

pub const TextureError = error{
    TextureLoadFailed,
    InvalidTextureData,
    InvalidTextureFormat,
    OpenGLError,
};

pub const Texture = struct {
    id: c.GLuint,
    width: i32,
    height: i32,
    channels: i32,

    ref_count: std.atomic.Value(u32),
    allocator: std.mem.Allocator,
    


    // ============================================================
    // Public API: Creation Functions
    // ============================================================

    // In your Texture.createFromFile function
    pub fn createFromFile(allocator: std.mem.Allocator, path: []const u8) !*Texture {
        // Check if file exists first
        const file = try std.fs.cwd().openFile(path, .{});
        file.close();

        const normalized_path = try std.fs.path.resolve(allocator, &[_][]const u8{path});
        defer allocator.free(normalized_path);

        const texture_ptr = try allocator.create(Texture);
        errdefer allocator.destroy(texture_ptr);

        texture_ptr.* = try initFromFile(allocator, normalized_path);
        texture_ptr.allocator = allocator;
        texture_ptr.ref_count = std.atomic.Value(u32).init(1);
        return texture_ptr;
    }


    // ============================================================
    // Public API: Operational Functions
    // ============================================================

    pub fn addRef(self: *Texture) void {
        _ = self.ref_count.fetchAdd(1, .monotonic);
    }


    /// Binds the texture to a specified texture unit.
    pub fn bind(self: *Texture, textureUnit: c_int) void {
        const texture_unit = c.GL_TEXTURE0 + textureUnit;
        c.glActiveTexture(@intCast(texture_unit));
        c.glBindTexture(c.GL_TEXTURE_2D, self.id);
        err.checkGLError("glBindTexture");
    }


    pub fn printInfo(self: *Texture) void {
        std.debug.print("Texture Info:\n", .{});
        std.debug.print("  ID: {}\n", .{self.id});
        std.debug.print("  Dimensions: {}x{}\n", .{ self.width, self.height });
        std.debug.print("  Channels: {}\n", .{self.channels});
        std.debug.print("  Ref Count: {}\n", .{self.ref_count});
    }


    // ============================================================
    // Public API: Destruction Function
    // ============================================================

    /// Deletes the texture object.
    pub fn release(self: *Texture) u32 {
        const prev = self.ref_count.fetchSub(1, .monotonic);
        if (prev == 1) {
            c.glDeleteTextures(1, &self.id);
            err.checkGLError("glDeleteTextures");

            // Free the Texture struct allocated by the allocator.
            self.allocator.destroy(self);
        }
        return prev;
    }


    // ============================================================
    // Private Helper Functions
    // ============================================================


    /// Loads a texture from file using stb_image.
    /// - path: a null-terminated string containing the file path.
    fn initFromFile(allocator: std.mem.Allocator, path: []const u8) !Texture {
        std.debug.print("Attempting to load texture from path: {s}\n", .{path});

        // Create a null-terminated copy of the path
        const c_path = try allocator.dupeZ(u8, path);
        defer allocator.free(c_path);

        var w: i32 = 0;
        var h: i32 = 0;
        var n: i32 = 0;
        
        c.stbi_set_flip_vertically_on_load(1);

        // Force image to load with 4 channels (RGBA)
        const data = c.stbi_load(c_path.ptr, &w, &h, &n, 4);
        if (data == null) {
            const err_msg = c.stbi_failure_reason();
            std.debug.print("STBI loading failed: {s}\n", .{err_msg});
            return TextureError.TextureLoadFailed;
        }
        defer c.stbi_image_free(data);

        // Validate dimensions
        if (w <= 0 or h <= 0) {
            std.debug.print("Invalid texture dimensions: {}x{}\n", .{ w, h });
            return TextureError.InvalidTextureData;
        }

        // Generate and bind texture first
        var texture_id: c.GLuint = undefined;
        c.glGenTextures(1, &texture_id);

        // Check if texture was created successfully
        if (texture_id == 0) {
            return TextureError.OpenGLError;
        }
        errdefer c.glDeleteTextures(1, &texture_id);  // Clean up if anything fails after this point

        // Bind the texture and verify binding
        c.glBindTexture(c.GL_TEXTURE_2D, texture_id);
        if (c.glGetError() != c.GL_NO_ERROR) {
            return TextureError.OpenGLError;
        }

        // Set wrapping parameters
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
        
        // Set filtering parameters
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR_MIPMAP_LINEAR);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

        // We're now forcing RGBA format
        const format = c.GL_RGBA;
        const internal_format = c.GL_RGBA8;

        // Upload the texture data with error checking
        c.glTexImage2D(
            c.GL_TEXTURE_2D,
            0,
            @intCast(internal_format),
            w,
            h,
            0,
            format,
            c.GL_UNSIGNED_BYTE,
            data,
        );

        // Check for upload errors
        const openglerr = c.glGetError();
        if (openglerr != c.GL_NO_ERROR) {
            std.debug.print("OpenGL error during texture upload: 0x{x}\n", .{openglerr});
            return TextureError.OpenGLError;
        }

        // Generate mipmaps with error checking
        c.glGenerateMipmap(c.GL_TEXTURE_2D);
        if (c.glGetError() != c.GL_NO_ERROR) {
            return TextureError.OpenGLError;
        }

        return Texture{
            .id = texture_id,
            .width = w,
            .height = h,
            .channels = 4,  // forcing RGBA
            .allocator = allocator,
            .ref_count = std.atomic.Value(u32).init(1),
        };
    }
};
