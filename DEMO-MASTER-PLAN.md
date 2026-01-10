# 8-Bit Native Engine: Demo Game Master Plan

## Vision: Pixel Punch

**What:** A hyper-focused arcade brawler that delivers instant gratification through visceral combat feedback.

**Why This Demo:** Pixel Punch embodies the core principle of engagement design - immediate payoff, clear value proposition, and minimal cognitive load. It's our proof-of-concept that retro aesthetics can deliver modern dopamine hits.

**Success Metric:** Player grins within 10 seconds of first input.

---

## The Demo Experience (Target)

```
Second 0:  Game boots instantly
Second 1:  Player sees sprite, presses arrow key, character moves
Second 2:  Enemy appears, player presses spacebar
Second 3:  EXPLOSION of particles, screen shake, "50 PTS" floats up
Second 5:  Next enemy spawns (different color = different threat)
Second 7:  Player punches again, "100 PTS COMBO!" 
Second 10: Player is addicted, trying to beat their score
```

**Core Loop:** Spawn → Punch → Feedback → Score → Repeat (15 seconds per cycle)

**Why It Requires These Systems:**
- Multiple enemies + particles = **sprite batching**
- Player control = **input system**
- Enemy AI + lifecycle = **entity system**
- Hit detection = **collision detection**
- Smooth 60fps = **delta time loop**
- Character animation = **animation system**
- Explosions = **particle system**
- Score display = **text rendering**

---

## Current Engine State

**✅ What We Have (Milestone 1 Complete):**
- Metal rendering backend
- Single sprite rendering
- Shader pipeline (vertex/fragment)
- Texture loading (PNG with alpha)
- Orthographic projection
- 28 unit tests (all passing)

**❌ What We're Missing:**
- Can only draw 1 sprite per frame
- No input handling
- No game objects or update loop
- No collision detection
- No timing system
- No animation
- No particles
- No text rendering

**The Gap:** We have a beautiful rendering engine, but no *game* engine.

---

## Task Roadmap

### Phase 1: Foundation (Critical Path)
**Goal:** Get from 1 sprite to a playable prototype

#### Task 1: Sprite Batching
**File:** `TASK-sprite-batching.md`

**Why:** Current engine can only draw one sprite. Demo needs 100+ (player + enemies + particles).

**What:**
- Batch multiple sprites into single draw call
- Dynamic vertex buffer for sprite quads
- Texture atlas support (multiple sprites, one texture)
- Instanced rendering or dynamic buffer approach

**Success:** Render 100 sprites at 60fps with no frame drops

**Priority:** CRITICAL - Blocks everything else

---

#### Task 2: Input System
**File:** `TASK-input-system.md`

**Why:** Can't play a game without controls.

**What:**
- SDL2 keyboard input wrapper
- Key states (pressed, held, released)
- Gamepad support (optional)
- Input mapping system

**Success:** Arrow keys move sprite, spacebar triggers action

**Priority:** CRITICAL - No gameplay without this

---

#### Task 3: Entity System
**File:** `TASK-entity-system.md`

**Why:** Need a way to manage player, enemies, particles as individual objects with behavior.

**What:**
- GameObject base class
- Entity manager (add, remove, update all)
- Component-based or inheritance-based architecture
- Transform (position, rotation, scale)
- Update loop integration

**Success:** 50 entities updating independently at 60fps

**Priority:** CRITICAL - Core game architecture

---

#### Task 4: Collision Detection
**File:** `TASK-collision-detection.md`

**Why:** Can't punch enemies without knowing when fist hits face.

**What:**
- AABB (Axis-Aligned Bounding Box) collision
- Collision layers/masks
- OnCollisionEnter callback system
- Spatial partitioning (optional for performance)

**Success:** Detect collision between player and 20 enemies accurately

**Priority:** CRITICAL - No hit detection, no game

---

#### Task 5: Delta Time & Game Loop
**File:** `TASK-delta-time.md`

**Why:** Movement/animation tied to framerate = broken game on different machines.

**What:**
- Frame-independent timing
- Fixed timestep for physics
- Variable timestep for rendering
- FPS counter

**Success:** Game runs at same speed on 60Hz and 120Hz displays

**Priority:** CRITICAL - Professional quality requirement

---

### Phase 2: Juice (Makes It Feel Good)

#### Task 6: Animation System
**File:** `TASK-animation-system.md`

**Why:** Static sprites look dead. Animation = life.

**What:**
- Sprite sheet frame sequencing
- Animation states (idle, walk, attack)
- Framerate control (12fps animation on 60fps game)
- State machine or simple frame player

**Success:** Player sprite has 4-frame walk cycle, 3-frame punch

**Priority:** HIGH - Game feels flat without this

---

#### Task 7: Particle System
**File:** `TASK-particle-system.md`

**Why:** The "explosion" moment is the dopamine hit. Particles = impact.

**What:**
- Particle emitter
- Lifetime, velocity, acceleration
- Color over time
- Pooling (reuse particles for performance)

**Success:** 200 particles spawn on hit, fade out over 0.5s

**Priority:** HIGH - Core to "juicy" feeling

---

#### Task 8: Text Rendering
**File:** `TASK-text-rendering.md`

**Why:** Can't show score without text. Score is the reward signal.

**What:**
- Bitmap font rendering
- Render string from font atlas
- Floating score numbers (animate up and fade)
- UI layer (always on top)

**Success:** Display "Score: 1234" at 60fps, floating "+50" on hit

**Priority:** MEDIUM - Can prototype without, but needed for full demo

---

### Phase 3: Polish (Release Quality)

#### Task 9: Sound System
**File:** `TASK-sound-system.md`

**Why:** Audio feedback completes the sensory loop. Silence = boring.

**What:**
- SDL2 audio integration
- Sound effect playback
- Volume control
- Audio pooling (multiple instances of same sound)

**Success:** Punch sound plays on hit without stutter

**Priority:** LOW - Can demo without, but needed for shipping

---

#### Task 10: Screen Shake & Camera
**File:** `TASK-camera-system.md`

**Why:** Screen shake on hit = primal satisfaction. Camera control = professional feel.

**What:**
- Camera class (position, zoom)
- Screen shake effect (trauma-based)
- Camera smoothing (lerp to target)
- Viewport transformation

**Success:** 2-pixel screen shake on punch, smooth camera follow

**Priority:** LOW - Polish, not core functionality

---

## Task Dependencies

```
Milestone 1: Single Sprite ✅
    ↓
Task 1: Sprite Batching (CRITICAL)
    ↓
    ├── Task 2: Input System (CRITICAL) ───┐
    ├── Task 3: Entity System (CRITICAL) ──┤
    ├── Task 4: Collision (CRITICAL) ──────┤
    └── Task 5: Delta Time (CRITICAL) ─────┤
                                           ↓
                    **PLAYABLE PROTOTYPE** (MVP)
                                           ↓
    ┌── Task 6: Animation (HIGH) ──────────┤
    ├── Task 7: Particles (HIGH) ──────────┤
    └── Task 8: Text Rendering (MEDIUM) ───┤
                                           ↓
                        **FULL DEMO**
                                           ↓
    ┌── Task 9: Sound (LOW) ───────────────┤
    └── Task 10: Camera/Shake (LOW) ───────┤
                                           ↓
                    **SHIPPABLE GAME**
```

---

## Why This Approach Works

**1. Immediate Gratification Design**
Every system is chosen to support the "punch → explosion → score" dopamine loop. No RPG stats, no crafting - just pure arcade action.

**2. Clear Milestone Validation**
After Phase 1, we have a *playable* game (ugly but playable). After Phase 2, we have a *compelling* game. After Phase 3, we have a *shippable* game.

**3. Incremental Dopamine**
Each task completion unlocks visible progress:
- Task 1 done = See multiple sprites
- Task 2 done = Control the player
- Task 3 done = Enemies spawn and move
- Task 4 done = You can hit enemies
- Task 5 done = Everything moves smoothly
- Task 6 done = Sprites come alive
- Task 7 done = Hits feel AMAZING
- Task 8 done = You can see your score climb

**4. De-Risking**
Critical path (Tasks 1-5) de-risks the project early. If any of those fail, we know before investing in polish.

---

## Estimation

**Phase 1 (MVP):** 5 tasks × 4 hours = 20 hours
**Phase 2 (Full Demo):** 3 tasks × 3 hours = 9 hours  
**Phase 3 (Polish):** 2 tasks × 2 hours = 4 hours

**Total: ~33 hours from current state to shippable demo**

---

## Success Criteria (Final Demo)

**Technical:**
- [ ] Render 100+ sprites at 60fps
- [ ] Zero memory leaks
- [ ] All tests passing (target: 100+ tests)
- [ ] Zero compiler warnings

**Experience:**
- [ ] Player smiles within 10 seconds
- [ ] Core loop (spawn → punch → feedback) takes 15 seconds
- [ ] Game runs identically on different machines
- [ ] High score persists between sessions

**Code Quality:**
- [ ] Each system has unit tests
- [ ] README explains how to build and run
- [ ] Code is commented and idiomatic
- [ ] Git history is clean (no "fix fix fix" commits)

---

## The Carmack Principle

> "Get it rendering. Get it playable. Get it shippable. In that order."

We've completed step 1 (rendering). This roadmap is steps 2 and 3.

No feature creep. No "wouldn't it be cool if..." 

Just: Can you punch a thing and feel good? If yes, ship it.

---

## Next Action

**Immediate:** Create `TASK-sprite-batching.md` and execute.

**After that:** Work through critical path (Tasks 2-5) in order.

**Then:** Validate with playable prototype before adding juice.

Let's ship this, good buddy. 🎯
