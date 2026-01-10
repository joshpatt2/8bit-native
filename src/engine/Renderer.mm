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
#include <iostream>

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

    // Clear color (NES dark blue by default)
    MTLClearColor clearColor = MTLClearColorMake(0.0, 0.0, 0.545, 1.0);
};

Renderer::Renderer() {
    impl = new RendererImpl();
}

Renderer::~Renderer() {
    shutdown();
    delete impl;
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

    std::cout << "Metal initialized successfully!" << std::endl;
    return true;
}

void Renderer::shutdown() {
    // Release Metal objects
    // ARC handles most cleanup, but we nil them to be explicit
    if (impl) {
        impl->commandQueue = nil;
        impl->device = nil;
        impl->metalLayer = nil;
        impl->currentDrawable = nil;
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
}

void Renderer::endFrame() {
    if (!impl->currentDrawable) {
        return;
    }

    // Create a command buffer - this holds all our GPU commands for this frame
    id<MTLCommandBuffer> commandBuffer = [impl->commandQueue commandBuffer];

    // Create a render pass descriptor - describes what we're rendering to
    MTLRenderPassDescriptor* passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];

    // Configure the color attachment (where pixels go)
    passDescriptor.colorAttachments[0].texture = impl->currentDrawable.texture;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;  // Clear before rendering
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore; // Keep the result
    passDescriptor.colorAttachments[0].clearColor = impl->clearColor;

    // Create a render command encoder - this is where we'd issue draw calls
    // For now, we just clear (no draw calls yet)
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];

    // End encoding - we're done with this render pass
    [encoder endEncoding];

    // Present the drawable when the GPU is done
    [commandBuffer presentDrawable:impl->currentDrawable];

    // Submit the command buffer to the GPU
    [commandBuffer commit];

    // Clear current drawable for next frame
    impl->currentDrawable = nil;
}

void Renderer::setClearColor(float r, float g, float b, float a) {
    impl->clearColor = MTLClearColorMake(r, g, b, a);
}
