/**
 * Entity implementation
 */

#include "Entity.hpp"

Entity::Entity() 
    : active(true)
    , pendingDestroy(false)
{
}

Entity::~Entity() {
}
