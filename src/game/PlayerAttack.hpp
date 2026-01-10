/**
 * PlayerAttack - Temporary hitbox entity spawned by player attacks
 * 
 * Exists for a short duration, damages enemies on contact, then disappears.
 */

#pragma once

#include "engine/Entity.hpp"

class PlayerAttack : public Entity {
public:
    PlayerAttack(float x, float y, float lifetime);
    ~PlayerAttack() override;

    void update(float dt) override;
    void render(SpriteBatch& batch) override;
    void onCollision(Entity* other) override;

    int damage = 1;

private:
    float lifetime;
};
