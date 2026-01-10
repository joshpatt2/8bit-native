# 8-Bit Native Engine

A retro-style game engine using Metal for GPU-accelerated rendering on macOS.

## Current Status

**Milestone 1: Sprite Rendering** ✅ COMPLETE
- Metal renderer with sprite shader pipeline
- PNG texture loading via stb_image
- Alpha transparency support
- Orthographic projection (NES-style coordinates)
- Full unit test coverage (28 tests passing)

## Features

### Rendering
- Metal-based GPU rendering
- Vertex/fragment shader system
- Texture loading (PNG with alpha)
- Nearest-neighbor sampling (pixel-perfect)
- Alpha cutoff transparency (hard edge @ 0.5)

### Engine Components
- `Renderer` - Metal device, command queue, render pipeline
- `Shader` - Runtime Metal shader compilation
- `Texture` - PNG loading and GPU upload

### Test Suite
- 11 texture loading tests
- 10 shader compilation tests  
- 7 renderer lifecycle tests
- Custom test framework (no external dependencies)

## Building

### Requirements
- macOS with Metal support
- CMake 3.20+
- SDL2
- Xcode Command Line Tools (for Metal framework)

### Build Steps
```bash
mkdir build
cd build
cmake ..
make
```

### Run Application
```bash
./8bit-native
```

### Run Tests
```bash
ctest --output-on-failure
# Or run individual test suites:
./tests/texture-tests
./tests/shader-tests
./tests/renderer-tests
```

## Project Structure

```
8bit-native/
├── src/
│   ├── main.mm              # Entry point
│   └── engine/
│       ├── Renderer.hpp/mm  # Metal rendering backend
│       ├── Shader.hpp/mm    # Shader compilation
│       ├── Texture.hpp/mm   # Texture loading
│       └── stb_image.h      # PNG decoder
├── shaders/
│   └── sprite.metal         # Sprite vertex/fragment shaders
├── assets/
│   └── sprites/
│       └── test.png         # Test sprite (32x32)
├── tests/
│   ├── TextureTests.mm      # Texture loading tests
│   ├── ShaderTests.mm       # Shader compilation tests
│   ├── RendererTests.mm     # Renderer lifecycle tests
│   ├── TestFramework.hpp    # Lightweight test framework
│   └── assets/              # Test fixtures
└── CMakeLists.txt
```

## Architecture Notes

### Coordinate System
- Orthographic projection: -128 to +128 (X), -120 to +120 (Y)
- Origin at center of screen
- Matches NES resolution (256x240)

### Rendering Pipeline
1. `beginFrame()` - Acquire drawable, create command buffer
2. `drawSprite()` - Upload uniforms, bind textures, draw quad
3. `endFrame()` - Commit commands, present drawable

### Shader Interface
- Vertex attributes: position (float2), texCoord (float2)
- Uniforms: MVP matrix (float4x4)
- Fragment: texture (texture2d), sampler (nearest-neighbor)

## Roadmap

See [ROADMAP-v1.md](ROADMAP-v1.md) for planned features.

**Next milestones:**
- Sprite batching (multiple sprites per frame)
- Sprite animation system
- Input handling
- Game loop timing

## Development

### Adding New Tests
Tests use a minimal custom framework in `tests/TestFramework.hpp`:

```cpp
TEST(MyNewTest) {
    // Your test code
    ASSERT_TRUE(condition, "message");
    ASSERT_EQUAL(a, b, "message");
}
```

### Shader Development
Shaders are compiled at runtime from source. Edit `shaders/*.metal` and rerun.

### Performance
- Current: Single sprite rendering
- Target: 100+ sprites @ 60fps (batched rendering)

## License

[Specify license]

## Credits

- stb_image by Sean Barrett (public domain)
- SDL2 (zlib license)
