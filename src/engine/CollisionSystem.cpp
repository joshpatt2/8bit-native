/**
 * CollisionSystem implementation
 */

#include "CollisionSystem.hpp"
#include "EntityManager.hpp"
#include "Entity.hpp"

CollisionSystem::CollisionSystem() {
}

CollisionSystem::~CollisionSystem() {
}

void CollisionSystem::checkCollisions(EntityManager& entities) {
    auto& ents = entities.getEntities();

    // O(n²) - Brute force. Don't care. 50 entities = 2500 checks @ 60 FPS = nothing.
    for (size_t i = 0; i < ents.size(); i++) {
        for (size_t j = i + 1; j < ents.size(); j++) {
            Entity* a = ents[i].get();
            Entity* b = ents[j].get();

            if (!a || !b) continue;
            if (!a->isActive() || !b->isActive()) continue;
            if (!shouldCollide(a, b)) continue;

            AABB boxA = a->getHitbox();
            AABB boxB = b->getHitbox();

            if (boxA.overlaps(boxB)) {
                a->onCollision(b);
                b->onCollision(a);
            }
        }
    }
}

bool CollisionSystem::shouldCollide(Entity* a, Entity* b) {
    // Check if a's layer is in b's mask and vice versa
    int aLayer = static_cast<int>(a->collisionLayer);
    int bLayer = static_cast<int>(b->collisionLayer);

    return (aLayer & b->collisionMask) || (bLayer & a->collisionMask);
}
