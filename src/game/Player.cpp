/**
 * Player implementation
 */

#include "Player.hpp"
#include "PlayerAttack.hpp"
#include "engine/SpriteBatch.hpp"
#include "engine/EntityManager.hpp"
#include <algorithm>

Player::Player(float startX, float startY, void* tex)
    : texture(tex)
{
    x = startX;
    y = startY;
    width = 32.0f;
    height = 32.0f;

    collisionLayer = Layer::Player;
    collisionMask = static_cast<int>(Layer::Enemy) | static_cast<int>(Layer::EnemyAttack);
}

void Player::update(float dt) {
    if (!input) return;

    // Update invincibility timer
    if (invincibleTimer > 0.0f) {
        invincibleTimer -= dt;
    }

    // Movement
    vx = 0.0f;
    vy = 0.0f;

    if (input->isDown(Key::Left)) {
        vx = -speed;
        facingRight = false;
    }
    if (input->isDown(Key::Right)) {
        vx = speed;
        facingRight = true;
    }
    if (input->isDown(Key::Up))    vy = speed;
    if (input->isDown(Key::Down))  vy = -speed;

    // Apply velocity
    x += vx * dt;
    y += vy * dt;

    // Clamp to screen bounds (NES coordinates: -128 to 128, -120 to 120)
    x = std::clamp(x, -120.0f, 120.0f);
    y = std::clamp(y, -110.0f, 110.0f);

    // Attack
    if (input->isPressed(Key::Attack) && !attacking && entityManager) {
        attacking = true;
        attackTimer = 0.15f;

        // Spawn attack hitbox in front of player
        float attackX = x + (facingRight ? 20.0f : -20.0f);
        auto* attack = entityManager->spawn<PlayerAttack>(attackX, y, 0.15f);
        attack->damage = 1;
    }

    // Attack timer
    if (attacking) {
        attackTimer -= dt;
        if (attackTimer <= 0.0f) {
            attacking = false;
        }
    }
}

void Player::render(SpriteBatch& batch) {
    // Flash when invincible
    if (invincibleTimer > 0.0f) {
        int frame = static_cast<int>(invincibleTimer * 10.0f);
        if (frame % 2 == 0) return;  // Flicker effect
    }
    
    batch.draw(texture, x, y, width, height);
}

void Player::onCollision(Entity* other) {
    // Collision handled by enemy->onCollision triggering takeDamage
}

void Player::takeDamage(int amount) {
    if (invincibleTimer > 0) return;  // I-frames active

    health -= amount;
    invincibleTimer = 1.0f;  // 1 second invincibility

    if (health <= 0) {
        destroy();  // Player dies
        // TODO: Game over state
    }
}
