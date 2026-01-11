/**
 * Player implementation
 */

#include "Player.hpp"
#include "PlayerAttack.hpp"
#include "engine/SpriteBatch.hpp"
#include "engine/EntityManager.hpp"
#include "engine/Audio.hpp"
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

    // Create animator and setup animations
    animator = new Animator();
    setupAnimations();
    animator->play("idle");
}

void Player::setupAnimations() {
    // For now, all frames use full texture (0,0,1,1) since we only have one sprite
    // When we have real sprite sheets, update these coordinates

    // Idle animation (2 frames, slow pulse)
    Animation idle;
    idle.name = "idle";
    idle.loop = true;
    idle.frames = {
        {0, 0, 1, 1, 0.5f},
        {0, 0, 1, 1, 0.5f},
    };
    animator->addAnimation("idle", idle);

    // Walk animation (4 frames)
    Animation walk;
    walk.name = "walk";
    walk.loop = true;
    walk.frames = {
        {0, 0, 1, 1, 0.1f},
        {0, 0, 1, 1, 0.1f},
        {0, 0, 1, 1, 0.1f},
        {0, 0, 1, 1, 0.1f},
    };
    animator->addAnimation("walk", walk);

    // Attack animation (3 frames, fast, no loop)
    Animation attack;
    attack.name = "attack";
    attack.loop = false;
    attack.frames = {
        {0, 0, 1, 1, 0.05f},  // Wind up
        {0, 0, 1, 1, 0.1f},   // Strike
        {0, 0, 1, 1, 0.05f},  // Recovery
    };
    animator->addAnimation("attack", attack);
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

        // Play attack sound
        if (g_audio) g_audio->playSound(sndAttack);

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

    // Update animation state
    if (attacking) {
        animator->play("attack");
    } else if (std::abs(vx) > 0.1f || std::abs(vy) > 0.1f) {
        animator->play("walk");
    } else {
        animator->play("idle");
    }

    // Update animator
    animator->update(dt);
}

void Player::render(SpriteBatch& batch) {
    // Flash when invincible
    if (invincibleTimer > 0.0f) {
        int frame = static_cast<int>(invincibleTimer * 10.0f);
        if (frame % 2 == 0) return;  // Flicker effect
    }

    // Get current animation frame
    float srcX, srcY, srcW, srcH;
    animator->getCurrentFrame(srcX, srcY, srcW, srcH);

    // GREEN player with animation frame
    batch.draw(texture, x, y, width, height,
               srcX, srcY, srcW, srcH,
               0.2f, 0.9f, 0.3f, 1.0f);
}

Player::~Player() {
    delete animator;
    animator = nullptr;
}

void Player::onCollision(Entity* other) {
    // Collision handled by enemy->onCollision triggering takeDamage
}

void Player::takeDamage(int amount) {
    if (invincibleTimer > 0) return;  // I-frames active

    health -= amount;
    invincibleTimer = 1.0f;  // 1 second invincibility

    // Play hurt sound
    if (g_audio) g_audio->playSound(sndPlayerHurt);

    if (health <= 0) {
        destroy();  // Player dies
        // TODO: Game over state
    }
}
