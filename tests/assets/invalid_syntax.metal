#include <metal_stdlib>
using namespace metal;

// Syntax error: missing semicolon
struct VertexIn {
    float2 position [[attribute(0)]]
    float2 texCoord [[attribute(1)]];
};

vertex float4 sprite_vertex() {
    return float4(0.0);
}
