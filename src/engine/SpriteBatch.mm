/**
 * SpriteBatch implementation
 */

#include "SpriteBatch.hpp"
#import <Metal/Metal.h>
#include <iostream>
#include <cstring>

SpriteBatch::SpriteBatch()
    : m_device(nullptr)
    , m_vertexBuffer(nullptr)
    , m_pipelineState(nullptr)
    , m_samplerState(nullptr)
    , m_currentTexture(nullptr)
    , m_maxSprites(0)
    , m_spriteCount(0)
    , m_begun(false)
{
}

SpriteBatch::~SpriteBatch() {
    shutdown();
}

bool SpriteBatch::init(void* device, void* pipelineState, int maxSprites) {
    if (!device || !pipelineState) {
        std::cerr << "SpriteBatch::init - invalid device or pipeline" << std::endl;
        return false;
    }

    id<MTLDevice> mtlDevice = (__bridge id<MTLDevice>)device;
    m_device = device;
    m_pipelineState = pipelineState;
    m_maxSprites = maxSprites;

    // Pre-allocate vertex storage (6 vertices per sprite)
    m_vertices.reserve(maxSprites * 6);

    // Create vertex buffer (shared storage for CPU/GPU)
    size_t bufferSize = maxSprites * 6 * sizeof(SpriteVertex);
    m_vertexBuffer = (__bridge_retained void*)[mtlDevice newBufferWithLength:bufferSize
                                                                      options:MTLResourceStorageModeShared];
    
    if (!m_vertexBuffer) {
        std::cerr << "SpriteBatch::init - failed to create vertex buffer" << std::endl;
        return false;
    }

    // Create sampler state (nearest-neighbor for pixel art)
    MTLSamplerDescriptor* samplerDesc = [MTLSamplerDescriptor new];
    samplerDesc.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDesc.magFilter = MTLSamplerMinMagFilterNearest;
    samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
    
    m_samplerState = (__bridge_retained void*)[mtlDevice newSamplerStateWithDescriptor:samplerDesc];
    
    if (!m_samplerState) {
        std::cerr << "SpriteBatch::init - failed to create sampler" << std::endl;
        return false;
    }

    return true;
}

void SpriteBatch::shutdown() {
    if (m_vertexBuffer) {
        CFRelease(m_vertexBuffer);
        m_vertexBuffer = nullptr;
    }
    if (m_samplerState) {
        CFRelease(m_samplerState);
        m_samplerState = nullptr;
    }
    m_vertices.clear();
    m_device = nullptr;
    m_pipelineState = nullptr;
    m_currentTexture = nullptr;
}

void SpriteBatch::begin() {
    m_vertices.clear();
    m_spriteCount = 0;
    m_currentTexture = nullptr;
    m_begun = true;
}

void SpriteBatch::draw(void* texture, float x, float y, float width, float height) {
    // Draw full texture (UV 0-1)
    draw(texture, x, y, width, height, 0.0f, 0.0f, 1.0f, 1.0f);
}

void SpriteBatch::draw(void* texture,
                       float x, float y, float width, float height,
                       float srcX, float srcY, float srcW, float srcH) {
    if (!m_begun) {
        std::cerr << "SpriteBatch::draw called without begin()" << std::endl;
        return;
    }

    if (m_spriteCount >= m_maxSprites) {
        std::cerr << "SpriteBatch::draw - max sprites exceeded, skipping" << std::endl;
        return;
    }

    // For now: assume all sprites use same texture (single atlas)
    // Future: flush when texture changes for multi-texture support
    m_currentTexture = texture;

    // Add quad with transformed UVs for sprite sheet support
    addQuad(x, y, width, height, srcX, srcY, srcX + srcW, srcY + srcH);
    m_spriteCount++;
}

void SpriteBatch::addQuad(float x, float y, float w, float h,
                           float u0, float v0, float u1, float v1) {
    // Calculate quad corners (centered on x, y)
    float left = x - w * 0.5f;
    float right = x + w * 0.5f;
    float top = y + h * 0.5f;
    float bottom = y - h * 0.5f;

    // Transform to NDC (Normalized Device Coordinates)
    // NES screen: -128 to 128 (X), -120 to 120 (Y)
    float ndcLeft = left / 128.0f;
    float ndcRight = right / 128.0f;
    float ndcTop = top / 120.0f;
    float ndcBottom = bottom / 120.0f;

    // White tint (no color modification)
    float r = 1.0f, g = 1.0f, b = 1.0f, a = 1.0f;

    // Two triangles = 6 vertices (CCW winding)
    // Triangle 1: BL, BR, TR
    m_vertices.push_back({ndcLeft, ndcBottom, u0, v1, r, g, b, a});  // Bottom-left
    m_vertices.push_back({ndcRight, ndcBottom, u1, v1, r, g, b, a}); // Bottom-right
    m_vertices.push_back({ndcRight, ndcTop, u1, v0, r, g, b, a});    // Top-right

    // Triangle 2: BL, TR, TL
    m_vertices.push_back({ndcLeft, ndcBottom, u0, v1, r, g, b, a});  // Bottom-left
    m_vertices.push_back({ndcRight, ndcTop, u1, v0, r, g, b, a});    // Top-right
    m_vertices.push_back({ndcLeft, ndcTop, u0, v0, r, g, b, a});     // Top-left
}

void SpriteBatch::end(void* encoder) {
    if (!m_begun) {
        return;
    }

    flush(encoder);
    m_begun = false;
}

void SpriteBatch::flush(void* encoder) {
    if (m_spriteCount == 0 || m_vertices.empty()) {
        return;
    }

    id<MTLRenderCommandEncoder> mtlEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
    id<MTLBuffer> mtlBuffer = (__bridge id<MTLBuffer>)m_vertexBuffer;
    id<MTLRenderPipelineState> mtlPipeline = (__bridge id<MTLRenderPipelineState>)m_pipelineState;
    id<MTLSamplerState> mtlSampler = (__bridge id<MTLSamplerState>)m_samplerState;
    id<MTLTexture> mtlTexture = (__bridge id<MTLTexture>)m_currentTexture;

    // Upload vertices to GPU
    size_t dataSize = m_vertices.size() * sizeof(SpriteVertex);
    memcpy(mtlBuffer.contents, m_vertices.data(), dataSize);

    // Set pipeline state
    [mtlEncoder setRenderPipelineState:mtlPipeline];

    // Bind vertex buffer
    [mtlEncoder setVertexBuffer:mtlBuffer offset:0 atIndex:0];

    // Bind texture and sampler
    if (mtlTexture) {
        [mtlEncoder setFragmentTexture:mtlTexture atIndex:0];
    }
    [mtlEncoder setFragmentSamplerState:mtlSampler atIndex:0];

    // ONE DRAW CALL FOR ALL SPRITES
    [mtlEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                   vertexStart:0
                   vertexCount:(NSUInteger)m_vertices.size()];
}
