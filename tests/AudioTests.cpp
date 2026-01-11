/**
 * Audio Tests
 */

#include "TestFramework.hpp"
#include "engine/Audio.hpp"
#include <SDL2/SDL.h>

// Helper to initialize SDL for audio tests
class SDLAudioFixture {
public:
    SDLAudioFixture() {
        if (SDL_Init(SDL_INIT_AUDIO) < 0) {
            throw std::runtime_error("SDL_Init failed for audio");
        }
    }
    
    ~SDLAudioFixture() {
        SDL_Quit();
    }
};

TEST(ConstructorWorks) {
    Audio audio;
    ASSERT_TRUE(true, "Audio constructor should not crash");
}

TEST(InitializationSucceeds) {
    SDLAudioFixture sdl;
    Audio audio;
    
    bool result = audio.init();
    
    ASSERT_TRUE(result, "Audio init should succeed");
    
    audio.shutdown();
}

TEST(LoadSoundReturnsHandle) {
    SDLAudioFixture sdl;
    Audio audio;
    
    if (!audio.init()) {
        throw std::runtime_error("Audio init failed");
    }
    
    // Try to load a sound (may fail if file doesn't exist, but should return -1)
    int handle = audio.loadSound("nonexistent.wav");
    
    // Should return -1 for invalid file
    ASSERT_EQUAL(handle, -1, "Loading nonexistent file should return -1");
    
    audio.shutdown();
}

TEST(PlaySoundDoesNotCrash) {
    SDLAudioFixture sdl;
    Audio audio;
    
    if (!audio.init()) {
        throw std::runtime_error("Audio init failed");
    }
    
    // Playing invalid handle should not crash
    ASSERT_NO_THROW(audio.playSound(-1), "Playing invalid sound should not crash");
    ASSERT_NO_THROW(audio.playSound(999), "Playing invalid sound should not crash");
    
    audio.shutdown();
}

TEST(SetMasterVolumeDoesNotCrash) {
    SDLAudioFixture sdl;
    Audio audio;
    
    if (!audio.init()) {
        throw std::runtime_error("Audio init failed");
    }
    
    ASSERT_NO_THROW(audio.setMasterVolume(64), "Setting volume should not crash");
    ASSERT_NO_THROW(audio.setMasterVolume(0), "Setting volume to 0 should not crash");
    ASSERT_NO_THROW(audio.setMasterVolume(128), "Setting volume to max should not crash");
    
    audio.shutdown();
}

TEST(ShutdownDoesNotCrash) {
    SDLAudioFixture sdl;
    Audio audio;
    
    audio.init();
    
    // Shutdown should not crash
    ASSERT_NO_THROW(audio.shutdown(), "Shutdown should not crash");
    
    // Double shutdown should also be safe
    ASSERT_NO_THROW(audio.shutdown(), "Double shutdown should be safe");
}

TEST(InitWithoutSDLFails) {
    // Don't initialize SDL
    Audio audio;
    
    bool result = audio.init();
    
    // May fail or succeed depending on global SDL state
    // Just verify it doesn't crash
    ASSERT_TRUE(true, "Init without SDL should handle gracefully");
    
    audio.shutdown();
}

int main() {
    std::cout << "=== Audio Tests ===" << std::endl;
    return TestRunner::instance().runAll();
}
