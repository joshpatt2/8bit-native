# Task: Input System

## Why This Is Next

You can render 500 sprites. Congratulations. They bounce around like screensavers from 1995.

You know what the player can do? WATCH. That's it. They can watch your sprites bounce.

A game requires INPUT. The player presses a button, something happens. That's the contract.

Right now we have no contract. We have a tech demo.

---

## What You're Building

An `Input` class that:
1. Polls SDL events once per frame
2. Tracks key states (up, down, just pressed, just released)
3. Provides a clean API for gameplay code to query
4. Supports gamepad (because this is an arcade brawler, not a spreadsheet)

---

## The Interface

```cpp
// Input.hpp

#pragma once
#include <SDL2/SDL.h>
#include <unordered_map>

// Abstract key codes (game doesn't care if it's keyboard or gamepad)
enum class Key {
    Left,
    Right,
    Up,
    Down,
    Attack,    // Spacebar or gamepad A
    Start,     // Enter or gamepad Start
    Back       // Escape or gamepad B
};

class Input {
public:
    Input();
    ~Input();

    // Call once at start of frame, before game logic
    void update();

    // Key state queries
    bool isDown(Key key) const;       // Currently held
    bool isPressed(Key key) const;    // Just pressed THIS frame
    bool isReleased(Key key) const;   // Just released THIS frame

    // Raw SDL access (for quit events, etc.)
    bool shouldQuit() const;

private:
    std::unordered_map<Key, bool> currentState;
    std::unordered_map<Key, bool> previousState;
    bool quitRequested = false;

    // Internal helpers
    void updateKeyboardState();
    void updateGamepadState();
    Key mapSDLKey(SDL_Keycode key);
};
```

---

## How It Works

### The State Machine

Every key has two states tracked:
- `previousState`: What it was LAST frame
- `currentState`: What it is THIS frame

From these two, we derive:

| Previous | Current | Meaning |
|----------|---------|---------|
| false | false | Up (not pressed) |
| false | true | **Just Pressed** |
| true | true | Held (still down) |
| true | false | **Just Released** |

```cpp
bool Input::isDown(Key key) const {
    auto it = currentState.find(key);
    return it != currentState.end() && it->second;
}

bool Input::isPressed(Key key) const {
    auto curr = currentState.find(key);
    auto prev = previousState.find(key);
    bool currDown = (curr != currentState.end() && curr->second);
    bool prevDown = (prev != previousState.end() && prev->second);
    return currDown && !prevDown;  // Down now, wasn't before
}

bool Input::isReleased(Key key) const {
    auto curr = currentState.find(key);
    auto prev = previousState.find(key);
    bool currDown = (curr != currentState.end() && curr->second);
    bool prevDown = (prev != previousState.end() && prev->second);
    return !currDown && prevDown;  // Up now, was down before
}
```

### The Update Loop

```cpp
void Input::update() {
    // Save current as previous
    previousState = currentState;

    // Poll SDL events
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            quitRequested = true;
        }
    }

    // Update keyboard state
    updateKeyboardState();

    // Update gamepad state (if connected)
    updateGamepadState();
}
```

### Keyboard Mapping

```cpp
void Input::updateKeyboardState() {
    const Uint8* keystate = SDL_GetKeyboardState(nullptr);

    currentState[Key::Left]   = keystate[SDL_SCANCODE_LEFT]  || keystate[SDL_SCANCODE_A];
    currentState[Key::Right]  = keystate[SDL_SCANCODE_RIGHT] || keystate[SDL_SCANCODE_D];
    currentState[Key::Up]     = keystate[SDL_SCANCODE_UP]    || keystate[SDL_SCANCODE_W];
    currentState[Key::Down]   = keystate[SDL_SCANCODE_DOWN]  || keystate[SDL_SCANCODE_S];
    currentState[Key::Attack] = keystate[SDL_SCANCODE_SPACE] || keystate[SDL_SCANCODE_Z];
    currentState[Key::Start]  = keystate[SDL_SCANCODE_RETURN];
    currentState[Key::Back]   = keystate[SDL_SCANCODE_ESCAPE];
}
```

### Gamepad Support

```cpp
void Input::updateGamepadState() {
    // Check if gamepad is connected
    if (SDL_NumJoysticks() < 1) return;

    // Open gamepad if not already open
    static SDL_GameController* controller = nullptr;
    if (!controller && SDL_IsGameController(0)) {
        controller = SDL_GameControllerOpen(0);
    }
    if (!controller) return;

    // D-pad
    currentState[Key::Left]  |= SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_LEFT);
    currentState[Key::Right] |= SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_RIGHT);
    currentState[Key::Up]    |= SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_UP);
    currentState[Key::Down]  |= SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_DOWN);

    // Buttons
    currentState[Key::Attack] |= SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_A);
    currentState[Key::Start]  |= SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_START);
    currentState[Key::Back]   |= SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_B);

    // Left stick (treat as d-pad with deadzone)
    const int DEADZONE = 8000;
    int leftX = SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTX);
    int leftY = SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTY);

    if (leftX < -DEADZONE) currentState[Key::Left] = true;
    if (leftX > DEADZONE)  currentState[Key::Right] = true;
    if (leftY < -DEADZONE) currentState[Key::Up] = true;
    if (leftY > DEADZONE)  currentState[Key::Down] = true;
}
```

---

## Integration with main.mm

```cpp
#include "engine/Input.hpp"

int main() {
    // ... existing setup ...

    Input input;

    // Test sprite that player controls
    float playerX = 0.0f;
    float playerY = 0.0f;
    const float PLAYER_SPEED = 100.0f;  // pixels per second

    while (!input.shouldQuit()) {
        timer.tick();
        float dt = timer.getDeltaTime();

        // Update input state
        input.update();

        // Check for quit
        if (input.isPressed(Key::Back)) {
            break;
        }

        // Move player based on input
        if (input.isDown(Key::Left))  playerX -= PLAYER_SPEED * dt;
        if (input.isDown(Key::Right)) playerX += PLAYER_SPEED * dt;
        if (input.isDown(Key::Up))    playerY += PLAYER_SPEED * dt;
        if (input.isDown(Key::Down))  playerY -= PLAYER_SPEED * dt;

        // Attack feedback (just print for now)
        if (input.isPressed(Key::Attack)) {
            std::cout << "PUNCH!" << std::endl;
        }

        // Clamp to screen bounds
        playerX = std::max(-120.0f, std::min(120.0f, playerX));
        playerY = std::max(-110.0f, std::min(110.0f, playerY));

        // Render
        renderer.beginFrame();

        // Draw player sprite (controlled by input)
        batch->draw((__bridge void*)testTexture.getTexture(),
                    playerX, playerY, 32.0f, 32.0f);

        // Draw some static sprites for reference
        batch->draw((__bridge void*)testTexture.getTexture(),
                    -80.0f, 0.0f, 16.0f, 16.0f);
        batch->draw((__bridge void*)testTexture.getTexture(),
                    80.0f, 0.0f, 16.0f, 16.0f);

        renderer.endFrame();
        timer.sync();
    }

    // ... cleanup ...
}
```

---

## Files to Create

```
src/engine/Input.hpp
src/engine/Input.cpp
```

## Files to Modify

```
CMakeLists.txt (add Input.cpp)
src/main.mm (integrate Input, add player control test)
```

---

## SDL Initialization Note

Make sure SDL is initialized with game controller support:

```cpp
// In main.mm, change:
SDL_Init(SDL_INIT_VIDEO)

// To:
SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER)
```

---

## Acceptance Criteria

- [ ] Input class compiles and links
- [ ] Arrow keys move a sprite around the screen
- [ ] WASD also moves the sprite (alternative mapping)
- [ ] Spacebar prints "PUNCH!" to console (just pressed, not held)
- [ ] Escape quits the game
- [ ] Gamepad d-pad works (if controller connected)
- [ ] Gamepad A button triggers attack
- [ ] Movement is frame-independent (uses delta time)
- [ ] No input lag (responsive feel)

---

## Test It

1. Run the game
2. Press arrow keys → sprite moves
3. Hold arrow key → sprite keeps moving smoothly
4. Release → sprite stops immediately
5. Tap spacebar → see ONE "PUNCH!" per tap (not spam)
6. Hold spacebar → still just one "PUNCH!" (isPressed, not isDown)
7. Plug in a controller → d-pad and A button work

---

## What NOT To Do

- Don't handle mouse input (we don't need it)
- Don't create an "input configuration" system (hardcode the mappings)
- Don't abstract SDL away completely (we might need raw events later)
- Don't over-engineer this - it's an arcade game, not a AAA title

---

## Why This Matters

After this task, we have PLAYER AGENCY. The player can DO something.

That's the difference between a demo and a game.

Right now: sprites bounce, player watches.
After this: player moves, player attacks.

Next task will be entities (so enemies can exist).
Then collision (so attacks can hit).
Then: GAMEPLAY.

---

## Deadline

The sprite batch took you a few days. This should take less.

Input systems are straightforward. Don't overthink it.

Ship it.

---

*"A delayed game is eventually good, but a game with no input is never played."*
*— Definitely Not Shigeru Miyamoto*
