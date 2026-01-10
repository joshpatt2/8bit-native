/**
 * EntityManager - Manages lifecycle of all game entities
 * 
 * Handles spawning, updating, rendering, and cleanup of entities.
 * Uses unique_ptr for automatic memory management.
 */

#pragma once

#include "Entity.hpp"
#include <vector>
#include <memory>

class SpriteBatch;

class EntityManager {
public:
    EntityManager();
    ~EntityManager();

    // Spawn a new entity of type T
    template<typename T, typename... Args>
    T* spawn(Args&&... args) {
        auto entity = std::make_unique<T>(std::forward<Args>(args)...);
        T* ptr = entity.get();
        entities.push_back(std::move(entity));
        return ptr;
    }

    // Update all active entities
    void update(float dt);

    // Render all active entities
    void render(SpriteBatch& batch);

    // Remove destroyed entities
    void cleanup();

    // Get entity count
    size_t count() const { return entities.size(); }

    // Clear all entities
    void clear();

    // Access entities (for collision, etc.)
    std::vector<std::unique_ptr<Entity>>& getEntities() { return entities; }

private:
    std::vector<std::unique_ptr<Entity>> entities;
};
