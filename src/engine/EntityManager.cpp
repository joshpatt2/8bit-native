/**
 * EntityManager implementation
 */

#include "EntityManager.hpp"
#include "SpriteBatch.hpp"
#include <algorithm>

EntityManager::EntityManager() {
}

EntityManager::~EntityManager() {
    clear();
}

void EntityManager::update(float dt) {
    for (auto& entity : entities) {
        if (entity && entity->isActive()) {
            entity->update(dt);
        }
    }
}

void EntityManager::render(SpriteBatch& batch) {
    for (auto& entity : entities) {
        if (entity && entity->isActive()) {
            entity->render(batch);
        }
    }
}

void EntityManager::cleanup() {
    entities.erase(
        std::remove_if(entities.begin(), entities.end(),
            [](const std::unique_ptr<Entity>& e) {
                return !e || e->isPendingDestroy();
            }),
        entities.end()
    );
}

void EntityManager::clear() {
    entities.clear();
}
