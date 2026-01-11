/**
 * SpriteBatch - Efficient sprite rendering with batching
 *
 * Collects multiple sprite draw calls and renders them in a single
 * GPU draw call for maximum performance.
 *
 * Usage:
 *   batch.begin();
 *   batch.draw(tex, x, y, w, h);  // Call 1000 times
 *   batch.end(encoder);            // ONE draw call
 */

#pragma once

#include <vector>
#include <cstdint>

// Forward declare Metal types
#ifdef __OBJC__
#import <Metal/Metal.h>
#else
typedef void* id;
#endif

// Vertex format for batched sprites
struct SpriteVertex {
    float x, y;      // Position (screen space)
    float u, v;      // Texture coordinates
    float r, g, b, a; // Color tint (for future use)
};

class SpriteBatch {
public:
    SpriteBatch();
    ~SpriteBatch();

    // Initialize with Metal device and maximum sprite capacity
    bool init(void* device, void* pipelineState, int maxSprites = 10000);

    // Start batching (call at beginning of frame)
    void begin();

    // Queue a sprite for rendering
    void draw(void* texture, float x, float y, float width, float height);

    // Queue a sprite with color tint
    void draw(void* texture, float x, float y, float width, float height,
              float r, float g, float b, float a);

    // Queue a sprite with source rectangle and color tint
    void draw(void* texture,
              float x, float y, float width, float height,
              float srcX, float srcY, float srcW, float srcH,
              float r, float g, float b, float a);

    // Flush all queued sprites to GPU (call at end of frame)
    void end(void* encoder);

    // Cleanup
    void shutdown();

    // Get current sprite count
    int getSpriteCount() const { return m_spriteCount; }

private:
    void flush(void* encoder);
    void addQuad(float x, float y, float w, float h, 
                 float u0, float v0, float u1, float v1,
                 float r, float g, float b, float a);

    void* m_device;           // id<MTLDevice>
    void* m_vertexBuffer;     // id<MTLBuffer>
    void* m_pipelineState;    // id<MTLRenderPipelineState>
    void* m_samplerState;     // id<MTLSamplerState>
    void* m_currentTexture;   // id<MTLTexture>

    std::vector<SpriteVertex> m_vertices;
    int m_maxSprites;
    int m_spriteCount;
    bool m_begun;
};
