/**
 * Audio System Implementation
 */

#include "Audio.hpp"
#include <SDL2/SDL.h>
#include <SDL2/SDL_mixer.h>
#include <iostream>

// Global audio pointer
Audio* g_audio = nullptr;

// Sound handles
int sndAttack = -1;
int sndHit = -1;
int sndEnemyDeath = -1;
int sndPlayerHurt = -1;

Audio::Audio() {}

Audio::~Audio() {
    shutdown();
}

bool Audio::init() {
    // Initialize SDL audio subsystem if not already done
    if (!(SDL_WasInit(SDL_INIT_AUDIO) & SDL_INIT_AUDIO)) {
        if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0) {
            std::cerr << "SDL audio init failed: " << SDL_GetError() << std::endl;
            return false;
        }
    }

    // Initialize SDL_mixer
    // 44100 Hz, default format, 2 channels (stereo), 2048 sample buffer
    if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) < 0) {
        std::cerr << "SDL_mixer init failed: " << Mix_GetError() << std::endl;
        return false;
    }

    // Allocate mixing channels (8 is plenty for retro game)
    Mix_AllocateChannels(8);

    m_initialized = true;
    std::cout << "Audio system initialized!" << std::endl;
    return true;
}

int Audio::loadSound(const std::string& filename) {
    if (!m_initialized) return -1;

    Mix_Chunk* chunk = Mix_LoadWAV(filename.c_str());
    if (!chunk) {
        std::cerr << "Failed to load sound: " << filename << " - " << Mix_GetError() << std::endl;
        return -1;
    }

    int handle = m_nextHandle++;
    m_sounds[handle] = chunk;

    std::cout << "Loaded sound: " << filename << " (handle " << handle << ")" << std::endl;
    return handle;
}

void Audio::playSound(int handle, int volume) {
    if (!m_initialized) return;

    auto it = m_sounds.find(handle);
    if (it == m_sounds.end()) return;

    // Find free channel and play (-1 means first available)
    int channel = Mix_PlayChannel(-1, it->second, 0);

    // Set volume if specified (0-128)
    if (channel >= 0 && volume >= 0) {
        Mix_Volume(channel, volume);
    }
}

void Audio::setMasterVolume(int volume) {
    if (!m_initialized) return;
    Mix_Volume(-1, volume);  // -1 sets volume for all channels
}

void Audio::shutdown() {
    if (!m_initialized) return;

    // Free all loaded sounds
    for (auto& pair : m_sounds) {
        Mix_FreeChunk(pair.second);
    }
    m_sounds.clear();

    Mix_CloseAudio();
    m_initialized = false;
    std::cout << "Audio system shutdown." << std::endl;
}
