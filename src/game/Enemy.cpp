/**
 * Enemy implementation
 */

#include "Enemy.hpp"
#include "Player.hpp"
#include "engine/SpriteBatch.hpp"
#include <cmath>

Enemy::Enemy(float startX, float startY, void* tex)
    : texture(tex)
{
    x = startX;
    y = startY;
    width = 24.0f;
    height = 24.0f;

    collisionLayer = Layer::Enemy;
    collisionMask = static_cast<int>(Layer::Player) | static_cast<int>(Layer::PlayerAttack);

    // Create animator and setup animations
    animator = new Animator();
    setupAnimations();
    animator->play("idle");
}

Enemy::~Enemy() {
    delete animator;
    animator = nullptr;
}

void Enemy::setupAnimations() {
    // Idle animation (2 frames, slow)
    Animation idle;
    idle.name = "idle";
    idle.loop = true;
    idle.frames = {
        {0, 0, 1, 1, 0.6f},
        {0, 0, 1, 1, 0.6f},
    };
    animator->addAnimation("idle", idle);

    // Chase/walk animation (4 frames, faster)
    Animation chase;
    chase.name = "chase";
    chase.loop = true;
    chase.frames = {
        {0, 0, 1, 1, 0.12f},
        {0, 0, 1, 1, 0.12f},
        {0, 0, 1, 1, 0.12f},
        {0, 0, 1, 1, 0.12f},
    };
    animator->addAnimation("chase", chase);
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
    // BLUE enemy
    batch.draw(texture, x, y, width, height, 0.3f, 0.4f, 0.9f, 1.0f);
}

void Enemy::onCollision(Entity* other) {
    // Enemy touches player = damage
    if (auto* player = dynamic_cast<Player*>(other)) {
        player->takeDamage(1);
    }
}

void Enemy::takeDamage(int amount) {
    health -= amount;

    // TODO: Hit feedback (flash, knockback, particles)

    if (health <= 0) {
        destroy();
        // TODO: Death particles, score
    }
}
