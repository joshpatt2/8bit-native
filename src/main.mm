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
#include "engine/Audio.hpp"
#include "engine/TextRenderer.hpp"
#include "engine/Screenshot.hpp"
#include "game/Paddle.hpp"
#include "game/Ball.hpp"
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
    
    // Initialize SDL with video and audio subsystems
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0) {
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

    // Load white square texture for Pong rectangles
    Texture whiteSquare;
    if (!whiteSquare.load(device, "assets/sprites/white_square.png")) {
        std::cerr << "Failed to load white square texture" << std::endl;
        spriteShader.shutdown();
        renderer.shutdown();
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    std::cout << "8-Bit Native Engine - PONG" << std::endl;
    std::cout << "Window: " << WINDOW_WIDTH << "x" << WINDOW_HEIGHT << std::endl;
    std::cout << "Use arrow keys to move paddle, ESC to quit." << std::endl;

    // Initialize audio system
    Audio audio;
    g_audio = &audio;
    if (!audio.init()) {
        std::cerr << "Audio init failed (continuing without sound)" << std::endl;
    } else {
        // Load sound effects (attack = paddle hit, hit = wall bounce)
        audio.loadSound("assets/audio/attack.wav");
        audio.loadSound("assets/audio/hit.wav");
    }

    // Initialize text renderer
    TextRenderer textRenderer;
    if (!textRenderer.loadFont(device, "assets/fonts/font8x8.png")) {
        std::cerr << "Failed to load font (continuing without text)" << std::endl;
    }

    // Create entity manager and input
    EntityManager entities;
    Input input;

    // Get sprite batch from renderer
    SpriteBatch* batch = renderer.getSpriteBatch();

    // Create Pong game objects
    Paddle* leftPaddle = entities.spawn<Paddle>(-115.0f, true);   // Player paddle (left)
    leftPaddle->setInput(&input);

    Paddle* rightPaddle = entities.spawn<Paddle>(115.0f, false);  // AI paddle (right)

    Ball* ball = entities.spawn<Ball>();
    ball->setPaddles(leftPaddle, rightPaddle);
    
    // AI paddle tracks the ball
    rightPaddle->setAITarget(ball);

    std::cout << "PONG ready! First to 10 wins." << std::endl;

    // Game state
    int leftScore = 0;
    int rightScore = 0;
    bool gameOver = false;
    const int WINNING_SCORE = 10;

    // Screenshot state
    float gameTime = 0.0f;
    bool screenshotTaken3s = false;

    // Create frame timer targeting 60 FPS
    FrameTimer timer(60);

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

        // Track game time
        gameTime += dt;

        // Update all entities
        entities.update(dt);

        // Check for scoring (ball goes off screen)
        if (!gameOver && ball->isActive()) {
            if (ball->x < -130.0f) {
                // Ball went off left edge - right player scores
                rightScore++;
                std::cout << "SCORE! Left: " << leftScore << " - Right: " << rightScore << std::endl;
                ball->reset();
                
                if (rightScore >= WINNING_SCORE) {
                    gameOver = true;
                    std::cout << "GAME OVER! AI WINS!" << std::endl;
                }
            } else if (ball->x > 130.0f) {
                // Ball went off right edge - left player scores
                leftScore++;
                std::cout << "SCORE! Left: " << leftScore << " - Right: " << rightScore << std::endl;
                ball->reset();
                
                if (leftScore >= WINNING_SCORE) {
                    gameOver = true;
                    std::cout << "GAME OVER! PLAYER WINS!" << std::endl;
                }
            }
        }

        // Clean up destroyed entities (none in Pong, but keep for consistency)
        entities.cleanup();

        // Render frame (beginFrame() calls batch->begin() internally)
        renderer.beginFrame();

        // Render scores first (font texture)
        std::string leftScoreText = std::to_string(leftScore);
        std::string rightScoreText = std::to_string(rightScore);
        textRenderer.drawTextScaled(*batch, -80.0f, 90.0f, leftScoreText, 3.0f, 1.0f, 1.0f, 1.0f);
        textRenderer.drawTextScaled(*batch, 60.0f, 90.0f, rightScoreText, 3.0f, 1.0f, 1.0f, 1.0f);
        
        // Game over message
        if (gameOver) {
            if (leftScore >= WINNING_SCORE) {
                textRenderer.drawTextScaled(*batch, -56.0f, 0.0f, "YOU WIN", 3.0f, 0.3f, 1.0f, 0.3f);
            } else {
                textRenderer.drawTextScaled(*batch, -56.0f, 0.0f, "AI WINS", 3.0f, 1.0f, 0.3f, 0.3f);
            }
        }
        
        // Draw paddles and ball (white_square texture)
        batch->draw((__bridge void*)whiteSquare.getTexture(), leftPaddle->x, leftPaddle->y,
                    leftPaddle->width, leftPaddle->height, 1.0f, 0.0f, 0.0f, 1.0f);
        batch->draw((__bridge void*)whiteSquare.getTexture(), rightPaddle->x, rightPaddle->y,
                    rightPaddle->width, rightPaddle->height, 1.0f, 0.0f, 0.0f, 1.0f);
        batch->draw((__bridge void*)whiteSquare.getTexture(), ball->x, ball->y,
                    ball->width, ball->height, 1.0f, 0.0f, 0.0f, 1.0f);

        // Screenshot at ~3 seconds of gameplay
        if (!screenshotTaken3s && gameTime >= 3.0f) {
            Screenshot::capture(renderer.getCurrentDrawable(), "screenshot_start.bmp");
            screenshotTaken3s = true;
        }

        // Flush remaining sprites to GPU and present
        renderer.endFrame();

        // Sleep to maintain target FPS and reduce CPU usage
        timer.sync();
    }

    // Screenshot before exit - need one more frame to capture
    renderer.beginFrame();
    // Render current game state
    textRenderer.drawTextScaled(*batch, -80.0f, 90.0f, std::to_string(leftScore), 3.0f, 1.0f, 1.0f, 1.0f);
    textRenderer.drawTextScaled(*batch, 60.0f, 90.0f, std::to_string(rightScore), 3.0f, 1.0f, 1.0f, 1.0f);
    if (gameOver) {
        if (leftScore >= WINNING_SCORE) {
            textRenderer.drawTextScaled(*batch, -56.0f, 0.0f, "YOU WIN", 3.0f, 0.3f, 1.0f, 0.3f);
        } else {
            textRenderer.drawTextScaled(*batch, -56.0f, 0.0f, "AI WINS", 3.0f, 1.0f, 0.3f, 0.3f);
        }
    }
    batch->draw((__bridge void*)whiteSquare.getTexture(), leftPaddle->x, leftPaddle->y,
                leftPaddle->width, leftPaddle->height, 1.0f, 0.0f, 0.0f, 1.0f);
    batch->draw((__bridge void*)whiteSquare.getTexture(), rightPaddle->x, rightPaddle->y,
                rightPaddle->width, rightPaddle->height, 1.0f, 0.0f, 0.0f, 1.0f);
    batch->draw((__bridge void*)whiteSquare.getTexture(), ball->x, ball->y,
                ball->width, ball->height, 1.0f, 0.0f, 0.0f, 1.0f);
    Screenshot::capture(renderer.getCurrentDrawable(), "screenshot_exit.bmp");
    renderer.endFrame();

    // Cleanup
    audio.shutdown();
    whiteSquare.shutdown();
    spriteShader.shutdown();
    renderer.shutdown();
    SDL_DestroyWindow(window);
    SDL_Quit();

    std::cout << "Goodbye!" << std::endl;
    return 0;
}
