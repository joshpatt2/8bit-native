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
#include "engine/EntityManager.hpp"
#include "engine/Input.hpp"
#include "engine/CollisionSystem.hpp"
#include "game/Player.hpp"
#include "game/Enemy.hpp"
#include <cstdlib>
#include <ctime>

// NES screen dimensions (scaled up 3x for visibility)
constexpr int NES_WIDTH = 256;
constexpr int NES_HEIGHT = 240;
constexpr int SCALE = 3;
constexpr int WINDOW_WIDTH = NES_WIDTH * SCALE;
constexpr int WINDOW_HEIGHT = NES_HEIGHT * SCALE;

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
    std::cout << "Use arrow keys to move, SPACE to attack, ESC to quit." << std::endl;

    // Create entity manager and input
    EntityManager entities;
    Input input;

    // Get sprite batch from renderer
    SpriteBatch* batch = renderer.getSpriteBatch();

    // Spawn player at center
    Player* player = entities.spawn<Player>(0.0f, 0.0f, (__bridge void*)testTexture.getTexture());
    player->setInput(&input);
    player->setEntityManager(&entities);

    // Spawn 5 enemies at random positions
    for (int i = 0; i < 5; i++) {
        float ex = randomFloat(-100.0f, 100.0f);
        float ey = randomFloat(-100.0f, 100.0f);
        Enemy* enemy = entities.spawn<Enemy>(ex, ey, (__bridge void*)testTexture.getTexture());
        enemy->setTarget(player);
    }

    std::cout << "Spawned " << entities.count() << " entities (1 player, 5 enemies)" << std::endl;

    // Create frame timer targeting 60 FPS
    FrameTimer timer(60);

    // Create collision system
    CollisionSystem collisions;

    // Main loop
    int frameCount = 0;

    while (!input.shouldQuit()) {
        // Start frame timing
        timer.tick();
        float dt = timer.getDeltaTime();

        // Update window title with FPS every 30 frames
        if (++frameCount % 30 == 0) {
            renderer.setWindowTitle(window, timer.getFPS());
        }

        // Update input (clears per-frame state)
        input.update();

        // Update all entities
        entities.update(dt);

        // Check collisions
        collisions.checkCollisions(entities);

        // Clean up destroyed entities
        entities.cleanup();

        // Render frame
        renderer.beginFrame();
        
        // Render all entities (dereference batch pointer)
        entities.render(*batch);
        
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
