/**
 * Enemy implementation
 */

#include "Enemy.hpp"
#include "engine/SpriteBatch.hpp"
#include <cmath>

Enemy::Enemy(float startX, float startY, void* tex)
    : texture(tex)
{
    x = startX;
    y = startY;
    width = 24.0f;
    height = 24.0f;
}

void Enemy::update(float dt) {
    if (!target) return;

    // Distance to target
    float dx = target->x - x;
    float dy = target->y - y;
    float distance = std::sqrt(dx * dx + dy * dy);

    // Simple state machine
    switch (state) {
        case State::Idle:
            // Check if player is in range
            if (distance < detectionRange) {
                state = State::Chase;
            }
            break;

        case State::Chase:
            // Move toward target
            if (distance > 1.0f) {
                float dirX = dx / distance;
                float dirY = dy / distance;
                x += dirX * speed * dt;
                y += dirY * speed * dt;
            }

            // Lost sight?
            if (distance > detectionRange * 1.5f) {
                state = State::Idle;
            }
            break;

        case State::Attack:
            // TODO: Attack behavior (later with collision)
            break;
    }
}

void Enemy::render(SpriteBatch& batch) {
    batch.draw(texture, x, y, width, height);
}

void Enemy::takeDamage(int amount) {
    health -= amount;
    if (health <= 0) {
        destroy();  // Mark for cleanup
    }
}
