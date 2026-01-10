/**
 * Renderer - Metal rendering backend
 *
 * Handles all GPU communication:
 * - Device/queue creation
 * - Render pass setup
 * - Frame presentation
 *
 * For now: just clears to a color.
 * Later: sprite batching, shaders, textures.
 */

#pragma once

// Forward declare SDL_Window to avoid including SDL in header
struct SDL_Window;

// Forward declare Metal types (actual types are Objective-C)
// We use void* here and cast in the .mm file
struct RendererImpl;

class Renderer {
public:
    Renderer();
    ~Renderer();

    // Initialize Metal with an SDL window
    // Returns false on failure
    bool init(SDL_Window* window);

    // Shutdown and release GPU resources
    void shutdown();

    // Begin a new frame - acquire drawable, start command buffer
    void beginFrame();

    // End frame - commit command buffer, present drawable
    void endFrame();

    // Set clear color (RGBA, 0.0-1.0)
    void setClearColor(float r, float g, float b, float a);

private:
    // Pointer to implementation (PIMPL pattern)
    // Hides Objective-C types from C++ header
    RendererImpl* impl = nullptr;
};
