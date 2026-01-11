/**
 * Input Tests
 */

#include "TestFramework.hpp"
#include "engine/Input.hpp"
#include <SDL2/SDL.h>

// Helper to initialize SDL for tests
class SDLTestFixture {
public:
    SDLTestFixture() {
        if (SDL_Init(SDL_INIT_VIDEO) < 0) {
            throw std::runtime_error("SDL_Init failed");
        }
    }
    
    ~SDLTestFixture() {
        SDL_Quit();
    }
};

TEST(ConstructorInitializesCorrectly) {
    SDLTestFixture sdl;
    Input input;
    
    // Should not quit initially
    ASSERT_FALSE(input.shouldQuit(), "Should not quit on construction");
    
    // All keys should be unpressed initially
    ASSERT_FALSE(input.isDown(Key::Up), "Up should not be pressed initially");
    ASSERT_FALSE(input.isDown(Key::Down), "Down should not be pressed initially");
    ASSERT_FALSE(input.isDown(Key::Left), "Left should not be pressed initially");
    ASSERT_FALSE(input.isDown(Key::Right), "Right should not be pressed initially");
    ASSERT_FALSE(input.isDown(Key::Attack), "Attack should not be pressed initially");
}

TEST(UpdateDoesNotCrash) {
    SDLTestFixture sdl;
    Input input;
    
    // Update should not crash
    ASSERT_NO_THROW(input.update(), "Update should not throw");
    
    // Multiple updates should work
    ASSERT_NO_THROW(input.update(), "Second update should not throw");
    ASSERT_NO_THROW(input.update(), "Third update should not throw");
}

TEST(isPressedRequiresEdgeTrigger) {
    SDLTestFixture sdl;
    Input input;
    
    // Without actual keyboard events, isPressed should always be false
    // (Edge trigger requires state transition, which we can't easily simulate)
    input.update();
    
    ASSERT_FALSE(input.isPressed(Key::Up), "isPressed requires state transition");
    ASSERT_FALSE(input.isPressed(Key::Attack), "isPressed requires state transition");
}

TEST(MultipleUpdatesWork) {
    SDLTestFixture sdl;
    Input input;
    
    // Simulate multiple frames of input polling
    for (int i = 0; i < 100; i++) {
        input.update();
    }
    
    // Should still be functional
    ASSERT_FALSE(input.shouldQuit(), "Should not quit after many updates");
}

int main() {
    std::cout << "=== Input Tests ===" << std::endl;
    return TestRunner::instance().runAll();
}
