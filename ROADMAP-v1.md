# 8-Bit Native Engine - v1.0 Roadmap

## Vision

A native Mac game engine that captures the soul of NES-era games: tight controls, pixel-perfect rendering, authentic constraints. Built from scratch in C++ and Metal so we understand every byte.

---

## v1.0 Release Goal

**Ship a playable side-scrolling platformer demo** that proves the engine works end-to-end.

The demo should feel like a lost NES game - responsive controls, chunky pixels, catchy music.

---

## Demo Game: "PIXEL QUEST"

A 3-level platformer featuring:
- A hero character with run/jump/attack animations
- Enemies with simple patrol AI
- Collectible coins
- One boss fight
- Start screen, level transitions, victory screen
- Chiptune music and sound effects

**Why platformer?** It exercises every engine system: sprites, scrolling, physics, collision, audio, input. If the platformer feels good, the engine is ready.

---

## Engine Features for v1.0

### Tier 1: Core (Must Have)

| Feature | Description | Status |
|---------|-------------|--------|
| **Window/Loop** | SDL2 window, 60fps fixed timestep | ✅ Done |
| **Metal Renderer** | GPU clear, present | ✅ Done |
| **Sprite Rendering** | Draw textured quads with shader | ⬜ Next |
| **Texture Loading** | Load PNG to GPU texture | ⬜ |
| **Sprite Animation** | Frame-based animation system | ⬜ |
| **Tilemap Rendering** | Background tiles from tileset | ⬜ |
| **Camera System** | Follow player, bounds, smooth scroll | ⬜ |
| **Input System** | Keyboard + gamepad, justPressed/isPressed | ⬜ |
| **Collision Detection** | AABB overlap, tilemap collision | ⬜ |
| **Audio Playback** | Music + sound effects (SDL_mixer) | ⬜ |
| **Screen Manager** | Title/gameplay/pause state machine | ⬜ |

### Tier 2: Polish (Should Have)

| Feature | Description | Status |
|---------|-------------|--------|
| **Sprite Batching** | Draw many sprites in one draw call | ⬜ |
| **Palette System** | NES-style 4-color palettes per sprite | ⬜ |
| **Particle Effects** | Simple particles for juice | ⬜ |
| **Screen Shake** | Camera shake on impact | ⬜ |
| **Bitmap Font** | Render text with pixel font | ⬜ |

### Tier 3: Nice to Have (Could Have)

| Feature | Description | Status |
|---------|-------------|--------|
| **Parallax Backgrounds** | Multiple scroll layers | ⬜ |
| **Entity Component System** | Optional ECS for complex games | ⬜ |
| **Hot Reload** | Reload assets without restart | ⬜ |
| **Debug Overlay** | FPS, hitboxes, entity count | ⬜ |

---

## Implementation Order

The order matters. Each feature builds on the last.

```
Phase 1: SEE THINGS
├── 1. Sprite shader (vertex + fragment)
├── 2. Texture loading (PNG → MTLTexture)
├── 3. Draw single sprite
└── 4. Sprite batching (draw many)

Phase 2: MOVE THINGS
├── 5. Input system (keyboard)
├── 6. Basic physics (velocity, gravity)
├── 7. Player movement
└── 8. Gamepad support

Phase 3: SCROLL THINGS
├── 9.  Tilemap rendering
├── 10. Camera follow
├── 11. Camera bounds
└── 12. Tilemap collision

Phase 4: HEAR THINGS
├── 13. SDL_mixer setup
├── 14. Sound effects
└── 15. Music playback

Phase 5: GAME THINGS
├── 16. Screen manager
├── 17. Sprite animation
├── 18. Enemy AI (patrol)
├── 19. Player attack
└── 20. Boss fight

Phase 6: POLISH THINGS
├── 21. Bitmap font
├── 22. UI (score, lives)
├── 23. Particles
├── 24. Screen shake
└── 25. Final demo levels
```

---

## Technical Constraints (NES Spirit)

We enforce these to maintain the aesthetic:

| Constraint | Value | Reason |
|------------|-------|--------|
| Resolution | 256×240 (scaled 3x) | NES native |
| Tile size | 8×8 pixels | NES PPU |
| Colors per sprite | 4 (including transparent) | NES limit |
| Max sprites | 64 on screen | NES OAM |
| Frame rate | 60 FPS | NES NTSC |

These are soft constraints - the engine CAN do more, but the demo should respect them.

---

## File Structure (Target)

```
8bit-native/
├── CMakeLists.txt
├── src/
│   ├── main.cpp
│   ├── engine/
│   │   ├── Renderer.hpp/mm     ✅
│   │   ├── Shader.hpp/mm
│   │   ├── Texture.hpp/mm
│   │   ├── Sprite.hpp/cpp
│   │   ├── SpriteBatch.hpp/cpp
│   │   ├── Tilemap.hpp/cpp
│   │   ├── Camera.hpp/cpp
│   │   ├── Input.hpp/cpp
│   │   ├── Collision.hpp/cpp
│   │   ├── Audio.hpp/cpp
│   │   ├── Screen.hpp/cpp
│   │   └── Animation.hpp/cpp
│   └── game/
│       ├── Game.cpp
│       ├── Player.cpp
│       ├── Enemy.cpp
│       └── Level.cpp
├── shaders/
│   ├── sprite.metal
│   └── tilemap.metal
└── assets/
    ├── sprites/
    ├── tilesets/
    ├── levels/
    └── audio/
```

---

## Intern Task Assignments

Break features into intern-sized tasks:

| Task | Assignee | Prereqs |
|------|----------|---------|
| Sprite shader | Sonnet | Renderer done |
| Texture loading | Sonnet | Shader done |
| Input system | Sonnet | None |
| Camera system | Sonnet | Sprite rendering |
| Audio setup | Sonnet | None |
| Tilemap rendering | Sonnet | Texture loading |
| Collision detection | Sonnet | Tilemap done |

**Review all intern work before merging.**

---

## Success Criteria for v1.0

The release is ready when:

1. ✅ Demo game runs at 60fps on Mac
2. ✅ Controls feel responsive (< 16ms input latency)
3. ✅ All 3 levels are playable start-to-finish
4. ✅ Music and sound effects play correctly
5. ✅ No crashes during normal gameplay
6. ✅ Code is commented and understandable

---

## What We'll Learn

By the end of v1.0, we will understand:

- **Metal API**: Devices, queues, command buffers, render passes
- **Shader programming**: MSL vertex/fragment shaders
- **GPU memory**: Textures, buffers, uniforms
- **Sprite batching**: Efficient 2D rendering
- **Game architecture**: Input→Update→Render loop
- **Collision detection**: AABB, spatial partitioning concepts
- **Audio programming**: Mixing, formats, timing

---

## Next Immediate Step

**Task: Sprite Shader**

Write `shaders/sprite.metal` that:
1. Takes vertex position + UV coordinates
2. Samples a texture
3. Outputs pixel color with alpha cutoff

This is the foundation for everything visual.

---

*"First, draw a sprite. Then draw a thousand."*
