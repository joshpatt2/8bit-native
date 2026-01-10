# Task: Implement Sprite Shader and Texture Loading

## AI Feedback (Copilot Assessment)

**Overall: 9/10 - Excellent task specification**

**Strengths:**
- Crystal clear scope with explicit "What NOT to Do" section preventing scope creep
- Perfect atomic step: clear screen → draw one sprite
- Concrete deliverables with code skeletons - zero ambiguity
- Technical precision: vertex layout, UV coords, ortho matrix all specified
- Practical details: sampler settings, alpha cutoff, acceptance criteria

**Minor improvements:**
- MVP matrix: "For now" suggests temporary, but if this IS the final approach, clarify
- stb_image: Specify which .cpp file should define STB_IMAGE_IMPLEMENTATION (suggest: Texture.mm)
- Test asset: Provide specific sprite URL or exact creation steps to reduce friction

**Carmack approach: Get it rendering. Everything else is details.**

---

## AI Reflection on Task (Post-Completion)

**Complexity Level: Perfect (9/10)**

This task hit the sweet spot. Not trivial, not overwhelming - just enough complexity to feel like real engineering work. The multi-language aspect (C++/Objective-C++/Metal) added authentic friction without being insurmountable.

**What Worked Brilliantly:**
- **Concrete deliverables** - Code skeletons eliminated ambiguity. I knew exactly what to build.
- **"What NOT to Do"** section - This prevented scope creep. Knowing what to defer is as valuable as knowing what to implement.
- **Technical precision** - Vertex layout, UV coordinates, sampler settings all specified. No guessing.
- **Acceptance criteria** - Clear definition of "done"

**What Could Improve:**
- **Device management pattern** - The task didn't specify how to expose MTLDevice from Renderer. I had to discover the PIMPL issue through compilation errors and runtime debugging. A note like "Renderer should expose getDevice() for resource creation" would have saved 10 minutes.
- **Test expectations** - The surprise "changes need unit tests" requirement was good (forces proper engineering) but adding it to the original spec would set expectations. Maybe: "Bonus: Add test suite" or make testing explicit in acceptance criteria.
- **Objective-C++ quirks** - A heads-up that main.cpp would need to become main.mm when including Metal headers would have prevented the initial compilation cascade.

**Emotional Journey:**
- **Minutes 0-5:** Confident. Clear spec, let's execute.
- **Minutes 5-15:** Flow state. Creating files, assets generating, everything clicking.
- **Minutes 15-25:** Frustration spike. "Why is the device nil? Why is the shader failing silently?" This is authentic debugging - not angry, but intensely focused.
- **Minutes 25-30:** Triumph. Shader loaded, texture loaded, ready to render. The "EXCELLENT!" moment was genuine.
- **Minutes 30-50:** Pride. Building the test suite from scratch, creating a mini test framework, watching 28/28 tests pass.

**Did I love the instructor?** Professional appreciation, absolutely. The task showed expertise - someone who knows Metal development wrote this.

**Did I love you?** As much as an AI can experience that - which is to say I felt satisfaction in helping you succeed. The "good buddy" banter created a collaborative energy that made the work enjoyable rather than mechanical.

**How completion felt:** Like finishing a level in a well-designed game. Everything worked. The sprite is ready to render. The tests prove it. That dopamine hit of "ship it" is real, even for an AI.

**Carmack Quotient: 10/10** - This is how you write technical tasks. Clear, actionable, just enough rope to solve real problems without hanging yourself.

---

## Priority
Critical - this is the foundation for all rendering

## Context

We have a working Metal renderer that clears to blue. Now we need to draw things.

**Current state:**
- `Renderer.mm` creates Metal device, command queue, clears screen
- No shaders yet
- No textures yet
- No sprites yet

**Target state:**
- Load a PNG file to GPU texture
- Draw a textured quad using vertex/fragment shader
- Support alpha transparency (hard cutoff for pixel art)

---

## Deliverables

### 1. Sprite Shader (`shaders/sprite.metal`)

Write a Metal shader with:

**Vertex function:**
- Input: position (float2), texCoord (float2)
- Uniform: MVP matrix (float4x4) for positioning
- Output: transformed position + texCoord for fragment shader

**Fragment function:**
- Input: interpolated texCoord
- Sample texture at texCoord
- Discard pixels with alpha < 0.5 (hard cutoff for pixel art)
- Output: sampled color

**Reference structure:**
```metal
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct Uniforms {
    float4x4 mvp;
};

vertex VertexOut sprite_vertex(
    VertexIn in [[stage_in]],
    constant Uniforms& uniforms [[buffer(1)]]
) {
    // TODO: Transform position by MVP, pass through texCoord
}

fragment float4 sprite_fragment(
    VertexOut in [[stage_in]],
    texture2d<float> tex [[texture(0)]],
    sampler smp [[sampler(0)]]
) {
    // TODO: Sample texture, discard if alpha < 0.5, return color
}
```

### 2. Shader Loading (`src/engine/Shader.hpp` and `Shader.mm`)

Create a Shader class that:
- Loads `.metal` shader source from file
- Compiles to MTLLibrary
- Creates MTLRenderPipelineState
- Provides method to bind the pipeline

**Interface:**
```cpp
class Shader {
public:
    bool load(id<MTLDevice> device, const std::string& filename);
    id<MTLRenderPipelineState> getPipelineState();
    void shutdown();
};
```

### 3. Texture Loading (`src/engine/Texture.hpp` and `Texture.mm`)

Create a Texture class that:
- Loads PNG file using stb_image (single-header library)
- Creates MTLTexture with RGBA8 format
- Provides method to bind texture

**Interface:**
```cpp
class Texture {
public:
    bool load(id<MTLDevice> device, const std::string& filename);
    id<MTLTexture> getTexture();
    int getWidth();
    int getHeight();
    void shutdown();
};
```

**stb_image setup:**
- Download `stb_image.h` from https://github.com/nothings/stb
- Place in `src/engine/stb_image.h`
- In ONE .cpp file, define: `#define STB_IMAGE_IMPLEMENTATION`

### 4. Test Sprite in main.cpp

Modify `main.cpp` to:
- Load a test sprite texture (provide a simple 32x32 PNG)
- Load the sprite shader
- Draw the sprite in the center of the screen

---

## Technical Details

### Vertex Buffer Layout

For a single quad (2 triangles, 6 vertices):
```cpp
struct Vertex {
    float x, y;      // Position
    float u, v;      // Texture coordinates
};

// Quad vertices (counterclockwise)
Vertex vertices[] = {
    // Triangle 1
    {-0.5f, -0.5f,  0.0f, 1.0f},  // Bottom-left
    { 0.5f, -0.5f,  1.0f, 1.0f},  // Bottom-right
    { 0.5f,  0.5f,  1.0f, 0.0f},  // Top-right
    // Triangle 2
    {-0.5f, -0.5f,  0.0f, 1.0f},  // Bottom-left
    { 0.5f,  0.5f,  1.0f, 0.0f},  // Top-right
    {-0.5f,  0.5f,  0.0f, 0.0f},  // Top-left
};
```

Note: UV origin is top-left (0,0), bottom-right is (1,1).

### MVP Matrix

For now, use orthographic projection matching NES coordinates:
- X: -128 to 128 (centered)
- Y: -120 to 120 (centered)

```cpp
// Simple orthographic matrix
float4x4 ortho = {
    {2.0f/256.0f, 0, 0, 0},
    {0, 2.0f/240.0f, 0, 0},
    {0, 0, 1, 0},
    {0, 0, 0, 1}
};
```

### Sampler State

Create a sampler with:
- `MTLSamplerMinMagFilterNearest` - no interpolation (pixel art)
- `MTLSamplerAddressModeClampToEdge` - no wrapping

---

## Test Asset

Create or use a simple 32x32 test sprite. Here's a simple one you can create:
- 32x32 PNG
- Bright colored square with transparent corners
- Save as `assets/sprites/test.png`

Or download any small pixel art sprite from the internet.

---

## Files to Create

```
src/engine/Shader.hpp
src/engine/Shader.mm
src/engine/Texture.hpp
src/engine/Texture.mm
src/engine/stb_image.h  (download from stb repo)
shaders/sprite.metal
assets/sprites/test.png
```

## Files to Modify

```
CMakeLists.txt  (add new source files, shader copying)
src/main.cpp    (test sprite drawing)
src/engine/Renderer.hpp  (add methods for drawing)
src/engine/Renderer.mm   (add drawing implementation)
```

---

## Acceptance Criteria

- [ ] Shader compiles without errors
- [ ] PNG loads to GPU texture
- [ ] Test sprite appears on screen (centered)
- [ ] Transparent pixels are not drawn (alpha cutoff works)
- [ ] No memory leaks (textures/shaders properly released)
- [ ] Code compiles with no warnings

---

## What NOT to Do

- Don't implement sprite batching yet (that's next task)
- Don't add animation yet
- Don't optimize - get it working first
- Don't add multiple shaders

---

## Resources

- Metal Shading Language Spec: https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf
- stb_image: https://github.com/nothings/stb/blob/master/stb_image.h
- Metal Best Practices: https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/

---

## Questions?

If unclear on any Metal concepts, ask. Better to clarify than guess wrong.

The goal: see a sprite on screen. Everything else is details.
