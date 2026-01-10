/**
 * Input implementation
 */

#include "Input.hpp"
#include <cstring>

Input::Input() {
    keyboardState = SDL_GetKeyboardState(nullptr);
    memset(prevKeyboardState, 0, sizeof(prevKeyboardState));
}

Input::~Input() {
}

void Input::update() {
    // Store previous frame state
    memcpy(prevKeyboardState, keyboardState, sizeof(prevKeyboardState));

    // Poll SDL events
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            quit = true;
        }
        if (event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_ESCAPE) {
            quit = true;
        }
    }

    // Refresh keyboard state
    keyboardState = SDL_GetKeyboardState(nullptr);
}

bool Input::isDown(Key key) const {
    SDL_Scancode scancode = getScancode(key);
    return keyboardState[scancode];
}

bool Input::isPressed(Key key) const {
    SDL_Scancode scancode = getScancode(key);
    return keyboardState[scancode] && !prevKeyboardState[scancode];
}

SDL_Scancode Input::getScancode(Key key) const {
    switch (key) {
        case Key::Up:     return SDL_SCANCODE_UP;
        case Key::Down:   return SDL_SCANCODE_DOWN;
        case Key::Left:   return SDL_SCANCODE_LEFT;
        case Key::Right:  return SDL_SCANCODE_RIGHT;
        case Key::Attack: return SDL_SCANCODE_SPACE;
        case Key::Back:   return SDL_SCANCODE_ESCAPE;
        default:          return SDL_SCANCODE_UNKNOWN;
    }
}
