/**
 * Player - Player-controlled entity
 * 
 * Responds to input, moves with WASD/arrows,
 * stays within screen bounds.
 */

#pragma once

#include "engine/Entity.hpp"
#include "engine/Input.hpp"

class Player : public Entity {
public:
    Player(float startX, float startY, void* texture);

    void update(float dt) override;
    void render(SpriteBatch& batch) override;

    void setInput(Input* input) { this->input = input; }

private:
    Input* input = nullptr;
    void* texture = nullptr;

    float speed = 100.0f;  // pixels per second

    // State
    bool attacking = false;
    float attackTimer = 0.0f;
};
