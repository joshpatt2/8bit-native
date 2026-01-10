# Pixel Punch: Feature Scope vs Engine State

## Current Engine Inventory

| Component | Status | Files | Lines |
|-----------|--------|-------|-------|
| Metal Renderer | DONE | Renderer.hpp/mm | 313 |
| Shader System | DONE | Shader.hpp/mm | 128 |
| Texture Loading | DONE | Texture.hpp/mm | 91 |
| Frame Timer | DONE | FrameTimer.hpp/cpp | 104 |
| Sprite Shader | DONE | sprite.metal | 42 |
| Unit Tests | DONE | 3 test files | 28 tests |

**Total: 678 lines of engine code, 28 passing tests**

---

## Pixel Punch Requirements

### Core Game Loop

```
SPAWN -> MOVE -> PUNCH -> FEEDBACK -> SCORE -> REPEAT
```

**Target Experience (10 seconds):**
1. Game boots instantly
2. Player presses arrow, character moves
3. Enemy spawns and approaches
4. Player presses attack, fist flies
5. EXPLOSION of particles, screen shake
6. "50 PTS" floats up
7. Player is hooked

---

## Feature Gap Analysis

### CRITICAL PATH (Must Have)

| Feature | Engine Has | Game Needs | Gap |
|---------|-----------|------------|-----|
| Multiple sprites | 1 sprite | 100+ | **SPRITE BATCHING** |
| Player control | Nothing | Arrow + Attack | **INPUT SYSTEM** |
| Game objects | Nothing | Player, enemies, particles | **ENTITY SYSTEM** |
| Hit detection | Nothing | Fist hits enemy | **COLLISION** |
| Smooth motion | Delta time | Frame-independent movement | Use existing dt |

### JUICE (Makes It Feel Good)

| Feature | Engine Has | Game Needs | Gap |
|---------|-----------|------------|-----|
| Sprite animation | Static sprite | Walk/punch/hit cycles | **ANIMATION** |
| Impact effects | Nothing | Explosions on hit | **PARTICLES** |
| Score display | Nothing | "50 PTS" floating text | **TEXT RENDERING** |

### POLISH (Ship Quality)

| Feature | Engine Has | Game Needs | Gap |
|---------|-----------|------------|-----|
| Sound effects | Nothing | Punch/hit/explosion | **AUDIO** |
| Screen shake | Nothing | Impact feedback | **CAMERA** |
| Game states | Nothing | Title/Play/GameOver | **SCENE SYSTEM** |

---

## Detailed Feature Requirements

### 1. SPRITE BATCHING (Critical)

**Current:** `drawSprite()` makes 1 draw call per sprite.

**Pixel Punch Needs:**
- Player sprite (1)
- 10-20 enemies on screen
- 50-100 particles per hit
- Score text (10-20 characters)
- **Total: 100-150 sprites per frame**

**Implementation:**
```cpp
class SpriteBatch {
    void begin();
    void draw(texture, x, y, w, h, srcX, srcY, srcW, srcH);
    void end(encoder);  // Single draw call
};
```

**Success Metric:** 1000 sprites @ 60 FPS

---

### 2. INPUT SYSTEM (Critical)

**Current:** SDL_PollEvent exists but not abstracted.

**Pixel Punch Needs:**
- Arrow keys: Move player (WASD alternative)
- Spacebar: Punch attack
- Enter: Start game / Confirm
- Escape: Pause / Quit
- Gamepad: D-pad + A button (REQUIRED for arcade feel)

**Implementation:**
```cpp
class Input {
    void update();  // Call once per frame
    bool isKeyDown(Key key);
    bool isKeyPressed(Key key);   // Just pressed this frame
    bool isKeyReleased(Key key);  // Just released
};
```

**Success Metric:** <16ms input latency, keyboard + gamepad working

---

### 3. ENTITY SYSTEM (Critical)

**Current:** Nothing.

**Pixel Punch Needs:**
- Player entity (position, velocity, state, sprite)
- Enemy entities (position, velocity, AI state, health)
- Projectile entities (punch hitbox)
- Particle entities (position, velocity, lifetime, alpha)
- Score popup entities (position, velocity, text, lifetime)

**Implementation Choice: Simple Inheritance (NOT ECS)**

Reasoning: ECS is overkill for an arcade brawler. We need:
- 50-100 entities max
- No complex queries
- Fast iteration speed
- Simple mental model

```cpp
class Entity {
    float x, y;
    float vx, vy;
    bool active;
    virtual void update(float dt) = 0;
    virtual void render(SpriteBatch& batch) = 0;
};

class EntityManager {
    std::vector<std::unique_ptr<Entity>> entities;
    void update(float dt);
    void render(SpriteBatch& batch);
    Entity* spawn<T>();
};
```

**Success Metric:** 100 entities updating @ 60 FPS

---

### 4. COLLISION DETECTION (Critical)

**Current:** Nothing.

**Pixel Punch Needs:**
- Player hitbox (body, for getting hit)
- Player attack box (fist, when punching)
- Enemy hitbox (body)
- Wall/boundary collision

**Implementation:**
```cpp
struct AABB {
    float x, y, w, h;
    bool overlaps(const AABB& other);
};

class CollisionSystem {
    void checkCollisions(EntityManager& entities);
    // Callbacks via virtual methods or std::function
};
```

**Collision Matrix:**
| | Player Body | Player Fist | Enemy Body |
|---|---|---|---|
| Player Body | - | - | HIT PLAYER |
| Player Fist | - | - | HIT ENEMY |
| Enemy Body | HIT PLAYER | HIT ENEMY | - |

**Success Metric:** 20 enemies vs player fist, no false positives/negatives

---

### 5. ANIMATION SYSTEM (High Priority)

**Current:** Static sprite rendering only.

**Pixel Punch Needs:**
- Player idle: 2 frames, 6 FPS
- Player walk: 4 frames, 12 FPS
- Player punch: 3 frames, 24 FPS (fast!)
- Player hit: 2 frames, 12 FPS
- Enemy idle: 2 frames, 6 FPS
- Enemy walk: 4 frames, 8 FPS
- Enemy attack: 3 frames, 12 FPS
- Enemy death: 4 frames, 12 FPS

**Implementation:**
```cpp
struct Animation {
    int startFrame;
    int frameCount;
    float fps;
    bool loop;
};

class Animator {
    void play(Animation& anim);
    void update(float dt);
    int getCurrentFrame();
};
```

**Sprite Sheet Layout:**
```
+-------+-------+-------+-------+
| Idle1 | Idle2 | Walk1 | Walk2 |
+-------+-------+-------+-------+
| Walk3 | Walk4 | Punch1| Punch2|
+-------+-------+-------+-------+
| Punch3| Hit1  | Hit2  | Death1|
+-------+-------+-------+-------+
```

**Success Metric:** Smooth animation transitions, no flickering

---

### 6. PARTICLE SYSTEM (High Priority)

**Current:** Nothing.

**Pixel Punch Needs:**
- Hit explosion: 20-30 particles burst outward
- Death explosion: 50 particles, screen shake
- Dust puffs: 5-10 particles on landing

**Particle Properties:**
- Position (x, y)
- Velocity (vx, vy)
- Acceleration (gravity, drag)
- Lifetime (0.2s - 1.0s)
- Alpha (fade out over lifetime)
- Color (white, yellow, orange for hits)
- Size (2x2 to 8x8 pixels)

**Implementation:**
```cpp
class ParticleSystem {
    struct Particle {
        float x, y, vx, vy;
        float life, maxLife;
        float size;
        uint32_t color;
    };

    std::vector<Particle> particles;  // Pool

    void emit(float x, float y, int count, ParticleConfig& config);
    void update(float dt);
    void render(SpriteBatch& batch);
};
```

**Success Metric:** 200 particles @ 60 FPS, smooth fade-out

---

### 7. TEXT RENDERING (Medium Priority)

**Current:** Nothing.

**Pixel Punch Needs:**
- Score display: "SCORE: 12340" (top of screen)
- Combo text: "5x COMBO!" (center, large)
- Floating damage: "+50" (rises and fades)
- Title screen: "PIXEL PUNCH"
- Game over: "GAME OVER" + "PRESS START"

**Implementation:**
```cpp
class BitmapFont {
    void load(Texture& atlas, const char* charMap, int charWidth, int charHeight);
    void drawText(SpriteBatch& batch, const char* text, float x, float y, float scale);
};
```

**Font Atlas Layout (8x8 characters):**
```
!"#$%&'()*+,-./
0123456789:;<=>?
@ABCDEFGHIJKLMNO
PQRSTUVWXYZ[\]^_
```

**Success Metric:** Render 50 characters @ 60 FPS, readable at 3x scale

---

### 8. AUDIO SYSTEM (Low Priority)

**Current:** Nothing.

**Pixel Punch Needs:**
- Punch swoosh (attack start)
- Hit impact (enemy takes damage)
- Death explosion (enemy dies)
- Player hurt (player takes damage)
- Combo sound (escalating pitch)
- Background music (chiptune loop)

**Implementation:**
```cpp
class Audio {
    void init();
    void loadSound(const char* name, const char* filename);
    void playSound(const char* name);
    void playMusic(const char* filename);
    void setVolume(float volume);
};
```

Library: SDL2_mixer (battle-tested, easy integration)

**Success Metric:** No audio stutter, multiple simultaneous sounds

---

### 9. CAMERA SYSTEM (Low Priority)

**Current:** Fixed orthographic projection.

**Pixel Punch Needs:**
- Screen shake on hit (trauma-based)
- Slight zoom on combo (optional)
- Camera bounds (don't show outside level)

**Implementation:**
```cpp
class Camera {
    float x, y;
    float zoom;
    float trauma;  // 0-1, decays over time

    void shake(float intensity);
    void update(float dt);
    simd::float4x4 getViewMatrix();
};
```

**Screen Shake Formula:**
```
offset_x = maxShake * trauma^2 * perlinNoise(time * frequency)
offset_y = maxShake * trauma^2 * perlinNoise(time * frequency + 1000)
```

**Success Metric:** Satisfying crunch on hit, no motion sickness

---

### 10. SCENE/STATE SYSTEM (Low Priority)

**Current:** Single main loop.

**Pixel Punch Needs:**
- Title Screen: Logo, "PRESS START", high score
- Gameplay: The actual game
- Pause: Overlay, resume/quit options
- Game Over: Score, "PLAY AGAIN?"

**Implementation:**
```cpp
class Scene {
    virtual void enter() = 0;
    virtual void exit() = 0;
    virtual void update(float dt) = 0;
    virtual void render(SpriteBatch& batch) = 0;
};

class SceneManager {
    std::stack<Scene*> scenes;
    void push(Scene* scene);
    void pop();
    void switchTo(Scene* scene);
};
```

**Success Metric:** Clean transitions, no memory leaks on scene change

---

## Implementation Order

### Phase 1: Playable (Critical Path)
1. **Sprite Batching** - Can't render game without it
2. **Input System** - Can't play without controls
3. **Entity System** - Need objects to control
4. **Collision Detection** - Need to hit things

**Milestone: Player can punch enemies**

### Phase 2: Fun (Juice)
5. **Animation System** - Characters come alive
6. **Particle System** - Hits feel impactful
7. **Text Rendering** - Score feedback loop

**Milestone: Demo-worthy, satisfying combat**

### Phase 3: Polish (Ship Quality)
8. **Audio System** - Sound completes the experience
9. **Camera System** - Screen shake = dopamine
10. **Scene System** - Professional game flow

**Milestone: Shippable product**

---

## Asset Requirements

### Sprites Needed
- Player sprite sheet: 32x32 per frame, 14 frames = 32x448
- Enemy Type 1: 32x32 per frame, 12 frames = 32x384
- Particle atlas: 8x8 per particle, 4 types = 32x8
- Font atlas: 8x8 per char, 64 chars = 64x64

### Audio Needed
- 6 sound effects (WAV, 8-bit style)
- 1 background track (OGG, chiptune)

---

## Risk Assessment

| Risk | Probability | Mitigation |
|------|-------------|------------|
| Sprite batching perf issues | Low | Metal is fast, profile early |
| Collision edge cases | High | Write thorough tests, visual debug |
| Animation state bugs | Medium | State machine, clear transitions |
| Audio latency on Mac | Low | SDL2_mixer handles this |
| Scope creep | HIGH | Stick to this document |

---

## Success Criteria

**Technical:**
- [ ] 1000 sprites @ 60 FPS (batching)
- [ ] <16ms input latency (input)
- [ ] 100 entities updating smoothly (entities)
- [ ] No collision false positives (collision)
- [ ] Zero memory leaks (all systems)

**Experience:**
- [ ] Player grins at first punch
- [ ] "One more game" feeling
- [ ] Combo system creates urgency
- [ ] Death feels fair, not cheap

**Code Quality:**
- [ ] Each system has unit tests
- [ ] No compiler warnings
- [ ] Clean git history
- [ ] Documented public APIs

---

## Next Action

**Immediate:** Assign Sprite Batching task to intern (TASK-sprite-batching.md exists)

**After batching:** Input system (requires entity system design first)

**Parallel work (art):** Create player sprite sheet in Aseprite

---

*This is the scope. Do not add features. Do not "improve" systems. Build exactly this, nothing more.*

*Punch things. Feel good. Ship it.*
