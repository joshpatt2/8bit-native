/**
 * 8-Bit Native Engine - Entry Point
 *
 * Creates an SDL2 window with Metal rendering.
 * First milestone: Clear the screen to NES blue.
 */

#include <SDL2/SDL.h>
#include <iostream>
#include "engine/Renderer.hpp"

// NES screen dimensions (scaled up 3x for visibility)
constexpr int NES_WIDTH = 256;
constexpr int NES_HEIGHT = 240;
constexpr int SCALE = 3;
constexpr int WINDOW_WIDTH = NES_WIDTH * SCALE;
constexpr int WINDOW_HEIGHT = NES_HEIGHT * SCALE;

int main(int argc, char* argv[]) {
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

    std::cout << "8-Bit Native Engine started!" << std::endl;
    std::cout << "Window: " << WINDOW_WIDTH << "x" << WINDOW_HEIGHT << std::endl;
    std::cout << "Press ESC or close window to exit." << std::endl;

    // Main loop
    bool running = true;
    SDL_Event event;

    while (running) {
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

        // Render frame - just clear to NES blue for now
        renderer.beginFrame();
        renderer.endFrame();
    }

    // Cleanup
    renderer.shutdown();
    SDL_DestroyWindow(window);
    SDL_Quit();

    std::cout << "Goodbye!" << std::endl;
    return 0;
}
