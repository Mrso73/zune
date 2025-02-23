# Zune - A Zig-based OpenGL Game Engine

Zune is a 2D/3D game engine being developed in the [Zig programming language](https://ziglang.org/), using both OpenGL and GLFW. 
It started as a personal project written in the programming language Odin, but I have since decided to
re-write the framework in the Zig programming language because i have taken a liking to it.


## Features

- **3D-first architecture** – While 2D rendering is possible, all objects exist within a 3D world space.
- **High-level design with low-level access** – Provides an intuitive API while allowing fine-grained control when needed.
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
- [x] Basic input system
- [x] Simple resource manager
- [ ] Enhanced input handling
- [ ] Collision detection system


### Rendering
- [x] Model, mesh, material, texture, and shader system
- [x] Camera system
- [x] Primitive shape rendering
- [ ] Lighting system


### Entity Component System (ECS)
- [x] Initial ECS implementation
- [ ] Improved query customization


## Contributing
Contributions are welcome! Feel free to open issues, suggest features, or submit pull requests.


