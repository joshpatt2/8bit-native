/**
 * Entity - Base class for all game objects
 * 
 * Provides common interface for lifecycle (update, render)
 * and basic transform/physics properties.
 */

#pragma once

class SpriteBatch;

class Entity {
public:
    Entity();
    virtual ~Entity();

    // Lifecycle (pure virtual - must override)
    virtual void update(float dt) = 0;
    virtual void render(SpriteBatch& batch) = 0;

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
