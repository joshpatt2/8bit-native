/**
 * Enemy - AI-controlled entity that chases the player
 * 
 * Simple state machine: Idle -> Chase
 * Moves toward target when in range.
 */

#pragma once

#include "engine/Entity.hpp"

class Enemy : public Entity {
public:
    Enemy(float startX, float startY, void* texture);

    void update(float dt) override;
    void render(SpriteBatch& batch) override;
    void onCollision(Entity* other) override;

    void setTarget(Entity* target) { this->target = target; }

    int getHealth() const { return health; }
    void takeDamage(int amount);

private:
    Entity* target = nullptr;  // What to chase (the player)
    void* texture = nullptr;

    float speed = 40.0f;  // Slower than player
    int health = 3;

    // Simple AI state
    enum class State { Idle, Chase, Attack };
    State state = State::Idle;

    float stateTimer = 0.0f;
    float detectionRange = 80.0f;
};
