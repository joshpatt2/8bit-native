/**
 * Player - Player-controlled entity
 * 
 * Responds to input, moves with WASD/arrows,
 * stays within screen bounds.
 */

#pragma once

#include "engine/Entity.hpp"
#include "engine/Input.hpp"
#include "engine/Animation.hpp"

class EntityManager;

class Player : public Entity {
public:
    Player(float startX, float startY, void* texture);
    ~Player();

    void update(float dt) override;
    void render(SpriteBatch& batch) override;
    void onCollision(Entity* other) override;

    void setInput(Input* input) { this->input = input; }
    void setEntityManager(EntityManager* em) { entityManager = em; }

    void takeDamage(int amount);
    
    // UI accessors
    int getHealth() const { return health; }
    bool isAlive() const { return health > 0; }

private:
    void setupAnimations();

    Input* input = nullptr;
    EntityManager* entityManager = nullptr;
    void* texture = nullptr;
    Animator* animator = nullptr;

    float speed = 60.0f;  // pixels per second

    // Combat
    int health = 3;
    float invincibleTimer = 0.0f;
    bool attacking = false;
    float attackTimer = 0.0f;
    bool facingRight = true;
};
