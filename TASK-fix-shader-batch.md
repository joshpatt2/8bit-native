# Task: Fix SpriteBatch Shader Integration

## The Problem

Your SpriteBatch code compiles but will crash at runtime. Three bugs:

### Bug 1: Function Name Mismatch

`Shader.mm` hardcodes function names:
```cpp
id<MTLFunction> vertexFunction = [library newFunctionWithName:@"sprite_vertex"];
id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"sprite_fragment"];
```

But `sprite_batch.metal` uses:
```metal
vertex VertexOut vertex_batch(...) { ... }
fragment float4 fragment_batch(...) { ... }
```

**Result:** "Failed to find shader functions" at runtime.

### Bug 2: Vertex Descriptor Mismatch

`Shader.mm` vertex descriptor:
```cpp
// Position (2 floats) + TexCoord (2 floats) = 16 bytes stride
vertexDescriptor.layouts[0].stride = 4 * sizeof(float);
```

But `SpriteVertex` in SpriteBatch.hpp:
```cpp
struct SpriteVertex {
    float x, y;      // 2 floats
    float u, v;      // 2 floats
    float r, g, b, a; // 4 floats
};  // = 8 floats = 32 bytes
```

**Result:** GPU reads garbage data, sprites render as visual noise.

### Bug 3: Pixel Format Mismatch

`Renderer.mm:105`:
```cpp
impl->metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
```

`Shader.mm:66`:
```cpp
pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
```

**Result:** Pipeline state creation might fail or colors will be washed out.

---

## The Fix

You have two options. Pick ONE.

### Option A: Modify Shader Class (Recommended)

Make `Shader::load()` accept function names as parameters:

```cpp
// Shader.hpp
bool load(id<MTLDevice> device, const std::string& filename,
          const std::string& vertexFunc = "sprite_vertex",
          const std::string& fragmentFunc = "sprite_fragment");
```

Then in `Shader.mm`:
```cpp
NSString* vertName = [NSString stringWithUTF8String:vertexFunc.c_str()];
NSString* fragName = [NSString stringWithUTF8String:fragmentFunc.c_str()];
id<MTLFunction> vertexFunction = [library newFunctionWithName:vertName];
id<MTLFunction> fragmentFunction = [library newFunctionWithName:fragName];
```

And create a new method for batch vertex descriptor:
```cpp
bool loadBatch(id<MTLDevice> device, const std::string& filename);
```

That sets the correct 32-byte stride and includes the color attribute.

### Option B: Rename Functions in Shader (Quick Hack)

Just rename the functions in `sprite_batch.metal`:
```metal
vertex VertexOut sprite_vertex(...) { ... }
fragment float4 sprite_fragment(...) { ... }
```

And update the vertex descriptor stride. But this is a hack because now ALL shaders must use the same function names.

---

## Vertex Descriptor for SpriteBatch

The correct vertex descriptor for `SpriteVertex`:

```cpp
MTLVertexDescriptor* vertexDescriptor = [[MTLVertexDescriptor alloc] init];

// Position (attribute 0): float2 at offset 0
vertexDescriptor.attributes[0].format = MTLVertexFormatFloat2;
vertexDescriptor.attributes[0].offset = 0;
vertexDescriptor.attributes[0].bufferIndex = 0;

// TexCoord (attribute 1): float2 at offset 8
vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
vertexDescriptor.attributes[1].offset = 2 * sizeof(float);
vertexDescriptor.attributes[1].bufferIndex = 0;

// Color (attribute 2): float4 at offset 16
vertexDescriptor.attributes[2].format = MTLVertexFormatFloat4;
vertexDescriptor.attributes[2].offset = 4 * sizeof(float);
vertexDescriptor.attributes[2].bufferIndex = 0;

// Layout: 32 bytes per vertex
vertexDescriptor.layouts[0].stride = 8 * sizeof(float);
vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
```

---

## Pixel Format Fix

In `Shader.mm`, match the Renderer's format:
```cpp
pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
```

---

## Also Fix: Shader Uses [[stage_in]] Not Buffer Access

Your shader changed to direct buffer access:
```metal
vertex VertexOut vertex_batch(const device VertexIn* vertices [[buffer(0)]],
                               uint vertexID [[vertex_id]]) {
```

But SpriteBatch binds the buffer at index 0 expecting `[[stage_in]]`. Either:

1. Change shader back to `[[stage_in]]` with `[[attribute(N)]]`
2. Or remove the vertex descriptor entirely and use buffer access

Pick one approach. Don't mix them.

---

## Acceptance Criteria

- [ ] `./build/8bit-native` runs without crashing
- [ ] 500 sprites render on screen (not garbage)
- [ ] Sprites bounce around at 60 FPS
- [ ] No shader compilation warnings
- [ ] Colors look correct (not washed out)

---

## Test Command

```bash
cd /Users/joshuapatterson/ai/8bit-native
cmake --build build && ./build/8bit-native
```

You should see 500 bouncing sprites. If you see a blue screen with no sprites, or garbage pixels, the fix isn't complete.

---

## Don't

- Don't create new files
- Don't change the SpriteBatch class interface
- Don't "improve" anything else
- Just fix the three bugs

---

**Deadline:** Fix this before you do anything else.
