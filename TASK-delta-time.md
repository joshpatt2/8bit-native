# TASK: Delta Time & Game Loop

**Priority:** CRITICAL (Task 0 - Blocks everything else)  
**Estimated Time:** 2-3 hours  
**Status:** Not Started

---

## WHY THIS MATTERS

Every line of code written without delta time is **framerate-dependent garbage**.

Right now the game loop runs as fast as the CPU allows. On a fast Mac: 1000+ FPS. On a slow machine: 30 FPS. If we write movement code like `x += 5`, a character moves 5000 pixels/second on the fast Mac and 150 pixels/second on the slow machine.

**The problem:**
- Animations play at different speeds on different hardware
- Physics/collision becomes inconsistent
- Game is literally unplayable on anything but the dev machine

**The solution:**
Delta time makes EVERYTHING frame-independent. `x += speed * deltaTime` works identically at 30 FPS or 300 FPS.

---

## CURRENT STATE

**Game loop in main.mm (lines 86-114):**
```cpp
while (running) {
    // Handle events
    while (SDL_PollEvent(&event)) { ... }
    
    // Render frame
    renderer.beginFrame();
    renderer.drawSprite(...);
    renderer.endFrame();
}
```

**Problems:**
- No frame timing
- No FPS cap
- No delta time calculation
- CPU pegged at 100% running infinite loop

---

## WHAT WE'RE BUILDING

### 1. Frame Timer Class

**Location:** `src/engine/FrameTimer.hpp/cpp`

**Interface:**
```cpp
class FrameTimer {
public:
    FrameTimer(int targetFPS = 60);
    
    // Call once per frame - calculates delta time
    void tick();
    
    // Get time since last frame (seconds)
    float getDeltaTime() const;
    
    // Get current FPS (smoothed average)
    float getFPS() const;
    
    // Sleep to maintain target FPS
    void sync();
    
private:
    uint64_t m_lastTime;
    uint64_t m_frequency;
    float m_deltaTime;
    float m_targetFrameTime;
    float m_fpsBuffer[60]; // Rolling average
    int m_fpsIndex;
};
```

**What it does:**
- Uses `SDL_GetPerformanceCounter()` for microsecond precision timing
- Calculates time between frames in seconds (e.g., 0.0166s for 60 FPS)
- Smooths FPS display over 60 samples (avoids jumpy numbers)
- Sleeps remainder of frame to hit target FPS (reduces CPU usage)

### 2. Game Loop Integration

**Modified main.mm:**
```cpp
#include "engine/FrameTimer.hpp"

int main() {
    // ... existing init code ...
    
    FrameTimer timer(60); // Target 60 FPS
    
    while (running) {
        timer.tick(); // Start frame timing
        float dt = timer.getDeltaTime();
        
        // Handle events
        while (SDL_PollEvent(&event)) { ... }
        
        // UPDATE PHASE (currently empty, but ready for future systems)
        // entities.update(dt);
        // physics.update(dt);
        
        // RENDER PHASE
        renderer.beginFrame();
        renderer.drawSprite(...);
        renderer.endFrame();
        
        timer.sync(); // Sleep to maintain 60 FPS
    }
}
```

### 3. FPS Display (Optional Debug Feature)

**Add to Renderer:**
```cpp
void Renderer::setWindowTitle(SDL_Window* window, float fps) {
    char title[64];
    snprintf(title, sizeof(title), "8-Bit Native Engine | %.1f FPS", fps);
    SDL_SetWindowTitle(window, title);
}
```

**In main.mm:**
```cpp
// Update window title every 30 frames
static int frameCount = 0;
if (++frameCount % 30 == 0) {
    renderer.setWindowTitle(window, timer.getFPS());
}
```

---

## SUCCESS METRICS

### Binary (Pass/Fail)
- [ ] Timer compiles without warnings
- [ ] `getDeltaTime()` returns values between 0.01 and 0.05 seconds (20-100 FPS range)
- [ ] Game loop runs at stable 60 FPS on dev machine
- [ ] CPU usage drops below 10% (currently 100% due to infinite loop)

### Measurable
- [ ] Delta time variance < 2ms (stable frame timing)
- [ ] FPS display shows 60.0 ± 1.0 FPS during idle
- [ ] Frame time: ~16.67ms per frame (1000ms / 60 FPS)

### Visual Proof
- [ ] Window title shows "60.0 FPS" during gameplay
- [ ] Activity Monitor shows <10% CPU usage (vs current 100%)

---

## IMPLEMENTATION STEPS

### Step 1: Create FrameTimer.hpp (10 minutes)
- Class declaration with interface above
- Use `<cstdint>` for `uint64_t` types
- Constructor takes target FPS (default 60)

### Step 2: Create FrameTimer.cpp (30 minutes)
- `tick()`: Get current time, calculate delta from last frame, update FPS buffer
- `getDeltaTime()`: Return delta in seconds (divide ticks by frequency)
- `getFPS()`: Average last 60 samples, return smoothed FPS
- `sync()`: Calculate remaining time, `SDL_Delay()` if needed

### Step 3: Integrate into main.mm (10 minutes)
- Include FrameTimer.hpp
- Create timer instance before game loop
- Call `timer.tick()` at start of loop
- Store `dt` for future use (even though nothing uses it yet)
- Call `timer.sync()` at end of loop

### Step 4: Add FPS Display (10 minutes)
- Add `setWindowTitle()` to Renderer.hpp/mm
- Update window title every 30 frames (don't spam it)
- Verify FPS shows 60.0 during idle

### Step 5: Update CMakeLists.txt (5 minutes)
- Add `src/engine/FrameTimer.cpp` to `SOURCES` list
- Recompile and test

### Step 6: Write Unit Tests (30 minutes)
**Location:** `tests/FrameTimerTests.mm`

**Test Cases:**
1. Constructor sets target FPS correctly
2. First `tick()` initializes timing (delta = 0)
3. Second `tick()` produces valid delta time (0.0 < dt < 1.0)
4. `getFPS()` returns reasonable value after 60 ticks
5. `sync()` doesn't crash when called
6. Delta time accumulates correctly over 10 frames

---

## EDGE CASES

### Problem: First Frame Delta Time
**Issue:** On first `tick()`, there's no "last frame" to compare to.  
**Solution:** Return `deltaTime = 0.0f` on first frame. All systems should handle dt=0 gracefully (no movement, no updates).

### Problem: Frame Spike
**Issue:** If one frame takes 500ms (e.g., loading asset), delta time explodes. `x += speed * 0.5` teleports objects.  
**Solution:** Clamp delta time to max 0.1 seconds (10 FPS minimum). Slow frames get multiple small updates instead of one huge jump.

```cpp
float FrameTimer::getDeltaTime() const {
    return std::min(m_deltaTime, 0.1f); // Clamp to 100ms max
}
```

### Problem: VSync Interference
**Issue:** Metal's drawable presentation may block to sync with display (60Hz).  
**Solution:** Accept that FPS cap might be enforced by OS. Don't fight VSync. If target is 60 and display is 60Hz, perfect. If target is 120, we're capped at 60. Log a warning but continue.

---

## DEPENDENCIES

**Before this task:**
- Nothing. This is Task 0. Foundation.

**After this task unlocks:**
- Input system (need dt for analog stick smoothing)
- Entity system (entities update based on dt)
- Animation system (frame progression uses dt)
- Physics/collision (velocity integration uses dt)
- Literally everything that moves or changes over time

---

## TESTING APPROACH

### Manual Testing
1. Run game, verify window title shows ~60 FPS
2. Open Activity Monitor, verify CPU usage <10%
3. Log delta time for 100 frames, verify average ~0.0166s
4. Introduce artificial delay (sleep 50ms per frame), verify dt increases to ~0.067s

### Unit Testing
```cpp
TEST(FrameTimerTests, DeltaTimeWithinBounds) {
    FrameTimer timer(60);
    timer.tick(); // First frame: dt = 0
    
    SDL_Delay(16); // Simulate frame work
    timer.tick(); // Second frame: should measure ~16ms
    
    float dt = timer.getDeltaTime();
    ASSERT_TRUE(dt > 0.01f && dt < 0.05f); // 10-50ms reasonable range
}
```

---

## DEFINITION OF DONE

- [x] FrameTimer.hpp/.cpp created and compiling
- [x] Integrated into main.mm game loop
- [x] Window title displays FPS
- [x] CPU usage below 10% when idle
- [x] Delta time logged to console for 10 frames (visual verification)
- [x] 6 unit tests written and passing
- [x] CMakeLists.txt updated
- [x] Code committed with message: "Add delta time and frame timing system"

**Code compiles, tests pass, FPS is stable. Not done until all boxes checked.**

---

## ANTI-PATTERNS TO AVOID

### ❌ DON'T: Use wall-clock time for gameplay
```cpp
time_t now = time(NULL); // This is calendar time, not frame time
```

### ❌ DON'T: Update at variable rate without dt
```cpp
x += 5; // Speed depends on framerate - BROKEN
```

### ❌ DON'T: Cap FPS with busy-wait
```cpp
while (elapsed < targetTime) {
    // Spin loop - wastes CPU
}
```

### ✅ DO: Use high-resolution timer
```cpp
uint64_t now = SDL_GetPerformanceCounter();
```

### ✅ DO: Scale all movement by dt
```cpp
x += speed * dt; // Frame-independent - CORRECT
```

### ✅ DO: Sleep to yield CPU
```cpp
SDL_Delay(remainingTime); // Let OS do other work
```

---

## NEXT STEPS AFTER COMPLETION

Once delta time is working:

1. **Add test sprite movement** to prove dt works:
```cpp
static float spriteX = 0.0f;
spriteX += 50.0f * dt; // Move 50 pixels/second
if (spriteX > 128.0f) spriteX = -128.0f; // Wrap
renderer.drawSprite(..., spriteX, 0.0f, ...);
```

2. **Verify frame-independence:**
   - Change target FPS to 30: sprite moves at same speed
   - Change target FPS to 120: sprite moves at same speed
   - This proves the system works

3. **Move to Task 1: Input System** (now safe because input can be frame-independent)

---

## REFLECTION

**Why this wasn't Task 1 originally:**
I assumed rendering came first, then timing. Wrong. Timing is **infrastructure**. You don't build a house before pouring the foundation.

**Intern feedback was right:**
Every system built without delta time has to be REWRITTEN later. That's double work. Do it right the first time.

**Lesson learned:**
Plans are only useful if they're in the right ORDER. A beautiful 10-task plan with tasks in the wrong sequence is just organized procrastination.

---

**LET'S BUILD IT.**
