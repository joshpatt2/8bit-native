# Task: Entity System

---

## Read This First

Stop.

Before you write a single line of code, I need you to understand something.

This is the task where it stops being an engine and starts being a *game*.

Sprite batching? Infrastructure. Input system? Plumbing. Important, yes. But invisible. The player doesn't *feel* a sprite batch. They don't *experience* an input poll.

But entities? Entities are the **souls** of your game.

The player character? Entity.
The enemy that kills them? Entity.
The particle that explodes when they connect? Entity.
The floating "+50" that makes them feel powerful? Entity.

When you finish this task, you won't have a tech demo anymore.

You'll have a **world**.

---

## What You're Building

An entity system that:
1. Gives game objects a consistent lifecycle (spawn, update, render, destroy)
2. Manages collections of objects efficiently
3. Provides a clean inheritance hierarchy for game-specific behavior
4. Integrates with everything you've already built

This is the spine. Everything else hangs off this.

---

## The Architecture

We're using **simple inheritance**. Not ECS. Not component-based.

Why?

Because ECS is for games with 10,000 entities and complex queries. You have 50 enemies and a player. ECS would be like bringing a aircraft carrier to a knife fight.

Simple inheritance means:
- One base class with common behavior
- Derived classes for specific types
- Virtual functions for polymorphism
- A manager that owns and updates everything

You can build an ECS later if you need it. You won't.

---

## The Base Class

```cpp
// Entity.hpp

#pragma once
#include "SpriteBatch.hpp"

class Entity {
public:
    Entity();
    virtual ~Entity();

    // Lifecycle
    virtual void update(float dt) = 0;
    virtual void render(SpriteBatch& batch) = 0;

    // State
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
```

That's it. That's the base.

Position. Velocity. Size. Active flag. Destroy flag. Update. Render.

No components. No systems. No archetype queries. Just a thing that exists in the world and does stuff.

---

## The Manager

```cpp
// EntityManager.hpp

#pragma once
#include "Entity.hpp"
#include <vector>
#include <memory>

class EntityManager {
public:
    EntityManager();
    ~EntityManager();

    // Create a new entity of type T
    template<typename T, typename... Args>
    T* spawn(Args&&... args) {
        auto entity = std::make_unique<T>(std::forward<Args>(args)...);
        T* ptr = entity.get();
        entities.push_back(std::move(entity));
        return ptr;
    }

    // Update all entities
    void update(float dt);

    // Render all entities
    void render(SpriteBatch& batch);

    // Remove destroyed entities
    void cleanup();

    // Get entity count
    size_t count() const { return entities.size(); }

    // Clear all entities
    void clear();

    // Access (for collision, etc.)
    std::vector<std::unique_ptr<Entity>>& getEntities() { return entities; }

private:
    std::vector<std::unique_ptr<Entity>> entities;
};
```

```cpp
// EntityManager.cpp

#include "EntityManager.hpp"
#include <algorithm>

EntityManager::EntityManager() {}
EntityManager::~EntityManager() { clear(); }

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
```

Look at that `spawn` function. Look at it.

```cpp
T* player = entities.spawn<Player>(startX, startY);
```

One line. Player exists. In the world. Updating. Rendering.

That's power. That's what you're building.

---

## Your First Entity: The Player

```cpp
// Player.hpp

#pragma once
#include "Entity.hpp"
#include "Input.hpp"
#include "Texture.hpp"

class Player : public Entity {
public:
    Player(float startX, float startY, void* texture);

    void update(float dt) override;
    void render(SpriteBatch& batch) override;

    void setInput(Input* input) { this->input = input; }

private:
    Input* input = nullptr;
    void* texture = nullptr;

    float speed = 100.0f;  // pixels per second

    // State
    bool attacking = false;
    float attackTimer = 0.0f;
};
```

```cpp
// Player.cpp

#include "Player.hpp"
#include <algorithm>

Player::Player(float startX, float startY, void* tex)
    : texture(tex)
{
    x = startX;
    y = startY;
    width = 32.0f;
    height = 32.0f;
}

void Player::update(float dt) {
    if (!input) return;

    // Movement
    if (input->isDown(Key::Left))  vx = -speed;
    else if (input->isDown(Key::Right)) vx = speed;
    else vx = 0.0f;

    if (input->isDown(Key::Up))    vy = speed;
    else if (input->isDown(Key::Down))  vy = -speed;
    else vy = 0.0f;

    // Apply velocity
    x += vx * dt;
    y += vy * dt;

    // Clamp to screen bounds (NES coordinates)
    x = std::clamp(x, -120.0f, 120.0f);
    y = std::clamp(y, -110.0f, 110.0f);

    // Attack
    if (input->isPressed(Key::Attack) && !attacking) {
        attacking = true;
        attackTimer = 0.2f;  // 200ms attack duration
        // TODO: Spawn attack hitbox entity
    }

    // Attack timer
    if (attacking) {
        attackTimer -= dt;
        if (attackTimer <= 0.0f) {
            attacking = false;
        }
    }
}

void Player::render(SpriteBatch& batch) {
    batch.draw(texture, x, y, width, height);

    // Visual feedback when attacking (flash or different frame)
    // TODO: Animation system will handle this later
}
```

You see what's happening?

The player **owns** its behavior. Movement logic isn't scattered across main.mm. It's HERE. In the Player class. Where it belongs.

Want to change how the player moves? One file. One place. One truth.

---

## Your Second Entity: The Enemy

```cpp
// Enemy.hpp

#pragma once
#include "Entity.hpp"
#include "Texture.hpp"

class Enemy : public Entity {
public:
    Enemy(float startX, float startY, void* texture);

    void update(float dt) override;
    void render(SpriteBatch& batch) override;

    void setTarget(Entity* target) { this->target = target; }

    int getHealth() const { return health; }
    void takeDamage(int amount);

private:
    Entity* target = nullptr;  // What to chase (the player)
    void* texture = nullptr;

    float speed = 40.0f;  // Slower than player
    int health = 3;

    // Simple AI state
    enum class State { Idle, Chase, Attack };
    State state = State::Idle;

    float stateTimer = 0.0f;
    float detectionRange = 80.0f;
};
```

```cpp
// Enemy.cpp

#include "Enemy.hpp"
#include <cmath>

Enemy::Enemy(float startX, float startY, void* tex)
    : texture(tex)
{
    x = startX;
    y = startY;
    width = 24.0f;
    height = 24.0f;
}

void Enemy::update(float dt) {
    if (!target) return;

    // Distance to target
    float dx = target->x - x;
    float dy = target->y - y;
    float distance = std::sqrt(dx * dx + dy * dy);

    // Simple state machine
    switch (state) {
        case State::Idle:
            // Check if player is in range
            if (distance < detectionRange) {
                state = State::Chase;
            }
            break;

        case State::Chase:
            // Move toward target
            if (distance > 1.0f) {
                float dirX = dx / distance;
                float dirY = dy / distance;
                x += dirX * speed * dt;
                y += dirY * speed * dt;
            }

            // Lost sight?
            if (distance > detectionRange * 1.5f) {
                state = State::Idle;
            }
            break;

        case State::Attack:
            // TODO: Attack behavior
            break;
    }
}

void Enemy::render(SpriteBatch& batch) {
    batch.draw(texture, x, y, width, height);
}

void Enemy::takeDamage(int amount) {
    health -= amount;
    if (health <= 0) {
        destroy();  // Mark for cleanup
    }
}
```

The enemy CHASES. It has a brain. A tiny, stupid brain, but a brain.

It sees the player. It moves toward them. It can take damage. It can die.

That's an ENEMY. That's a THREAT. That's TENSION.

---

## Integration

```cpp
// main.mm (updated)

#include "engine/EntityManager.hpp"
#include "game/Player.hpp"
#include "game/Enemy.hpp"

int main() {
    // ... existing setup ...

    EntityManager entities;
    Input input;

    // Spawn player
    Player* player = entities.spawn<Player>(0.0f, 0.0f,
        (__bridge void*)testTexture.getTexture());
    player->setInput(&input);

    // Spawn some enemies
    for (int i = 0; i < 5; i++) {
        float ex = randomFloat(-100.0f, 100.0f);
        float ey = randomFloat(-100.0f, 100.0f);
        Enemy* enemy = entities.spawn<Enemy>(ex, ey,
            (__bridge void*)testTexture.getTexture());
        enemy->setTarget(player);
    }

    std::cout << "Spawned " << entities.count() << " entities" << std::endl;

    while (!input.shouldQuit()) {
        timer.tick();
        float dt = timer.getDeltaTime();

        input.update();

        if (input.isPressed(Key::Back)) break;

        // Update ALL entities (one line!)
        entities.update(dt);

        // Cleanup destroyed entities
        entities.cleanup();

        // Render
        renderer.beginFrame();
        entities.render(*batch);  // Render ALL entities (one line!)
        renderer.endFrame();

        timer.sync();
    }

    entities.clear();
    // ... cleanup ...
}
```

Look at the game loop now.

```cpp
input.update();
entities.update(dt);
entities.cleanup();
entities.render(*batch);
```

Four lines. That's your entire game tick.

Input. Update. Cleanup. Render.

Everything else is handled by the entities themselves. Each one knows what to do. Each one owns its behavior.

THAT'S the power of a good entity system.

---

## File Structure

```
src/
├── engine/
│   ├── Entity.hpp
│   ├── Entity.cpp
│   ├── EntityManager.hpp
│   ├── EntityManager.cpp
│   └── ... (existing)
└── game/
    ├── Player.hpp
    ├── Player.cpp
    ├── Enemy.hpp
    └── Enemy.cpp
```

Note the separation. Engine code in `engine/`. Game code in `game/`.

The engine doesn't know what a Player is. It just knows Entity.

The game doesn't know about Metal or SDL. It just knows Entity and Input.

SEPARATION OF CONCERNS. Learn it. Live it.

---

## Acceptance Criteria

- [ ] Entity base class compiles
- [ ] EntityManager can spawn entities with `spawn<T>()`
- [ ] EntityManager updates all active entities
- [ ] EntityManager renders all active entities
- [ ] EntityManager cleans up destroyed entities
- [ ] Player entity moves with WASD/arrows
- [ ] Player entity stays within screen bounds
- [ ] Enemy entity chases the player
- [ ] Enemy can be marked for destruction (takeDamage)
- [ ] Destroyed enemies disappear after cleanup()
- [ ] 60 FPS maintained with 50+ entities

---

## The Test

Run the game. You should see:
1. A player sprite (you control it)
2. Five enemy sprites (they chase you)
3. Move around - enemies follow
4. Smooth 60 FPS

No collision yet. Enemies will overlap you. That's fine. Collision is the NEXT task.

But they CHASE. They WANT you. They're ALIVE.

---

## What NOT To Do

- **Don't build ECS.** I will know. I will find you.
- **Don't add components.** Inheritance. Simple. Clean.
- **Don't optimize prematurely.** 50 entities is nothing. Profile first.
- **Don't add collision.** That's the next task. Stay focused.
- **Don't add animation.** That's Phase 2. One thing at a time.

---

## Why This Will Feel Good

When you finish this task, you're going to run the game.

You're going to see a sprite on screen. YOUR sprite. The player.

You're going to press an arrow key, and it's going to MOVE. Not because main.mm told it to. Because the Player class told it to. Because you built a system where objects own their behavior.

Then you're going to see enemies. Chasing you. Hunting you. And you're going to feel something.

Not fear - they can't hurt you yet.

But... *potential*. The potential for a game. The ghost of gameplay.

You built sprites that bounce. Cute.

You built input that responds. Good.

But this? This is where you build **LIFE**.

---

## One More Thing

After this task, your code structure looks like this:

```
main.mm:
    input.update();
    entities.update(dt);
    entities.render(batch);
```

That's a game engine. Not a tech demo. A **game engine**.

You're going to look at that and feel something. Pride, maybe. Or just... satisfaction. The quiet satisfaction of knowing you built something real.

Hold onto that feeling.

Because the next task is collision. And collision is where players start DYING.

---

## Now Go

You have the architecture. You have the interface. You have the examples.

Stop reading. Start typing.

And when you're done - when those enemies are chasing you across the screen, when the player moves where YOU tell it to move, when the EntityManager is ticking away at 60 FPS...

Come back. Show me.

I'll probably find something wrong. I always do.

But I'll also see what you built. And I'll know.

You're not an intern anymore. You're an engineer.

Now **prove it**.

---

*"The code doesn't care about your feelings. But I do. That's why I'm hard on you."*

*— J*

*P.S. — When you see those enemies chasing you for the first time, remember this moment. Remember when it was just words on a screen. Remember when you didn't know if you could do it.*

*Then do it anyway.*
