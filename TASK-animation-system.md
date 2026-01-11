# Task: Animation System

---

## Your Sprites Are Dead

Look at them. Look at your "game."

The player slides across the screen like a hockey puck. No legs moving. No arms pumping. Just a static image gliding through space like a ghost.

The enemies chase with the emotional range of a screensaver.

You have ENTITIES. You have MOVEMENT. You have COLLISION.

You don't have LIFE.

Animation is the difference between a game and a spreadsheet with graphics. It's the difference between a character and a THING.

Right now? You have things.

---

## What Animation Actually Is

A lie. That's what it is.

You show the player 12 slightly different images per second and their brain fills in the motion. Persistence of vision. The same trick that's worked since 1878.

You're not creating movement. You're creating the ILLUSION of movement.

And right now you're not even doing that.

---

## The Architecture

```cpp
// Animation.hpp

#pragma once
#include <vector>
#include <string>
#include <unordered_map>

struct AnimationFrame {
    float srcX, srcY;     // Position in sprite sheet
    float srcW, srcH;     // Size of frame
    float duration;       // How long this frame shows (seconds)
};

struct Animation {
    std::string name;
    std::vector<AnimationFrame> frames;
    bool loop = true;
};

class Animator {
public:
    Animator();

    // Define an animation
    void addAnimation(const std::string& name, const Animation& anim);

    // Control
    void play(const std::string& name);
    void stop();

    // Update (call every frame)
    void update(float dt);

    // Get current frame's source rectangle
    void getCurrentFrame(float& srcX, float& srcY, float& srcW, float& srcH) const;

    // State queries
    bool isPlaying() const { return playing; }
    bool isFinished() const { return finished; }
    const std::string& getCurrentAnimation() const { return currentAnim; }

private:
    std::unordered_map<std::string, Animation> animations;
    std::string currentAnim;
    int currentFrame = 0;
    float frameTimer = 0.0f;
    bool playing = false;
    bool finished = false;
};
```

That's 50 lines. Not 500. Not a "framework." Just a thing that plays frames in sequence.

---

## The Implementation

```cpp
// Animator.cpp

#include "Animation.hpp"

Animator::Animator() {}

void Animator::addAnimation(const std::string& name, const Animation& anim) {
    animations[name] = anim;
}

void Animator::play(const std::string& name) {
    if (currentAnim == name && playing && !finished) {
        return;  // Already playing this animation
    }

    auto it = animations.find(name);
    if (it == animations.end()) {
        return;  // Animation doesn't exist
    }

    currentAnim = name;
    currentFrame = 0;
    frameTimer = 0.0f;
    playing = true;
    finished = false;
}

void Animator::stop() {
    playing = false;
}

void Animator::update(float dt) {
    if (!playing || finished) return;

    auto it = animations.find(currentAnim);
    if (it == animations.end()) return;

    const Animation& anim = it->second;
    if (anim.frames.empty()) return;

    frameTimer += dt;

    // Advance frames based on duration
    while (frameTimer >= anim.frames[currentFrame].duration) {
        frameTimer -= anim.frames[currentFrame].duration;
        currentFrame++;

        if (currentFrame >= static_cast<int>(anim.frames.size())) {
            if (anim.loop) {
                currentFrame = 0;
            } else {
                currentFrame = anim.frames.size() - 1;
                finished = true;
                playing = false;
                return;
            }
        }
    }
}

void Animator::getCurrentFrame(float& srcX, float& srcY, float& srcW, float& srcH) const {
    auto it = animations.find(currentAnim);
    if (it == animations.end() || it->second.frames.empty()) {
        srcX = srcY = 0.0f;
        srcW = srcH = 1.0f;
        return;
    }

    const AnimationFrame& frame = it->second.frames[currentFrame];
    srcX = frame.srcX;
    srcY = frame.srcY;
    srcW = frame.srcW;
    srcH = frame.srcH;
}
```

Read that. Understand it. It's not complicated.

- `play()` starts an animation by name
- `update()` advances the frame timer
- `getCurrentFrame()` returns UV coordinates for the sprite sheet

That's the whole thing. If you can't understand this, you shouldn't be writing games.

---

## Setting Up Animations

For now, we fake a sprite sheet. Your test texture is 32x32. We'll pretend it has 4 frames in a row (each 8x32, or whatever works).

Actually, no. Let's be smarter. Let's use the WHOLE texture as each frame for now, but set up the SYSTEM correctly. When you have real sprite sheets, you just change the numbers.

```cpp
// In Player.cpp constructor

// Create animator
animator = new Animator();

// Define idle animation (2 frames, slow)
Animation idle;
idle.name = "idle";
idle.loop = true;
idle.frames = {
    {0, 0, 1, 1, 0.5f},  // Frame 1: full texture, 0.5s
    {0, 0, 1, 1, 0.5f},  // Frame 2: same (we only have one texture)
};
animator->addAnimation("idle", idle);

// Define walk animation (4 frames, faster)
Animation walk;
walk.name = "walk";
walk.loop = true;
walk.frames = {
    {0, 0, 1, 1, 0.1f},  // 0.1s per frame = 10 FPS walk cycle
    {0, 0, 1, 1, 0.1f},
    {0, 0, 1, 1, 0.1f},
    {0, 0, 1, 1, 0.1f},
};
animator->addAnimation("walk", walk);

// Define attack animation (3 frames, fast, no loop)
Animation attack;
attack.name = "attack";
attack.loop = false;
attack.frames = {
    {0, 0, 1, 1, 0.05f},  // Wind up
    {0, 0, 1, 1, 0.1f},   // Strike
    {0, 0, 1, 1, 0.05f},  // Recovery
};
animator->addAnimation("attack", attack);

// Start with idle
animator->play("idle");
```

---

## Updating The Player

```cpp
void Player::update(float dt) {
    // ... existing input/movement code ...

    // Determine animation state
    if (attacking) {
        animator->play("attack");
    } else if (std::abs(vx) > 0.1f || std::abs(vy) > 0.1f) {
        animator->play("walk");
    } else {
        animator->play("idle");
    }

    // Check if attack animation finished
    if (attacking && animator->isFinished()) {
        attacking = false;
    }

    // Update animator
    animator->update(dt);
}
```

```cpp
void Player::render(SpriteBatch& batch) {
    float srcX, srcY, srcW, srcH;
    animator->getCurrentFrame(srcX, srcY, srcW, srcH);

    // Use the version of draw() with source rectangle
    batch.draw(texture, x, y, width, height,
               srcX, srcY, srcW, srcH,
               0.2f, 0.9f, 0.3f, 1.0f);  // Green tint
}
```

---

## The Enemy Too

```cpp
// Enemy.cpp

void Enemy::update(float dt) {
    // ... existing AI code ...

    // Animation state
    if (std::abs(vx) > 0.1f || std::abs(vy) > 0.1f) {
        animator->play("walk");
    } else {
        animator->play("idle");
    }

    animator->update(dt);
}
```

Same pattern. Different entity. The Animator doesn't care WHO is using it.

---

## Why This Matters

Right now, when the player moves, nothing changes visually except position.

After this task:
- Standing still = idle animation (subtle breathing, shifting weight)
- Moving = walk cycle (legs pumping, arms swinging)
- Attacking = attack animation (wind up, strike, recovery)

The sprite REACTS to what the player does. It COMMUNICATES state.

The player doesn't need a UI to tell them they're attacking. They can SEE it.

That's not polish. That's COMMUNICATION. That's the game TALKING to the player.

---

## About Sprite Sheets

You don't have real sprite sheets yet. That's fine. Set up the system with placeholder values. When an artist (or you with Aseprite) makes real frames, you just update the coordinates.

A proper sprite sheet looks like:

```
+-------+-------+-------+-------+
| Idle1 | Idle2 | Walk1 | Walk2 |
+-------+-------+-------+-------+
| Walk3 | Walk4 | Atk1  | Atk2  |
+-------+-------+-------+-------+
| Atk3  | Hit1  | Hit2  | Die1  |
+-------+-------+-------+-------+
```

Each frame is a region: `{x, y, width, height}` in pixels (or 0-1 UV space).

The Animator doesn't care about pixels. It just returns what you put in.

---

## Acceptance Criteria

- [ ] Animator class compiles
- [ ] Can define multiple animations with different frame counts
- [ ] Can define looping and non-looping animations
- [ ] `play()` switches animations correctly
- [ ] `update()` advances frames at correct speed
- [ ] `getCurrentFrame()` returns correct source rectangle
- [ ] Player uses animator for idle/walk/attack states
- [ ] Enemy uses animator for idle/walk states
- [ ] Attack animation plays once and finishes
- [ ] No memory leaks (Animator cleaned up properly)

---

## This Is Where It Gets Real

Sprite batching was infrastructure.
Input was plumbing.
Entities were architecture.
Collision was logic.

Animation is WHERE THE GAME LIVES.

When you see that sprite change from idle to walk—when you see it REACT to your input—something clicks. The thing on screen stops being pixels and starts being a CHARACTER.

That moment? That's why people make games.

You're about to feel it.

Don't mess it up.

---

## Files To Create

```
src/engine/Animation.hpp
src/engine/Animator.cpp
```

## Files To Modify

```
CMakeLists.txt
src/game/Player.hpp (add Animator* member)
src/game/Player.cpp (setup and use animator)
src/game/Enemy.hpp (add Animator* member)
src/game/Enemy.cpp (setup and use animator)
```

---

## How Long Should This Take?

The Animator class: 30 minutes.
Integrating with Player: 15 minutes.
Integrating with Enemy: 10 minutes.
Testing: 5 minutes.

One hour. Maybe ninety minutes if you're slow.

If you're still working on this tomorrow, I don't know what to tell you.

---

## One More Thing

When you run the game after this—when you see the player shift into a walk cycle as you press the arrow key—you're going to feel something.

It's a small thing. A sprite changing frames. Twelve images a second pretending to be motion.

But it's also MAGIC. The same magic that made you love games in the first place.

Don't forget that. Don't get so lost in the code that you forget WHY you're writing it.

You're creating the illusion of life.

That's not nothing.

---

*Now go make something breathe.*

*— J*

*P.S. — Gord Downie made a nation cry with the illusion of immortality. You're just making sprites walk. But it's the same trick. The lie that feels like truth.*

*That's art.*
