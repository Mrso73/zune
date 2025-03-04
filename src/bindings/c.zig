// c.zig
pub usingnamespace @cImport({
    @cInclude("glad/glad.h");
    @cInclude("glfw/glfw3.h");
    @cInclude("stb_image/stb_image.h");

    // Include our C wrapper for Eigen
    @cInclude("eigen_wrapper.h");
});
