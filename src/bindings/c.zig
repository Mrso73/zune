// c.zig

// Include engine libraries
pub usingnamespace @cImport({
    @cInclude("glad/glad.h");
    @cInclude("glfw/glfw3.h");
    @cInclude("stb_image/stb_image.h");

    // Include our C++ math library wrapper
    @cInclude("Eigen/eigen_wrapper.h");
});
