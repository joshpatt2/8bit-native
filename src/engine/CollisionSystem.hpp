/**
 * CollisionSystem - Handles entity collision detection and response
 * 
 * Uses AABB overlap testing with collision layers/masks for filtering.
 */

#pragma once

class EntityManager;
class Entity;

class CollisionSystem {
public:
    CollisionSystem();
    ~CollisionSystem();

    // Check all entity collisions and invoke callbacks
    void checkCollisions(EntityManager& entities);

private:
    // Determine if two entities should check collision based on layers
    bool shouldCollide(Entity* a, Entity* b);
};
