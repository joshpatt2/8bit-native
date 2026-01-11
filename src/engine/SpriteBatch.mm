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
    , m_encoder(nullptr)
    , m_maxSprites(0)
    , m_spriteCount(0)
    , m_begun(false)
    , m_bufferOffset(0)
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
    m_bufferOffset = 0;  // Reset buffer offset for new frame
    // Don't reset m_encoder here - it's set by setEncoder() or end()
    m_begun = true;
}

void SpriteBatch::setEncoder(void* encoder) {
    m_encoder = encoder;
}

void SpriteBatch::draw(void* texture, float x, float y, float width, float height) {
    // Draw full texture (UV 0-1) with white color
    draw(texture, x, y, width, height, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f);
}

void SpriteBatch::draw(void* texture, float x, float y, float width, float height,
                       float r, float g, float b, float a) {
    // Draw full texture (UV 0-1) with color
    draw(texture, x, y, width, height, 0.0f, 0.0f, 1.0f, 1.0f, r, g, b, a);
}

void SpriteBatch::draw(void* texture,
                       float x, float y, float width, float height,
                       float srcX, float srcY, float srcW, float srcH,
                       float r, float g, float b, float a) {
    if (!m_begun) {
        std::cerr << "SpriteBatch::draw called without begin()" << std::endl;
        return;
    }

    if (m_spriteCount >= m_maxSprites) {
        std::cerr << "SpriteBatch::draw - max sprites exceeded, skipping" << std::endl;
        return;
    }

    // Auto-flush if texture changes (multi-texture support)
    if (m_currentTexture != nullptr && m_currentTexture != texture && m_spriteCount > 0) {
        // Texture changed, flush current batch
        std::cout << "SpriteBatch: texture change, flushing " << m_spriteCount << " sprites (old=" << m_currentTexture << " new=" << texture << ")" << std::endl;
        flush(m_encoder);
        m_vertices.clear();
        m_spriteCount = 0;
    }

    m_currentTexture = texture;

    // Add quad with transformed UVs for sprite sheet support
    addQuad(x, y, width, height, srcX, srcY, srcX + srcW, srcY + srcH, r, g, b, a);
    m_spriteCount++;
}

void SpriteBatch::addQuad(float x, float y, float w, float h,
                           float u0, float v0, float u1, float v1,
                           float r, float g, float b, float a) {
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

    m_encoder = encoder;  // Store encoder for mid-batch flushes
    flush(encoder);
    m_begun = false;
}

void SpriteBatch::flush(void* encoder) {
    if (m_spriteCount == 0 || m_vertices.empty()) {
        return;
    }

    if (!encoder) {
        std::cerr << "SpriteBatch::flush - null encoder! Losing " << m_spriteCount << " sprites" << std::endl;
        return;
    }

    static int flushCount = 0;
    if (++flushCount <= 2) {
        std::cout << "FLUSH #" << flushCount << ": " << m_spriteCount << " sprites, "
                  << m_vertices.size() << " verts, tex=" << m_currentTexture << std::endl;
        // Print ALL vertices
        for (int i = 0; i < (int)m_vertices.size(); i++) {
            SpriteVertex& v = m_vertices[i];
            std::cout << "  v" << i << ": pos=(" << v.x << "," << v.y << ") uv=(" << v.u << "," << v.v
                      << ") color=(" << v.r << "," << v.g << "," << v.b << "," << v.a << ")" << std::endl;
        }
    }

    id<MTLRenderCommandEncoder> mtlEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
    id<MTLBuffer> mtlBuffer = (__bridge id<MTLBuffer>)m_vertexBuffer;
    id<MTLRenderPipelineState> mtlPipeline = (__bridge id<MTLRenderPipelineState>)m_pipelineState;
    id<MTLSamplerState> mtlSampler = (__bridge id<MTLSamplerState>)m_samplerState;
    id<MTLTexture> mtlTexture = (__bridge id<MTLTexture>)m_currentTexture;

    // Set pipeline state
    [mtlEncoder setRenderPipelineState:mtlPipeline];

    // Use setVertexBytes for dynamic data - creates temporary buffer per draw call
    // This avoids the synchronization issue with mid-frame flushes overwriting data
    size_t dataSize = m_vertices.size() * sizeof(SpriteVertex);
    [mtlEncoder setVertexBytes:m_vertices.data() length:dataSize atIndex:0];

    // Bind texture and sampler
    if (mtlTexture) {
        [mtlEncoder setFragmentTexture:mtlTexture atIndex:0];
    }
    [mtlEncoder setFragmentSamplerState:mtlSampler atIndex:0];

    // ONE DRAW CALL FOR ALL SPRITES
    static int drawCount = 0;
    if (++drawCount <= 2) {
        std::cout << "DRAW CALL #" << drawCount << ": vertexCount=" << m_vertices.size()
                  << " dataSize=" << dataSize << " bytes"
                  << " pipeline=" << (mtlPipeline ? "valid" : "NULL")
                  << " encoder=" << (mtlEncoder ? "valid" : "NULL") << std::endl;
    }

    // Write to buffer at current offset (avoids overwriting previous flush data)
    char* bufferPtr = (char*)mtlBuffer.contents + m_bufferOffset;
    memcpy(bufferPtr, m_vertices.data(), dataSize);

    // Bind buffer with offset
    [mtlEncoder setVertexBuffer:mtlBuffer offset:m_bufferOffset atIndex:0];

    // Single draw call for all sprites in this batch
    [mtlEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                   vertexStart:0
                   vertexCount:(NSUInteger)m_vertices.size()];

    // Advance offset for next flush
    m_bufferOffset += dataSize;
}
