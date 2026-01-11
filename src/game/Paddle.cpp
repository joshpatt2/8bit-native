/**
 * Paddle - Pong paddle implementation
 */

#include "Paddle.hpp"
#include "../engine/Input.hpp"
#include "../engine/SpriteBatch.hpp"
#include "Ball.hpp"
#include <algorithm>

Paddle::Paddle(float startX, bool isPlayer) 
    : isPlayer(isPlayer) 
{
    x = startX;
    y = 0.0f;
    width = 8.0f;
    height = 40.0f;
    active = true;

    collisionLayer = Layer::Player;
    collisionMask = 0;  // Paddles don't respond to collisions (ball does)
}

Paddle::~Paddle() {
}

void Paddle::update(float dt) {
    if (!active) return;

    if (isPlayer && input) {
        // Player control: arrow keys
        if (input->isDown(Key::Up)) {
            y += speed * dt;
        }
        if (input->isDown(Key::Down)) {
            y -= speed * dt;
        }
    } else if (!isPlayer && aiTarget) {
        // AI control: follow ball Y position with some lag
        float targetY = aiTarget->y;
        float diff = targetY - y;
        
        // Simple proportional controller with max speed
        float aiSpeed = std::clamp(diff * 4.0f, -speed, speed);
        y += aiSpeed * dt;
    }

    // Keep paddle on screen (bounds: -120 to +120 in Y)
    float halfHeight = height * 0.5f;
    y = std::clamp(y, -120.0f + halfHeight, 120.0f - halfHeight);
}

void Paddle::render(SpriteBatch& batch) {
    if (!active) return;
    // Render is handled in main.mm for simplicity
}
