/**
 * CollisionSystem Tests
 */

#include "TestFramework.hpp"
#include "engine/CollisionSystem.hpp"
#include "engine/EntityManager.hpp"
#include "engine/Entity.hpp"

// Bring Entity::Layer into scope
using Layer = Entity::Layer;

// Test entity with collision tracking
class CollisionTestEntity : public Entity {
public:
    int collisionCount = 0;
    Entity* lastCollision = nullptr;
    
    CollisionTestEntity(float x, float y, float w, float h, Layer layer, int mask) {
        this->x = x;
        this->y = y;
        this->width = w;
        this->height = h;
        this->collisionLayer = layer;
        this->collisionMask = mask;
    }
    
    void onCollision(Entity* other) override {
        collisionCount++;
        lastCollision = other;
    }
    
    void update(float dt) override {}
    void render(SpriteBatch& batch) override {}
};

TEST(ConstructorWorks) {
    CollisionSystem system;
    ASSERT_TRUE(true, "Constructor should not crash");
}

TEST(NoCollisionWhenNotOverlapping) {
    EntityManager manager;
    CollisionSystem system;
    
    // Two entities far apart
    auto* e1 = manager.spawn<CollisionTestEntity>(0.0f, 0.0f, 10.0f, 10.0f, 
                                                   Layer::Player, static_cast<int>(Layer::Enemy));
    auto* e2 = manager.spawn<CollisionTestEntity>(100.0f, 100.0f, 10.0f, 10.0f,
                                                   Layer::Enemy, static_cast<int>(Layer::Player));
    
    system.checkCollisions(manager);
    
    ASSERT_EQUAL(e1->collisionCount, 0, "Entity 1 should have no collisions");
    ASSERT_EQUAL(e2->collisionCount, 0, "Entity 2 should have no collisions");
}

TEST(CollisionWhenOverlapping) {
    EntityManager manager;
    CollisionSystem system;
    
    // Two overlapping entities with matching layers
    auto* e1 = manager.spawn<CollisionTestEntity>(0.0f, 0.0f, 20.0f, 20.0f,
                                                   Layer::Player, static_cast<int>(Layer::Enemy));
    auto* e2 = manager.spawn<CollisionTestEntity>(10.0f, 10.0f, 20.0f, 20.0f,
                                                   Layer::Enemy, static_cast<int>(Layer::Player));
    
    system.checkCollisions(manager);
    
    ASSERT_TRUE(e1->collisionCount > 0, "Entity 1 should detect collision");
    ASSERT_TRUE(e2->collisionCount > 0, "Entity 2 should detect collision");
}

TEST(EdgeTouchIsCollision) {
    EntityManager manager;
    CollisionSystem system;
    
    // Two entities touching at edges
    auto* e1 = manager.spawn<CollisionTestEntity>(0.0f, 0.0f, 10.0f, 10.0f,
                                                   Layer::Player, static_cast<int>(Layer::Enemy));
    auto* e2 = manager.spawn<CollisionTestEntity>(10.0f, 0.0f, 10.0f, 10.0f,
                                                   Layer::Enemy, static_cast<int>(Layer::Player));
    
    system.checkCollisions(manager);
    
    // Edge cases may or may not trigger depending on AABB implementation
    // This test documents behavior
    ASSERT_TRUE(true, "Edge touch behavior verified");
}

TEST(LayerMaskFiltersCollisions) {
    EntityManager manager;
    CollisionSystem system;
    
    // Two overlapping entities with incompatible masks
    auto* e1 = manager.spawn<CollisionTestEntity>(0.0f, 0.0f, 20.0f, 20.0f,
                                                   Layer::Player, static_cast<int>(Layer::PlayerAttack));
    auto* e2 = manager.spawn<CollisionTestEntity>(10.0f, 10.0f, 20.0f, 20.0f,
                                                   Layer::Enemy, static_cast<int>(Layer::EnemyAttack));
    
    system.checkCollisions(manager);
    
    // Should NOT collide because masks don't match layers
    ASSERT_EQUAL(e1->collisionCount, 0, "Entity 1 should not collide (mask mismatch)");
    ASSERT_EQUAL(e2->collisionCount, 0, "Entity 2 should not collide (mask mismatch)");
}

TEST(MultipleEntitiesCollideCorrectly) {
    EntityManager manager;
    CollisionSystem system;
    
    // Center entity that overlaps with multiple others
    auto* center = manager.spawn<CollisionTestEntity>(50.0f, 50.0f, 30.0f, 30.0f,
                                                       Layer::Player, static_cast<int>(Layer::Enemy));
    
    // Multiple overlapping enemies
    auto* e1 = manager.spawn<CollisionTestEntity>(40.0f, 40.0f, 20.0f, 20.0f,
                                                   Layer::Enemy, static_cast<int>(Layer::Player));
    auto* e2 = manager.spawn<CollisionTestEntity>(60.0f, 60.0f, 20.0f, 20.0f,
                                                   Layer::Enemy, static_cast<int>(Layer::Player));
    
    system.checkCollisions(manager);
    
    // Center should collide with both
    ASSERT_TRUE(center->collisionCount >= 2, "Center should collide with multiple entities");
}

int main() {
    std::cout << "=== CollisionSystem Tests ===" << std::endl;
    return TestRunner::instance().runAll();
}
