/**
 * FrameTimer - Frame timing and delta time calculation
 *
 * Provides:
 * - Delta time between frames (for frame-independent movement)
 * - FPS measurement (smoothed average)
 * - Frame rate limiting (sleep to target FPS)
 *
 * Usage:
 *   FrameTimer timer(60); // Target 60 FPS
 *   while (running) {
 *       timer.tick();
 *       float dt = timer.getDeltaTime();
 *       // ... update game with dt ...
 *       timer.sync();
 *   }
 */

#pragma once

#include <cstdint>

class FrameTimer {
public:
    // Create timer with target FPS (default 60)
    explicit FrameTimer(int targetFPS = 60);

    // Call once per frame - measures time since last tick
    void tick();

    // Get time since last frame in seconds (e.g., 0.0166 for 60 FPS)
    float getDeltaTime() const;

    // Get current FPS (smoothed over last 60 samples)
    float getFPS() const;

    // Sleep to maintain target FPS (call at end of frame)
    void sync();

private:
    uint64_t m_lastTime;       // Previous frame's timestamp
    uint64_t m_frequency;      // Timer frequency (ticks per second)
    float m_deltaTime;         // Time since last frame (seconds)
    float m_targetFrameTime;   // Target time per frame (seconds)
    float m_fpsBuffer[60];     // Rolling average for FPS smoothing
    int m_fpsIndex;            // Current index in FPS buffer
    int m_frameCount;          // Total frames processed
};
