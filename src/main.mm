/**
 * 8-Bit Native Engine - Entry Point
 *
 * Creates an SDL2 window with Metal rendering.
 * Sprite rendering test.
 */

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_metal.h>
#include <iostream>
#include "engine/Renderer.hpp"
#include "engine/Shader.hpp"
#include "engine/Texture.hpp"
#include "engine/FrameTimer.hpp"
#include "engine/SpriteBatch.hpp"
#include <vector>
#include <cstdlib>
#include <ctime>

// NES screen dimensions (scaled up 3x for visibility)
constexpr int NES_WIDTH = 256;
constexpr int NES_HEIGHT = 240;
constexpr int SCALE = 3;
constexpr int WINDOW_WIDTH = NES_WIDTH * SCALE;
constexpr int WINDOW_HEIGHT = NES_HEIGHT * SCALE;

// Test sprite for batching stress test
struct TestSprite {
    float x, y;       // Position
    float vx, vy;     // Velocity
};

// Random float helper
float randomFloat(float min, float max) {
    return min + (static_cast<float>(rand()) / RAND_MAX) * (max - min);
}

int main(int argc, char* argv[]) {
    // Seed random number generator
    srand(static_cast<unsigned>(time(nullptr)));
    
    // Initialize SDL with video subsystem
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL_Init failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    // Create window with Metal support
    // SDL_WINDOW_METAL tells SDL to create a CAMetalLayer for us
    SDL_Window* window = SDL_CreateWindow(
        "8-Bit Native Engine",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        SDL_WINDOW_METAL | SDL_WINDOW_ALLOW_HIGHDPI
    );

    if (!window) {
        std::cerr << "SDL_CreateWindow failed: " << SDL_GetError() << std::endl;
        SDL_Quit();
        return 1;
    }

    // Create Metal renderer
    Renderer renderer;
    if (!renderer.init(window)) {
        std::cerr << "Renderer init failed" << std::endl;
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Get Metal device from renderer
    id<MTLDevice> device = (__bridge id<MTLDevice>)renderer.getDevice();

    // Load shader
    Shader spriteShader;
    if (!spriteShader.load(device, "shaders/sprite.metal")) {
        std::cerr << "Failed to load sprite shader" << std::endl;
        renderer.shutdown();
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Load test texture
    Texture testTexture;
    if (!testTexture.load(device, "assets/sprites/test.png")) {
        std::cerr << "Failed to load test texture" << std::endl;
        spriteShader.shutdown();
        renderer.shutdown();
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    std::cout << "8-Bit Native Engine started!" << std::endl;
    std::cout << "Window: " << WINDOW_WIDTH << "x" << WINDOW_HEIGHT << std::endl;
    std::cout << "Press ESC or close window to exit." << std::endl;

    // Get sprite batch from renderer
    SpriteBatch* batch = renderer.getSpriteBatch();

    // Create 500 bouncing sprites for stress test
    const int SPRITE_COUNT = 500;
    std::vector<TestSprite> sprites(SPRITE_COUNT);
    
    std::cout << "Spawning " << SPRITE_COUNT << " bouncing sprites..." << std::endl;
    
    for (auto& s : sprites) {
        s.x = randomFloat(-100.0f, 100.0f);
        s.y = randomFloat(-100.0f, 100.0f);
        s.vx = randomFloat(-80.0f, 80.0f);  // pixels per second
        s.vy = randomFloat(-80.0f, 80.0f);
    }

    // Create frame timer targeting 60 FPS
    FrameTimer timer(60);

    // Main loop
    bool running = true;
    SDL_Event event;
    int frameCount = 0;

    while (running) {
        // Start frame timing
        timer.tick();
        float dt = timer.getDeltaTime();

        // Handle events
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = false;
            }
            if (event.type == SDL_KEYDOWN) {
                if (event.key.keysym.sym == SDLK_ESCAPE) {
                    running = false;
                }
            }
        }

        // Update window title with FPS every 30 frames
        if (++frameCount % 30 == 0) {
            renderer.setWindowTitle(window, timer.getFPS());
        }

        // Update all sprites (frame-independent movement with delta time)
        for (auto& s : sprites) {
            s.x += s.vx * dt;
            s.y += s.vy * dt;

            // Bounce off edges (NES coordinates: -128 to 128, -120 to 120)
            if (s.x < -120.0f || s.x > 120.0f) s.vx *= -1.0f;
            if (s.y < -110.0f || s.y > 110.0f) s.vy *= -1.0f;
        }

        // Render frame
        renderer.beginFrame();
        
        // Draw all 500 sprites using sprite batch (ONE draw call)
        for (const auto& s : sprites) {
            batch->draw(
                (__bridge void*)testTexture.getTexture(),
                s.x, s.y,
                16.0f, 16.0f  // 16x16 sprite size
            );
        }
        
        renderer.endFrame();

        // Sleep to maintain target FPS and reduce CPU usage
        timer.sync();
    }

    // Cleanup
    testTexture.shutdown();
    spriteShader.shutdown();
    renderer.shutdown();
    SDL_DestroyWindow(window);
    SDL_Quit();

    std::cout << "Goodbye!" << std::endl;
    return 0;
}
