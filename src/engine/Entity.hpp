/**
 * Entity - Base class for all game objects
 * 
 * Provides common interface for lifecycle (update, render)
 * and basic transform/physics properties.
 */

#pragma once

#include <cmath>

class SpriteBatch;

// AABB - Axis-Aligned Bounding Box for collision detection
struct AABB {
    float x, y;      // Center position
    float hw, hh;    // Half-width, half-height

    bool overlaps(const AABB& other) const {
        return std::abs(x - other.x) < (hw + other.hw) &&
               std::abs(y - other.y) < (hh + other.hh);
    }
};

class Entity {
public:
    Entity();
    virtual ~Entity();

    // Lifecycle (pure virtual - must override)
    virtual void update(float dt) = 0;
    virtual void render(SpriteBatch& batch) = 0;

    // Collision
    virtual void onCollision(Entity* other) {}

    AABB getHitbox() const {
        return { x, y, width * 0.5f, height * 0.5f };
    }

    // Collision layers
    enum class Layer {
        None = 0,
        Player = 1,
        Enemy = 2,
        PlayerAttack = 4,
        EnemyAttack = 8
    };

    Layer collisionLayer = Layer::None;
    int collisionMask = 0;  // What layers I collide WITH

    // State management
    bool isActive() const { return active; }
    void setActive(bool a) { active = a; }
    void destroy() { pendingDestroy = true; }
    bool isPendingDestroy() const { return pendingDestroy; }

    // Transform
    float x = 0.0f;
    float y = 0.0f;
    float width = 16.0f;
    float height = 16.0f;

    // Physics (simple)
    float vx = 0.0f;
    float vy = 0.0f;

protected:
    bool active = true;
    bool pendingDestroy = false;
};
