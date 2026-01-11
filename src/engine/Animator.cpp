/**
 * Animator implementation
 */

#include "Animation.hpp"

Animator::Animator() {}

Animator::~Animator() {}

void Animator::addAnimation(const std::string& name, const Animation& anim) {
    m_animations[name] = anim;
}

void Animator::play(const std::string& name) {
    // Already playing this animation? Don't restart
    if (m_currentAnim == name && m_playing && !m_finished) {
        return;
    }

    // Check if animation exists
    auto it = m_animations.find(name);
    if (it == m_animations.end()) {
        return;
    }

    // Start the animation
    m_currentAnim = name;
    m_currentFrame = 0;
    m_frameTimer = 0.0f;
    m_playing = true;
    m_finished = false;
}

void Animator::stop() {
    m_playing = false;
}

void Animator::update(float dt) {
    if (!m_playing || m_finished) return;

    auto it = m_animations.find(m_currentAnim);
    if (it == m_animations.end()) return;

    const Animation& anim = it->second;
    if (anim.frames.empty()) return;

    m_frameTimer += dt;

    // Advance frames based on duration
    while (m_frameTimer >= anim.frames[m_currentFrame].duration) {
        m_frameTimer -= anim.frames[m_currentFrame].duration;
        m_currentFrame++;

        // Check for end of animation
        if (m_currentFrame >= static_cast<int>(anim.frames.size())) {
            if (anim.loop) {
                m_currentFrame = 0;
            } else {
                m_currentFrame = static_cast<int>(anim.frames.size()) - 1;
                m_finished = true;
                m_playing = false;
                return;
            }
        }
    }
}

void Animator::getCurrentFrame(float& srcX, float& srcY, float& srcW, float& srcH) const {
    auto it = m_animations.find(m_currentAnim);
    if (it == m_animations.end() || it->second.frames.empty()) {
        // Default: full texture
        srcX = 0.0f;
        srcY = 0.0f;
        srcW = 1.0f;
        srcH = 1.0f;
        return;
    }

    const AnimationFrame& frame = it->second.frames[m_currentFrame];
    srcX = frame.srcX;
    srcY = frame.srcY;
    srcW = frame.srcW;
    srcH = frame.srcH;
}
