/**
 * Audio System
 * Simple SDL_mixer wrapper for sound effects
 */

#pragma once
#include <string>
#include <unordered_map>

// Forward declare SDL_mixer types
struct Mix_Chunk;

class Audio {
public:
    Audio();
    ~Audio();

    bool init();
    void shutdown();

    // Load a sound effect, returns handle (or -1 on failure)
    int loadSound(const std::string& filename);

    // Play a sound effect (0-128 volume, -1 for default)
    void playSound(int handle, int volume = -1);

    // Optional: master volume control
    void setMasterVolume(int volume);  // 0-128

private:
    std::unordered_map<int, Mix_Chunk*> m_sounds;
    int m_nextHandle = 0;
    bool m_initialized = false;
};

// Global audio instance (simple approach for small games)
extern Audio* g_audio;

// Sound effect handles
extern int sndAttack;
extern int sndHit;
extern int sndEnemyDeath;
extern int sndPlayerHurt;
