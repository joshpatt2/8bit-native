/**
 * Ball - Pong ball with physics
 */

#pragma once

#include "../engine/Entity.hpp"

class Paddle;

class Ball : public Entity {
public:
    Ball();
    virtual ~Ball();

    void update(float dt) override;
    void render(SpriteBatch& batch) override;

    void reset();
    void setPaddles(Paddle* left, Paddle* right);

    // Velocity exposed for AI paddle tracking
    float vx = 0.0f;
    float vy = 0.0f;

private:
    float baseSpeed = 150.0f;
    Paddle* leftPaddle = nullptr;
    Paddle* rightPaddle = nullptr;

    void checkPaddleCollision(Paddle* paddle);
};
