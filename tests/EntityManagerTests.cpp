/**
 * EntityManager Tests
 */

#include "TestFramework.hpp"
#include "engine/EntityManager.hpp"
#include "engine/Entity.hpp"
#include "engine/SpriteBatch.hpp"

// Test entity class
class TestEntity : public Entity {
public:
    int updateCount = 0;
    bool wasRendered = false;
    
    TestEntity(float x, float y) {
        this->x = x;
        this->y = y;
        this->width = 10.0f;
        this->height = 10.0f;
    }
    
    void update(float dt) override {
        updateCount++;
    }
    
    void render(SpriteBatch& batch) override {
        wasRendered = true;
    }
};

TEST(ConstructorInitializesEmpty) {
    EntityManager manager;
    
    ASSERT_EQUAL(manager.count(), 0u, "Manager should start empty");
}

TEST(SpawnAddsEntity) {
    EntityManager manager;
    
    TestEntity* entity = manager.spawn<TestEntity>(10.0f, 20.0f);
    
    ASSERT_NOT_NIL(entity, "Spawn should return valid pointer");
    ASSERT_EQUAL(manager.count(), 1u, "Manager should have 1 entity");
    ASSERT_EQUAL(entity->x, 10.0f, "Entity X should be set");
    ASSERT_EQUAL(entity->y, 20.0f, "Entity Y should be set");
}

TEST(SpawnMultipleEntities) {
    EntityManager manager;
    
    manager.spawn<TestEntity>(0.0f, 0.0f);
    manager.spawn<TestEntity>(10.0f, 10.0f);
    manager.spawn<TestEntity>(20.0f, 20.0f);
    
    ASSERT_EQUAL(manager.count(), 3u, "Manager should have 3 entities");
}

TEST(UpdateCallsAllEntities) {
    EntityManager manager;
    
    TestEntity* e1 = manager.spawn<TestEntity>(0.0f, 0.0f);
    TestEntity* e2 = manager.spawn<TestEntity>(10.0f, 10.0f);
    
    manager.update(0.016f);
    
    ASSERT_EQUAL(e1->updateCount, 1, "First entity should be updated once");
    ASSERT_EQUAL(e2->updateCount, 1, "Second entity should be updated once");
    
    manager.update(0.016f);
    
    ASSERT_EQUAL(e1->updateCount, 2, "First entity should be updated twice");
    ASSERT_EQUAL(e2->updateCount, 2, "Second entity should be updated twice");
}

TEST(CleanupRemovesDestroyedEntities) {
    EntityManager manager;
    
    TestEntity* e1 = manager.spawn<TestEntity>(0.0f, 0.0f);
    TestEntity* e2 = manager.spawn<TestEntity>(10.0f, 10.0f);
    TestEntity* e3 = manager.spawn<TestEntity>(20.0f, 20.0f);
    
    // Mark middle entity for destruction
    e2->destroy();
    
    ASSERT_EQUAL(manager.count(), 3u, "Count should be 3 before cleanup");
    
    manager.cleanup();
    
    ASSERT_EQUAL(manager.count(), 2u, "Count should be 2 after cleanup");
}

TEST(ClearRemovesAllEntities) {
    EntityManager manager;
    
    manager.spawn<TestEntity>(0.0f, 0.0f);
    manager.spawn<TestEntity>(10.0f, 10.0f);
    manager.spawn<TestEntity>(20.0f, 20.0f);
    
    ASSERT_EQUAL(manager.count(), 3u, "Should have 3 entities");
    
    manager.clear();
    
    ASSERT_EQUAL(manager.count(), 0u, "Should have 0 entities after clear");
}

TEST(GetEntitiesReturnsVector) {
    EntityManager manager;
    
    manager.spawn<TestEntity>(0.0f, 0.0f);
    manager.spawn<TestEntity>(10.0f, 10.0f);
    
    auto& entities = manager.getEntities();
    
    ASSERT_EQUAL(entities.size(), 2u, "Should return vector with 2 entities");
}

int main() {
    std::cout << "=== EntityManager Tests ===" << std::endl;
    return TestRunner::instance().runAll();
}
