const std = @import("std");
const zune = @import("zune"); // The Engine
const c = @import("zune").c;

pub fn main() !void {
    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    //setup time utitilites
    var time = zune.utils.Time.Time.init(.{
        .target_fps = 60,
        .fixed_timestep = 1.0 / 60.0,
    });

    // setup the input system
    var input = try zune.core.Input.init(allocator);
    defer input.deinit();

    // create a window
    const window = try zune.core.Window.init(allocator, .{
        .title = "Zune test",
        .width = 800,
        .height = 600,
        .transparent = false,
        .decorated = true,
    });
    defer window.deinit();

    // create a renderer
    var renderer = try zune.graphics.Renderer.init(allocator);
    defer renderer.deinit();

    // create a camera
    var camera = zune.core.PerspectiveCamera.init(std.math.degreesToRadians(45.0), 800.0 / 600.0, 0.1, 100.0);
    camera.setPosition(0.0, 0.0, 5.0);
    camera.lookAt(0.0, 0.0, 0.0);

    // -----------

    window.centerWindow();
    renderer.setClearColor(.{ 0.1, 0.1, 0.1, 1.0 });

    // Create a simple triangle mesh
    const vertices = [_]f32{
        // positions      // texture coords
        0.0, 0.5, 0.0, 0.5, 1.0, // top
        -0.5, -0.5, 0.0, 0.0, 0.0, // left
        0.5, -0.5, 0.0, 1.0, 0.0, // right
    };

    const indices = [_]u32{ 0, 1, 2 };

    // Define Vertex Layout
    const vertex_layout = zune.graphics.VertexLayout{
        .descriptors = &[_]zune.graphics.VertexAttributeDescriptor{
            .{ .attribute_type = .Position, .data_type = c.GL_FLOAT },
            .{ .attribute_type = .TexCoord, .data_type = c.GL_FLOAT },
        },
    };

    var triangle = try zune.graphics.VertexBuffer.init(
        &vertices,
        &indices,
        vertex_layout, // Pass VertexLayout here
    );
    defer triangle.deinit();

    // Get the default shader and cache uniforms
    var shader = renderer.default_shader;
    try shader.cacheUniform("model", .Mat4);
    try shader.cacheUniform("view", .Mat4);
    try shader.cacheUniform("projection", .Mat4);
    try shader.cacheUniform("color", .Vec4);

    // Set viewport
    const size = window.getSize();
    renderer.setViewport(0, 0, @intCast(size.width), @intCast(size.height));

    // Simple model matrix (identity)
    const model = [16]f32{
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    };

    while (!window.shouldClose()) {
        // Update timing
        time.update();
        input.update();

        // Regular updates (every frame)
        const dt = time.getDelta();
        _ = dt; // Update game state with dt...

        // input
        if (input.isKeyPressed(zune.core.Input.Key.SPACE)) {
            window.setTitle("wow sick");
            std.debug.print("ye", .{});
        }

        // Clear the screen
        renderer.clear();
        zune.err.gl.checkGLError("after clear");

        // --------------------------------------------------------

        // Use shader and set uniforms
        renderer.useShader(shader);
        zune.err.gl.checkGLError("after shader use");

        try shader.setUniformMat4("model", &model);
        try shader.setUniformMat4("view", &camera.base.view_matrix);
        try shader.setUniformMat4("projection", &camera.base.projection_matrix);
        try shader.setUniformVec4("color", .{ 1.0, 0.0, 0.0, 1.0 }); // Bright red color
        zune.err.gl.checkGLError("After setting uniforms");

        // Bind and draw triangle
        triangle.bind();
        zune.err.gl.checkGLError("After bind");

        triangle.draw();
        zune.err.gl.checkGLError("After draw");

        // --------------------------------------------------------

        // Fixed updates (at fixed timestep intervals)
        while (time.shouldFixedUpdate()) {
            const fixed_dt = time.getFixedTimestep();
            _ = fixed_dt;
            // Update physics with fixed_dt...
        }

        // Print FPS every second
        if (time.fps.timer >= 1.0) {
            std.debug.print("FPS: {d:.2}\n", .{time.getFPS()});
        }

        window.pollEvents();
        window.swapBuffers();
    }
}
