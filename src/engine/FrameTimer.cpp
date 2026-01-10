/**
 * FrameTimer implementation
 */

#include "FrameTimer.hpp"
#include <SDL2/SDL.h>
#include <algorithm>
#include <cstring>

FrameTimer::FrameTimer(int targetFPS)
    : m_lastTime(0)
    , m_frequency(SDL_GetPerformanceFrequency())
    , m_deltaTime(0.0f)
    , m_targetFrameTime(1.0f / static_cast<float>(targetFPS))
    , m_fpsIndex(0)
    , m_frameCount(0)
{
    // Initialize FPS buffer to target FPS
    for (int i = 0; i < 60; ++i) {
        m_fpsBuffer[i] = static_cast<float>(targetFPS);
    }
    
    // Initialize timer
    m_lastTime = SDL_GetPerformanceCounter();
}

void FrameTimer::tick() {
    uint64_t currentTime = SDL_GetPerformanceCounter();
    
    // First frame: no previous time to compare
    if (m_frameCount == 0) {
        m_deltaTime = 0.0f;
    } else {
        // Calculate time since last frame
        uint64_t elapsed = currentTime - m_lastTime;
        m_deltaTime = static_cast<float>(elapsed) / static_cast<float>(m_frequency);
        
        // Clamp delta time to prevent huge jumps (max 100ms = 10 FPS minimum)
        m_deltaTime = std::min(m_deltaTime, 0.1f);
    }
    
    m_lastTime = currentTime;
    m_frameCount++;
    
    // Update FPS buffer (rolling average)
    if (m_deltaTime > 0.0f) {
        float currentFPS = 1.0f / m_deltaTime;
        m_fpsBuffer[m_fpsIndex] = currentFPS;
        m_fpsIndex = (m_fpsIndex + 1) % 60;
    }
}

float FrameTimer::getDeltaTime() const {
    return m_deltaTime;
}

float FrameTimer::getFPS() const {
    // Average last 60 samples for smooth FPS display
    float sum = 0.0f;
    for (int i = 0; i < 60; ++i) {
        sum += m_fpsBuffer[i];
    }
    return sum / 60.0f;
}

void FrameTimer::sync() {
    // Calculate how much time we have left in this frame
    uint64_t currentTime = SDL_GetPerformanceCounter();
    uint64_t elapsed = currentTime - m_lastTime;
    float elapsedSeconds = static_cast<float>(elapsed) / static_cast<float>(m_frequency);
    
    float remainingTime = m_targetFrameTime - elapsedSeconds;
    
    // If we have time left, sleep to reduce CPU usage
    if (remainingTime > 0.0f) {
        // SDL_Delay takes milliseconds
        uint32_t delayMs = static_cast<uint32_t>(remainingTime * 1000.0f);
        if (delayMs > 0) {
            SDL_Delay(delayMs);
        }
    }
}
