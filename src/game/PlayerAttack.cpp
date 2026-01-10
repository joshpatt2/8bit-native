/**
 * PlayerAttack implementation
 */

#include "PlayerAttack.hpp"
#include "Enemy.hpp"
#include "engine/SpriteBatch.hpp"

PlayerAttack::PlayerAttack(float px, float py, float life)
    : lifetime(life)
{
    x = px;
    y = py;
    width = 24.0f;
    height = 24.0f;

    collisionLayer = Layer::PlayerAttack;
    collisionMask = static_cast<int>(Layer::Enemy);
}

PlayerAttack::~PlayerAttack() {
}

void PlayerAttack::update(float dt) {
    lifetime -= dt;
    if (lifetime <= 0) {
        destroy();
    }
}

void PlayerAttack::render(SpriteBatch& batch) {
    // Invisible hitbox - no rendering needed
    // Could draw debug rect here if needed
}

void PlayerAttack::onCollision(Entity* other) {
    // Hit an enemy!
    if (auto* enemy = dynamic_cast<Enemy*>(other)) {
        enemy->takeDamage(damage);
        destroy();  // Attack disappears after hitting
    }
}
