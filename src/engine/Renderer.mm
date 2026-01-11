/**
 * Renderer Implementation - Metal backend
 *
 * This file is Objective-C++ (.mm) because Metal is an Objective-C API.
 * We wrap it in C++ classes for the rest of the engine.
 */

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <SDL2/SDL.h>
#import <SDL2/SDL_metal.h>

#include "Renderer.hpp"
#include "SpriteBatch.hpp"
#include "Shader.hpp"
#include <iostream>
#include <simd/simd.h>

// Vertex structure for sprite quads (legacy single-sprite API)
struct Vertex {
    float x, y;      // Position
    float u, v;      // Texture coordinates
};

// Uniforms for MVP matrix (legacy single-sprite API)
struct Uniforms {
    simd::float4x4 mvp;
};

// Implementation struct holds all the Metal objects
// This is the PIMPL (Pointer to Implementation) pattern
// It keeps Objective-C types out of the C++ header
struct RendererImpl {
    // The Metal layer attached to our window
    CAMetalLayer* metalLayer = nil;

    // The GPU device - represents the actual GPU hardware
    id<MTLDevice> device = nil;

    // Command queue - we submit command buffers to this
    id<MTLCommandQueue> commandQueue = nil;

    // Current frame's drawable - the texture we render to
    id<CAMetalDrawable> currentDrawable = nil;

    // Vertex buffer for sprite quad (legacy single-sprite API)
    id<MTLBuffer> vertexBuffer = nil;

    // Sampler state for texture sampling
    id<MTLSamplerState> samplerState = nil;

    // Current render encoder (valid during frame)
    id<MTLRenderCommandEncoder> renderEncoder = nil;

    // Current command buffer (valid during frame)
    id<MTLCommandBuffer> commandBuffer = nil;

    // Clear color (NES dark blue by default)
    MTLClearColor clearColor = MTLClearColorMake(0.0, 0.0, 0.545, 1.0);

    // Sprite batch shader (needs to persist)
    Shader* batchShader = nullptr;
};

Renderer::Renderer() {
    impl = new RendererImpl();
    spriteBatch = new SpriteBatch();
}

Renderer::~Renderer() {
    shutdown();
    delete spriteBatch;
    spriteBatch = nullptr;
    delete impl;
    impl = nullptr;
}

bool Renderer::init(SDL_Window* window) {
    // Create a Metal view from the SDL window
    // SDL_Metal_CreateView gives us a CAMetalLayer we can render to
    SDL_MetalView metalView = SDL_Metal_CreateView(window);
    if (!metalView) {
        std::cerr << "Failed to create Metal view: " << SDL_GetError() << std::endl;
        return false;
    }

    // Get the CAMetalLayer from the view
    impl->metalLayer = (__bridge CAMetalLayer*)SDL_Metal_GetLayer(metalView);
    if (!impl->metalLayer) {
        std::cerr << "Failed to get CAMetalLayer" << std::endl;
        return false;
    }

    // Create the Metal device (GPU)
    // MTLCreateSystemDefaultDevice() gets the best available GPU
    impl->device = MTLCreateSystemDefaultDevice();
    if (!impl->device) {
        std::cerr << "Failed to create Metal device - no GPU?" << std::endl;
        return false;
    }

    std::cout << "Metal device: " << [impl->device.name UTF8String] << std::endl;

    // Tell the layer which device to use
    impl->metalLayer.device = impl->device;

    // Set pixel format - BGRA8 is standard, sRGB for correct colors
    impl->metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

    // Create command queue
    // All GPU work is submitted through command buffers to this queue
    impl->commandQueue = [impl->device newCommandQueue];
    if (!impl->commandQueue) {
        std::cerr << "Failed to create command queue" << std::endl;
        return false;
    }

    // Create vertex buffer for sprite quad (2 triangles, 6 vertices)
    // This is for the legacy single-sprite API
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

    impl->vertexBuffer = [impl->device newBufferWithBytes:vertices
                                                    length:sizeof(vertices)
                                                   options:MTLResourceStorageModeShared];

    // Create sampler state (nearest neighbor for pixel art)
    MTLSamplerDescriptor* samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToEdge;
    impl->batchShader = new Shader();
    if (!impl->batchShader->load(impl->device, "shaders/sprite_batch.metal")) {
        std::cerr << "Failed to load sprite_batch shader" << std::endl;
        return false;
    }

    // Initialize sprite batch
    if (!spriteBatch->init((__bridge void*)impl->device, 
                           (__bridge void*)impl->batchShader->getPipelineState(),                       10000)) {
        std::cerr << "Failed to initialize sprite batch" << std::endl;
        return false;
    }

    std::cout << "Metal initialized successfully!" << std::endl;
    return true;
}

void Renderer::shutdown() {
    // Shutdown sprite batch first
    if (spriteBatch) {
        spriteBatch->shutdown();
    }

    // Release Metal objects
    // ARC handles most cleanup, but we nil them to be explicit
    if (impl) {
        if (impl->batchShader) {
            impl->batchShader->shutdown();
            delete impl->batchShader;
            impl->batchShader = nullptr;
        }
        impl->commandQueue = nil;
        impl->device = nil;
        impl->metalLayer = nil;
        impl->currentDrawable = nil;
        impl->vertexBuffer = nil;
        impl->samplerState = nil;
        impl->renderEncoder = nil;
        impl->commandBuffer = nil;
    }
}

void Renderer::beginFrame() {
    // Get the next drawable from the layer
    // This is the texture we'll render to
    // It blocks if no drawable is available (triple buffering)
    impl->currentDrawable = [impl->metalLayer nextDrawable];
    if (!impl->currentDrawable) {
        std::cerr << "Failed to get drawable" << std::endl;
        return;
    }

    // Create a command buffer - this holds all our GPU commands for this frame
    impl->commandBuffer = [impl->commandQueue commandBuffer];

    // Create a render pass descriptor - describes what we're rendering to
    MTLRenderPassDescriptor* passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];

    // Configure the color attachment (where pixels go)
    passDescriptor.colorAttachments[0].texture = impl->currentDrawable.texture;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;  // Clear before rendering
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore; // Keep the result
    passDescriptor.colorAttachments[0].clearColor = impl->clearColor;

    // Create a render command encoder - this is where we issue draw calls
    impl->renderEncoder = [impl->commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];

    // Begin sprite batch for this frame and set the encoder for mid-batch flushes
    if (spriteBatch) {
        spriteBatch->begin();
        spriteBatch->setEncoder((__bridge void*)impl->renderEncoder);
    }
}

void Renderer::endFrame() {
    if (!impl->currentDrawable || !impl->renderEncoder || !impl->commandBuffer) {
        return;
    }

    // Flush sprite batch before ending frame
    if (spriteBatch) {
        spriteBatch->end((__bridge void*)impl->renderEncoder);
    }

    // End encoding - we're done with this render pass
    [impl->renderEncoder endEncoding];

    // Present the drawable when the GPU is done
    [impl->commandBuffer presentDrawable:impl->currentDrawable];

    // Submit the command buffer to the GPU
    [impl->commandBuffer commit];

    // Clear current state for next frame
    impl->currentDrawable = nil;
    impl->renderEncoder = nil;
    impl->commandBuffer = nil;
}

void Renderer::setClearColor(float r, float g, float b, float a) {
    impl->clearColor = MTLClearColorMake(r, g, b, a);
}

void Renderer::drawSprite(void* texture, void* pipelineState, float x, float y, float width, float height) {
    if (!impl->renderEncoder) {
        std::cerr << "drawSprite called outside beginFrame/endFrame" << std::endl;
        return;
    }

    id<MTLTexture> mtlTexture = (__bridge id<MTLTexture>)texture;
    id<MTLRenderPipelineState> mtlPipeline = (__bridge id<MTLRenderPipelineState>)pipelineState;

    // Set pipeline state
    [impl->renderEncoder setRenderPipelineState:mtlPipeline];

    // Set vertex buffer
    [impl->renderEncoder setVertexBuffer:impl->vertexBuffer offset:0 atIndex:0];

    // Create MVP matrix (orthographic projection + model transform)
    // Orthographic projection for NES coordinates: -128 to 128 (X), -120 to 120 (Y)
    simd::float4x4 projection = {
        simd::make_float4(2.0f/256.0f, 0, 0, 0),
        simd::make_float4(0, 2.0f/240.0f, 0, 0),
        simd::make_float4(0, 0, 1, 0),
        simd::make_float4(0, 0, 0, 1)
    };

    // Model matrix (scale and translate)
    simd::float4x4 model = {
        simd::make_float4(width, 0, 0, 0),
        simd::make_float4(0, height, 0, 0),
        simd::make_float4(0, 0, 1, 0),
        simd::make_float4(x, y, 0, 1)
    };

    // MVP = Projection * Model
    Uniforms uniforms;
    uniforms.mvp = simd_mul(projection, model);

    // Set uniforms
    [impl->renderEncoder setVertexBytes:&uniforms length:sizeof(Uniforms) atIndex:1];

    // Set texture and sampler
    [impl->renderEncoder setFragmentTexture:mtlTexture atIndex:0];
    [impl->renderEncoder setFragmentSamplerState:impl->samplerState atIndex:0];

    // Draw the quad (6 vertices)
    [impl->renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}

void* Renderer::getDevice() {
    return (__bridge void*)impl->device;
}

void Renderer::setWindowTitle(SDL_Window* window, float fps) {
    char title[64];
    snprintf(title, sizeof(title), "8-Bit Native Engine | %.1f FPS", fps);
    SDL_SetWindowTitle(window, title);
}

SpriteBatch* Renderer::getSpriteBatch() {
    return spriteBatch;
}

void* Renderer::getRenderEncoder() {
    return (__bridge void*)impl->renderEncoder;
}

void* Renderer::getCurrentDrawable() {
    return (__bridge void*)impl->currentDrawable;
}
