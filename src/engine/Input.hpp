/**
 * Input - Simple input handling system
 * 
 * Wraps SDL keyboard input for game use.
 */

#pragma once

#include <SDL2/SDL.h>

enum class Key {
    Up,
    Down,
    Left,
    Right,
    Attack,  // Space or Z
    Back     // Escape
};

class Input {
public:
    Input();
    ~Input();

    // Call once per frame to poll SDL events
    void update();

    // Check if key is currently held down
    bool isDown(Key key) const;

    // Check if key was pressed this frame (edge trigger)
    bool isPressed(Key key) const;

    // Check if should quit (window close or ESC)
    bool shouldQuit() const { return quit; }

private:
    const Uint8* keyboardState;
    Uint8 prevKeyboardState[512];
    bool quit = false;

    SDL_Scancode getScancode(Key key) const;
};
