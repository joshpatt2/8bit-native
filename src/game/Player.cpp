/**
 * Player implementation
 */

#include "Player.hpp"
#include "engine/SpriteBatch.hpp"
#include <algorithm>

Player::Player(float startX, float startY, void* tex)
    : texture(tex)
{
    x = startX;
    y = startY;
    width = 32.0f;
    height = 32.0f;
}

void Player::update(float dt) {
    if (!input) return;

    // Movement
    vx = 0.0f;
    vy = 0.0f;

    if (input->isDown(Key::Left))  vx = -speed;
    if (input->isDown(Key::Right)) vx = speed;
    if (input->isDown(Key::Up))    vy = speed;
    if (input->isDown(Key::Down))  vy = -speed;

    // Apply velocity
    x += vx * dt;
    y += vy * dt;

    // Clamp to screen bounds (NES coordinates: -128 to 128, -120 to 120)
    x = std::clamp(x, -120.0f, 120.0f);
    y = std::clamp(y, -110.0f, 110.0f);

    // Attack
    if (input->isPressed(Key::Attack) && !attacking) {
        attacking = true;
        attackTimer = 0.2f;  // 200ms attack duration
        // TODO: Spawn attack hitbox entity
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
    batch.draw(texture, x, y, width, height);
    // TODO: Visual feedback when attacking (animation system later)
}
