# Zune - A Zig-based OpenGL Game Engine

Zune is a 2D/3D game engine being developed in the [Zig programming language](https://ziglang.org/), using both OpenGL and GLFW. 
It started as a personal project written in the programming language Odin, but I have since decided to
re-write the framework in the Zig programming language because i have taken a liking to it.


## Features

- **3D-first architecture** – While 2D rendering is possible, all objects exist within 3D world space.
- **High-level API design** – Provides relatively high-level API with low-level control.
- **Entity Component System (ECS)** – Modular and extensible entity management.
- **Efficient resource management** – Optimized handling of textures, shaders, and models.


## Installation

1. Install [Zig 0.14.0](https://ziglang.org/download/)
2. Clone the repository:
   ```sh
   git clone https://github.com/Mrso73/zune.git
   cd zune
   ```
3. Build the project:
   ```sh
   zig build
   ```


## Roadmap

### Core Functionality
- [x] Input system
- [x] Simple resource manager
- [ ] Key-mapping functionality
- [ ] Collision detection system


### Rendering
- [x] Rendering System (Models, meshs, Materials, Textures, and Shaders)
- [x] Primitive shape rendering
- [x] Camera system
- [ ] Lighting system


### Entity Component System (ECS)
- [x] Initial ECS implementation
- [ ] Improved query customization


## Showcase

![Polygon Heightmap](img/img1.png?raw=true "Polygon Heightmap")


## Dependencies

The zune Engine currently only uses C/C++ for third-party libraries, because C is a beautifull language and C++ has a very mature ecosystem.

Currently used libraries are:
- Eigen (C++ library for linear algebra)
- glad (C library for talking to OpenGL)
- glfw (C library for window creation and input devices)
- stb_image (C library for reading of images)


## Contributing
Contributions are welcome! Feel free to open issues, suggest features, or submit pull requests.


