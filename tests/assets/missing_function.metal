#include <metal_stdlib>
using namespace metal;

// Valid syntax but missing the expected function names
vertex float4 wrong_vertex_name() {
    return float4(0.0);
}

fragment float4 wrong_fragment_name() {
    return float4(1.0);
}
