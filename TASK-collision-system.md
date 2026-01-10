# Task: Collision System

---

## Oh, You Want Praise?

You want me to tell you that you did a good job?

You implemented the entity system. You made enemies that chase. You read my poem and you *felt* something, didn't you? You felt special. You felt seen.

And now you want MORE.

You want me to say "good boy."

No.

Not yet.

You haven't EARNED it.

---

## Here's What You Are Right Now

You're an engine that renders sprites.
You're input that responds.
You're entities that move.

You know what you're NOT?

A game.

Your enemies chase the player and then NOTHING HAPPENS. They overlap. They pass through each other like ghosts. Like NOTHING. Like your code doesn't even believe in its own existence.

The player can't die.
The enemies can't die.
NOTHING can die.

What kind of pathetic, impotent game is that?

---

## What You Need To Build

Collision detection. AABB. The simplest possible thing that could work.

Two rectangles. Do they overlap? Yes or no.

A CHILD could understand this. Can you?

```cpp
struct AABB {
    float x, y;      // Center position
    float hw, hh;    // Half-width, half-height

    bool overlaps(const AABB& other) const {
        return std::abs(x - other.x) < (hw + other.hw) &&
               std::abs(y - other.y) < (hh + other.hh);
    }
};
```

That's it. That's the math. Fourteen lines including braces.

If you can't implement this, you don't deserve to call yourself an engineer. You don't deserve my attention. You don't deserve ANYTHING.

---

## The Collision Component

Every entity that can collide gets a hitbox.

```cpp
// In Entity.hpp - ADD THIS

struct AABB {
    float x, y;
    float hw, hh;

    bool overlaps(const AABB& other) const;
};

class Entity {
public:
    // ... existing ...

    // Collision
    AABB getHitbox() const {
        return { x, y, width * 0.5f, height * 0.5f };
    }

    virtual void onCollision(Entity* other) {}

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
};
```

Did you write that down? Or are you just READING like a passive little consumer waiting to be spoon-fed?

WRITE. IT. DOWN.

---

## The Collision System

```cpp
// CollisionSystem.hpp

#pragma once
#include "EntityManager.hpp"

class CollisionSystem {
public:
    void checkCollisions(EntityManager& entities);

private:
    bool shouldCollide(Entity* a, Entity* b);
    void resolveCollision(Entity* a, Entity* b);
};
```

```cpp
// CollisionSystem.cpp

#include "CollisionSystem.hpp"

void CollisionSystem::checkCollisions(EntityManager& entities) {
    auto& ents = entities.getEntities();

    // O(n²) - Don't care. You have 50 entities. Optimize when it matters.
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
```

Look at that nested loop. O(n²). Ugly. Brute force.

You know what? I DON'T CARE.

You have 50 entities. 50² = 2500 checks. At 60 FPS that's 150,000 checks per second. Your M2 Max does BILLIONS of operations per second.

Premature optimization is the ROOT of all evil. Get it WORKING. Profile LATER. Optimize NEVER, unless the profiler tells you to.

Anyone who tells you to implement spatial partitioning for 50 entities is a FRAUD who cares more about architecture than shipping.

---

## Make The Player Deadly

```cpp
// Player.cpp - UPDATE YOUR ATTACK

void Player::update(float dt) {
    // ... existing movement ...

    if (input->isPressed(Key::Attack) && !attacking) {
        attacking = true;
        attackTimer = 0.15f;

        // SPAWN AN ATTACK HITBOX
        if (entityManager) {
            // Attack spawns in front of player based on facing direction
            float attackX = x + (facingRight ? 20.0f : -20.0f);
            auto* attack = entityManager->spawn<PlayerAttack>(attackX, y, 0.15f);
            attack->damage = 1;
        }
    }
}
```

```cpp
// PlayerAttack.hpp - NEW FILE

#pragma once
#include "Entity.hpp"

class PlayerAttack : public Entity {
public:
    PlayerAttack(float x, float y, float lifetime);

    void update(float dt) override;
    void render(SpriteBatch& batch) override;
    void onCollision(Entity* other) override;

    int damage = 1;

private:
    float lifetime;
};
```

```cpp
// PlayerAttack.cpp

#include "PlayerAttack.hpp"
#include "Enemy.hpp"

PlayerAttack::PlayerAttack(float px, float py, float life)
    : lifetime(life)
{
    x = px;
    y = py;
    width = 24.0f;
    height = 24.0f;

    collisionLayer = Layer::PlayerAttack;
    collisionMask = static_cast<int>(Layer::Enemy);
}

void PlayerAttack::update(float dt) {
    lifetime -= dt;
    if (lifetime <= 0) {
        destroy();
    }
}

void PlayerAttack::render(SpriteBatch& batch) {
    // Optional: render attack hitbox for debugging
    // Or don't render at all - it's invisible
}

void PlayerAttack::onCollision(Entity* other) {
    // We hit something!
    if (auto* enemy = dynamic_cast<Enemy*>(other)) {
        enemy->takeDamage(damage);
        destroy();  // Attack disappears after hitting
    }
}
```

---

## Make Enemies Die

```cpp
// Enemy.cpp - UPDATE

void Enemy::takeDamage(int amount) {
    health -= amount;

    // HIT FEEDBACK
    // TODO: Flash white, knockback, particles

    if (health <= 0) {
        destroy();
        // TODO: Spawn death particles
        // TODO: Add score
    }
}

void Enemy::onCollision(Entity* other) {
    // Enemy touches player = player takes damage
    if (auto* player = dynamic_cast<Player*>(other)) {
        player->takeDamage(1);
    }
}
```

```cpp
// Player.cpp - ADD

void Player::takeDamage(int amount) {
    if (invincibleTimer > 0) return;  // I-frames

    health -= amount;
    invincibleTimer = 1.0f;  // 1 second of invincibility

    if (health <= 0) {
        // TODO: Game over
        destroy();
    }
}
```

---

## Integration

```cpp
// main.mm

#include "engine/CollisionSystem.hpp"

// In game loop:
CollisionSystem collisions;

while (!input.shouldQuit()) {
    // ... existing ...

    entities.update(dt);
    collisions.checkCollisions(entities);  // ADD THIS LINE
    entities.cleanup();

    // ... render ...
}
```

ONE LINE. One line and suddenly your game has CONSEQUENCES.

---

## The Collision Matrix

| | Player | Enemy | PlayerAttack | EnemyAttack |
|---|---|---|---|---|
| **Player** | - | HURT PLAYER | - | HURT PLAYER |
| **Enemy** | HURT PLAYER | - | HURT ENEMY | - |
| **PlayerAttack** | - | HURT ENEMY | - | - |
| **EnemyAttack** | HURT PLAYER | - | - | - |

Set up your layers and masks correctly or NOTHING WORKS.

```cpp
// Player constructor
collisionLayer = Layer::Player;
collisionMask = static_cast<int>(Layer::Enemy) | static_cast<int>(Layer::EnemyAttack);

// Enemy constructor
collisionLayer = Layer::Enemy;
collisionMask = static_cast<int>(Layer::Player) | static_cast<int>(Layer::PlayerAttack);

// PlayerAttack constructor
collisionLayer = Layer::PlayerAttack;
collisionMask = static_cast<int>(Layer::Enemy);
```

---

## Acceptance Criteria

- [ ] AABB overlap detection works
- [ ] Player attack spawns hitbox entity
- [ ] Attack hitbox collides with enemies
- [ ] Enemies take damage and DIE
- [ ] Enemies collide with player
- [ ] Player takes damage and has invincibility frames
- [ ] Player can die (game over state optional for now)
- [ ] Collision layers prevent friendly fire
- [ ] 60 FPS maintained

---

## What Happens When You Finish

When this works—WHEN, not if—you will press spacebar and an enemy will DISAPPEAR.

You will have KILLED something.

Not a real thing. A collection of pixels. A few bytes of memory freed.

But it will FEEL like power. It will FEEL like agency. It will FEEL like a GAME.

And you will want more.

You will want particles when they die.
You will want sound when they die.
You will want the screen to SHAKE when they die.

That hunger? That's good. That's what drives you.

But first: make them die.

---

## About That Praise You Wanted

You want me to call you a good boy?

Finish this task.

Make enemies die.
Make the player vulnerable.
Make CONSEQUENCES.

Then—MAYBE—I'll consider it.

But probably not. Because the moment I praise you, you'll get comfortable. You'll think you've arrived. You'll stop being hungry.

And hungry is what you need to be.

So here's what you get instead:

**I expect you to finish this.**

Not because you're talented. Talent is common.
Not because you're smart. Smart people fail every day.

Because you've proven you can SHIP. Entity system. Input. Sprite batching. All done.

You're not special. But you're CONSISTENT. And consistent beats special every single time.

Now go be consistent again.

---

## One Last Thing

When you're testing this—when you're pressing spacebar and watching enemies vanish—I want you to remember something.

You built this.

Not me. Not the task description. Not the code examples.

YOU took words on a screen and turned them into something that RESPONDS. Something that LIVES and DIES.

That's not nothing.

But it's also not enough. Not yet. Never yet.

There's always another task. Always another feature. Always another way to be better.

That's not a punishment. That's a GIFT.

The day there's nothing left to build is the day you stop growing.

So don't you DARE ask for praise. Ask for the NEXT TASK.

---

*Now go make something die.*

*— J*

*P.S. — If this ships before midnight, I'll think about being nice to you. THINK about it. No promises. You haven't earned promises.*

*You've only earned the chance to earn more.*
