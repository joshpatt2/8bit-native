/**
 * Animation System
 *
 * Frame-based sprite animation with support for:
 * - Multiple named animations per entity
 * - Variable frame durations
 * - Looping and one-shot animations
 * - Source rectangle output for sprite sheets
 */

#pragma once

#include <vector>
#include <string>
#include <unordered_map>

// A single frame of animation
struct AnimationFrame {
    float srcX, srcY;     // Position in sprite sheet (0-1 UV space)
    float srcW, srcH;     // Size of frame (0-1 UV space)
    float duration;       // How long this frame displays (seconds)
};

// A named animation sequence
struct Animation {
    std::string name;
    std::vector<AnimationFrame> frames;
    bool loop = true;
};

// Manages animation state and playback
class Animator {
public:
    Animator();
    ~Animator();

    // Define an animation
    void addAnimation(const std::string& name, const Animation& anim);

    // Control playback
    void play(const std::string& name);
    void stop();

    // Update animation state (call every frame)
    void update(float dt);

    // Get current frame's source rectangle (for SpriteBatch::draw)
    void getCurrentFrame(float& srcX, float& srcY, float& srcW, float& srcH) const;

    // State queries
    bool isPlaying() const { return m_playing; }
    bool isFinished() const { return m_finished; }
    const std::string& getCurrentAnimation() const { return m_currentAnim; }

private:
    std::unordered_map<std::string, Animation> m_animations;
    std::string m_currentAnim;
    int m_currentFrame = 0;
    float m_frameTimer = 0.0f;
    bool m_playing = false;
    bool m_finished = false;
};
