/**
 * Ball - Pong ball implementation
 */

#include "Ball.hpp"
#include "Paddle.hpp"
#include "../engine/SpriteBatch.hpp"
#include "../engine/Audio.hpp"
#include <cmath>
#include <cstdlib>

Ball::Ball() {
    width = 6.0f;
    height = 6.0f;
    active = true;

    collisionLayer = Layer::None;
    collisionMask = 0;

    reset();
}

Ball::~Ball() {
}

void Ball::reset() {
    x = 0.0f;
    y = 0.0f;

    // Random initial angle (between -45 and +45 degrees from horizontal)
    float angle = ((rand() % 90) - 45) * 3.14159f / 180.0f;
    
    // Random direction (left or right)
    float direction = (rand() % 2 == 0) ? 1.0f : -1.0f;

    vx = cos(angle) * baseSpeed * direction;
    vy = sin(angle) * baseSpeed;
}

void Ball::setPaddles(Paddle* left, Paddle* right) {
    leftPaddle = left;
    rightPaddle = right;
}

void Ball::update(float dt) {
    if (!active) return;

    // Move ball
    x += vx * dt;
    y += vy * dt;

    // Bounce off top/bottom walls
    if (y + height * 0.5f > 120.0f) {
        y = 120.0f - height * 0.5f;
        vy = -vy;
        if (g_audio) g_audio->playSound(1);  // Hit sound
    }
    if (y - height * 0.5f < -120.0f) {
        y = -120.0f + height * 0.5f;
        vy = -vy;
        if (g_audio) g_audio->playSound(1);  // Hit sound
    }

    // Check paddle collisions
    if (leftPaddle) checkPaddleCollision(leftPaddle);
    if (rightPaddle) checkPaddleCollision(rightPaddle);
}

void Ball::checkPaddleCollision(Paddle* paddle) {
    AABB ballBox = getHitbox();
    AABB paddleBox = paddle->getHitbox();

    if (ballBox.overlaps(paddleBox)) {
        // Bounce ball off paddle
        if (vx < 0 && paddle->x < 0) {
            // Bounce off left paddle
            vx = -vx;
            x = paddle->x + paddle->width * 0.5f + width * 0.5f;
        } else if (vx > 0 && paddle->x > 0) {
            // Bounce off right paddle
            vx = -vx;
            x = paddle->x - paddle->width * 0.5f - width * 0.5f;
        }

        // Add some English based on where ball hits paddle
        float hitOffset = y - paddle->y;  // -3 to +3 range
        vy += hitOffset * 2.0f;  // Influence vertical velocity

        // Speed up slightly on each hit (max 1.5x base speed)
        float currentSpeed = sqrt(vx * vx + vy * vy);
        if (currentSpeed < baseSpeed * 1.5f) {
            float speedMultiplier = 1.05f;
            vx *= speedMultiplier;
            vy *= speedMultiplier;
        }

        if (g_audio) g_audio->playSound(0);  // Attack sound (paddle hit)
    }
}

void Ball::render(SpriteBatch& batch) {
    if (!active) return;
    // Render is handled in main.mm for simplicity
}
