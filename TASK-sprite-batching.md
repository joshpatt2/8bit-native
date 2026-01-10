# Task: Sprite Batching

## Why This Is First

We can draw ONE sprite. A game needs HUNDREDS.

Current state: Each sprite = 1 draw call. 100 sprites = 100 draw calls = garbage performance.

Target state: 1000 sprites = 1 draw call = butter smooth.

---

## What You're Building

A `SpriteBatch` class that:
1. Collects sprite draw requests
2. Builds a single vertex buffer with all quads
3. Renders everything in ONE draw call
4. Resets for next frame

---

## The Interface

```cpp
class SpriteBatch {
public:
    SpriteBatch();
    ~SpriteBatch();

    // Initialize with device and maximum sprite capacity
    bool init(id<MTLDevice> device, id<MTLRenderPipelineState> pipeline, int maxSprites);

    // Call at start of frame
    void begin();

    // Queue a sprite for drawing (call many times)
    void draw(id<MTLTexture> texture, float x, float y, float width, float height);

    // Optional: draw with source rectangle (for sprite sheets)
    void draw(id<MTLTexture> texture, float x, float y, float width, float height,
              float srcX, float srcY, float srcW, float srcH);

    // Flush all queued sprites to GPU (call once at end)
    void end(id<MTLRenderCommandEncoder> encoder);

    // Cleanup
    void shutdown();

private:
    id<MTLBuffer> vertexBuffer;
    id<MTLRenderPipelineState> pipeline;
    id<MTLSamplerState> sampler;

    std::vector<Vertex> vertices;
    int maxSprites;
    int spriteCount;

    id<MTLTexture> currentTexture;  // For texture batching
};
```

---

## How It Works

### The Vertex Buffer

Instead of 6 vertices per sprite submitted separately, we build ONE buffer with ALL vertices:

```cpp
// For 100 sprites = 600 vertices
// Each sprite is a quad = 2 triangles = 6 vertices

void SpriteBatch::draw(texture, x, y, w, h) {
    if (spriteCount >= maxSprites) {
        // Buffer full - flush and continue
        flush(encoder);
    }

    // Calculate quad corners
    float left = x - w/2;
    float right = x + w/2;
    float top = y + h/2;
    float bottom = y - h/2;

    // Add 6 vertices for this quad
    vertices.push_back({left, bottom, 0, 1});   // BL
    vertices.push_back({right, bottom, 1, 1});  // BR
    vertices.push_back({right, top, 1, 0});     // TR

    vertices.push_back({left, bottom, 0, 1});   // BL
    vertices.push_back({right, top, 1, 0});     // TR
    vertices.push_back({left, top, 0, 0});      // TL

    spriteCount++;
}
```

### The Draw Call

```cpp
void SpriteBatch::end(id<MTLRenderCommandEncoder> encoder) {
    if (spriteCount == 0) return;

    // Upload vertices to GPU
    memcpy(vertexBuffer.contents, vertices.data(), vertices.size() * sizeof(Vertex));

    // Bind state
    [encoder setRenderPipelineState:pipeline];
    [encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    [encoder setFragmentTexture:currentTexture atIndex:0];
    [encoder setFragmentSamplerState:sampler atIndex:0];

    // ONE draw call for ALL sprites
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle
                vertexStart:0
                vertexCount:spriteCount * 6];

    // Reset for next frame
    vertices.clear();
    spriteCount = 0;
}
```

---

## The Problem: Multiple Textures

Different sprites use different textures. You can't batch across texture changes.

### Solution: Texture Atlas

Pack multiple sprites into ONE texture. Use UV coordinates to select which sprite.

```
+--------+--------+
| player | enemy1 |
+--------+--------+
| enemy2 | bullet |
+--------+--------+
```

For this task: **Support texture atlas via source rectangle parameter.**

The `draw()` overload with `srcX, srcY, srcW, srcH` specifies which region of the texture to sample.

```cpp
// Draw player from atlas (top-left, 32x32 region)
batch.draw(atlas, playerX, playerY, 32, 32, 0, 0, 32, 32);

// Draw enemy from atlas (top-right, 32x32 region)
batch.draw(atlas, enemyX, enemyY, 32, 32, 32, 0, 32, 32);
```

UV calculation:
```cpp
float u0 = srcX / textureWidth;
float v0 = srcY / textureHeight;
float u1 = (srcX + srcW) / textureWidth;
float v1 = (srcY + srcH) / textureHeight;
```

---

## Texture Batching (Advanced)

If you MUST support multiple textures without an atlas:

1. Track current texture
2. When texture changes, flush current batch, switch texture, continue
3. This means multiple draw calls, but fewer than one-per-sprite

```cpp
void SpriteBatch::draw(id<MTLTexture> texture, ...) {
    if (texture != currentTexture && spriteCount > 0) {
        flush(encoder);  // Draw everything with old texture
    }
    currentTexture = texture;
    // ... add vertices
}
```

For v1: **Just use a single atlas.** Multi-texture batching is optimization for later.

---

## Performance Target

| Sprites | Target FPS | Max Draw Calls |
|---------|------------|----------------|
| 100 | 60 | 1 |
| 1000 | 60 | 1 |
| 5000 | 60 | 1-2 |

If you can't hit 1000 sprites at 60fps with one draw call, something is wrong.

---

## Integration

Modify `Renderer` to use SpriteBatch:

```cpp
class Renderer {
    // ... existing ...
    SpriteBatch spriteBatch;

    void init() {
        // ... existing ...
        spriteBatch.init(device, shader.getPipelineState(), 10000);
    }

    void beginFrame() {
        // ... existing ...
        spriteBatch.begin();
    }

    void drawSprite(Texture& tex, float x, float y, float w, float h) {
        spriteBatch.draw(tex.getTexture(), x, y, w, h);
    }

    void endFrame() {
        spriteBatch.end(renderEncoder);
        // ... existing present/commit ...
    }
};
```

---

## Test Scene

Create a test in `main.cpp` that:

1. Loads one texture atlas (or single texture)
2. Draws 500 sprites in random positions
3. Moves them each frame (simple velocity)
4. Displays FPS

```cpp
// Pseudo-code for test
struct TestSprite {
    float x, y;
    float vx, vy;
};

std::vector<TestSprite> sprites(500);

// Initialize with random positions/velocities
for (auto& s : sprites) {
    s.x = randomFloat(-100, 100);
    s.y = randomFloat(-100, 100);
    s.vx = randomFloat(-50, 50);
    s.vy = randomFloat(-50, 50);
}

// In game loop
for (auto& s : sprites) {
    s.x += s.vx * deltaTime;
    s.y += s.vy * deltaTime;

    // Bounce off edges
    if (s.x < -128 || s.x > 128) s.vx *= -1;
    if (s.y < -120 || s.y > 120) s.vy *= -1;

    renderer.drawSprite(texture, s.x, s.y, 16, 16);
}
```

This test also requires delta time. So: **implement basic delta time in main.cpp as part of this task.**

---

## Files to Create

```
src/engine/SpriteBatch.hpp
src/engine/SpriteBatch.mm
```

## Files to Modify

```
CMakeLists.txt (add new source files)
src/engine/Renderer.hpp (add spriteBatch member, modify interface)
src/engine/Renderer.mm (integrate spriteBatch)
src/main.cpp (test with 500 moving sprites)
```

---

## Acceptance Criteria

- [ ] SpriteBatch class compiles and links
- [ ] Can draw 500+ sprites in one draw call
- [ ] FPS stays at 60 with 1000 sprites
- [ ] Source rectangle (sprite sheet) support works
- [ ] Delta time implemented in main loop
- [ ] Test scene shows 500 bouncing sprites
- [ ] No memory leaks

---

## What NOT To Do

- Don't implement texture atlas LOADING (just use source rects on a single texture)
- Don't implement sprite sorting/layering yet
- Don't implement rotation yet
- Don't optimize prematurely - get it working first

---

## Resources

- Metal Best Practices - Vertex Buffers: https://developer.apple.com/documentation/metal/resource_management/setting_resource_storage_modes
- Sprite Batching Techniques: Search "sprite batch opengl" - concepts transfer to Metal

---

## Deadline Pressure

This is the foundation for the entire game. No batching = no game.

Don't come back until 500 sprites are bouncing smoothly.

Not. My. Tempo.
