# Text Rendering Debug Investigation

## Overview
Investigation into why score text doesn't render in PONG despite using the same SpriteBatch system that successfully renders paddles and ball.

**Status**: Unresolved - root cause identified but fix incomplete

---

## What Works

### Texture Loading
- Font texture loads correctly: `assets/fonts/font8x8.png (128x24)`
- Fixed ARC issue where `delete fontTexture` was releasing the Metal texture prematurely
- Solution: Keep `Texture*` object alive via `m_fontTextureOwner`

### SpriteBatch Infrastructure
- `flush()` is called with correct sprite counts
- Vertex data contains valid NDC coordinates
- Pipeline state and render encoder are valid at draw time
- Draw calls are issued to Metal

### Shader Pipeline
- Shader compiles and links successfully
- Magenta debug shader renders paddles/ball correctly
- Note: Shaders must be manually copied to build directory (CMake `file(COPY)` runs at configure time only)

---

## The Problem

**Symptom**: Within a single draw call containing multiple quads, only the FIRST quad renders. All subsequent quads are invisible.

**Evidence**:
```
FLUSH #1: 4 sprites, 24 verts
  v0-v5: paddle (RENDERS)
  v6-v11: test quad (INVISIBLE)
  v12-v17: test quad (INVISIBLE)
  v18-v23: test quad (INVISIBLE)
```

This is NOT about:
- First vs second flush (tested by reordering)
- Text-specific issues (same problem with simple colored quads)
- Y position (tested various positions)
- Texture binding (same texture, same problem)

---

## Buffer Synchronization Issue

Mid-frame flushes overwrite the shared vertex buffer:

```
Frame timeline:
1. Text flush -> write to buffer[0], queue draw
2. Paddle flush -> write to buffer[0] (OVERWRITES), queue draw
3. GPU executes -> both draws read final buffer state
```

**Partial fix implemented**: Use buffer offsets so each flush writes to different region
```cpp
m_bufferOffset += dataSize;
[mtlEncoder setVertexBuffer:mtlBuffer offset:m_bufferOffset atIndex:0];
```

**Result**: Buffer sync fixed, but deeper issue remains.

---

## Deeper Issue: Single Draw Call, Multiple Quads

Even with buffer synchronization fixed, Metal only renders the first 6 vertices of each draw call.

Tested approaches that all failed:

| Approach | Result |
|----------|--------|
| Single draw call with vertexCount:24 | Only first quad |
| Separate draw calls per quad | Only first quad |
| setVertexBytes (inline buffer) | Only first quad |
| setVertexBuffer with offset | Only first quad |
| constant address space in shader | Only first quad |

---

## Possible Root Causes (Untested)

### 1. Struct Alignment Mismatch
```cpp
// C++ SpriteVertex (32 bytes)
struct SpriteVertex {
    float x, y;       // 8 bytes
    float u, v;       // 8 bytes
    float r, g, b, a; // 16 bytes
};

// Metal VertexIn (32 bytes)
struct VertexIn {
    float2 position;  // 8 bytes
    float2 texCoord;  // 8 bytes
    float4 color;     // 16 bytes
};
```
Sizes match, but Metal's `float4` may require 16-byte alignment affecting struct packing.

### 2. Vertex Descriptor Conflict
Shader reads directly from buffer using vertexID, but Shader.mm also sets a vertex descriptor. These might conflict.

### 3. vertexID Not Incrementing
If `vertexID` stays at 0 for all vertices, all would read the same data.

---

## Files Modified

| File | Changes |
|------|---------|
| `src/engine/TextRenderer.mm` | Fixed texture ownership |
| `src/engine/TextRenderer.hpp` | Added `m_fontTextureOwner` |
| `src/engine/SpriteBatch.mm` | Debug output, buffer offset tracking |
| `src/engine/SpriteBatch.hpp` | Added `m_bufferOffset` |
| `shaders/sprite_batch.metal` | Debug output, address space tests |
| `src/engine/Shader.mm` | Fixed vertex descriptor stride |

---

## Recommended Next Steps

1. **Use Metal GPU Frame Capture** in Xcode to see actual shader inputs
2. **Test indexed rendering** instead of direct vertex array
3. **Verify struct padding** with sizeof and byte-by-byte inspection
4. **Remove vertex descriptor** to test if it conflicts with direct buffer access
5. **Simplify to single-texture batching** to avoid mid-frame flushes

---

## Lessons Learned

1. Metal shader changes require manual copy when using CMake `file(COPY)`
2. ARC and void* bridging can cause unexpected texture releases
3. Shared buffers need synchronization - GPU reads happen after all CPU writes
4. Debug with forced solid colors to isolate vertex vs fragment issues
