/**
 * Sprite Batch Shader - Optimized for batched rendering
 *
 * Simpler than sprite.metal:
 * - No per-sprite MVP matrix (vertices pre-transformed to NDC)
 * - Just passes through position and UVs
 * - Fragment shader samples texture with alpha discard
 */

#include <metal_stdlib>
using namespace metal;

// Vertex input (matches SpriteVertex in SpriteBatch.hpp)
struct VertexIn {
    float2 position;  // Already in NDC (-1 to 1)
    float2 texCoord;
    float4 color;
};

// Vertex output / Fragment input
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float4 color;
};

// Vertex shader - pass-through (no transformation needed)
vertex VertexOut sprite_vertex(const device VertexIn* vertices [[buffer(0)]],
                                uint vertexID [[vertex_id]]) {
    VertexIn in = vertices[vertexID];
    VertexOut out;
    out.position = float4(in.position.x, in.position.y, 0.0, 1.0);
    out.texCoord = in.texCoord;
    out.color = in.color;
    return out;
}

// Fragment shader - sample texture and apply color tint
fragment float4 sprite_fragment(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 sampler texSampler [[sampler(0)]]) {
    float4 texColor = tex.sample(texSampler, in.texCoord);
    
    // Alpha discard for transparency (0.5 threshold)
    if (texColor.a < 0.5) {
        discard_fragment();
    }
    
    // Apply color tint (for future sprite effects)
    return texColor * in.color;
}
