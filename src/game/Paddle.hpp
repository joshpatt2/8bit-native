/**
 * Paddle - Pong paddle (player or AI controlled)
 */

#pragma once

#include "../engine/Entity.hpp"

class Input;
class Ball;

class Paddle : public Entity {
public:
    Paddle(float startX, bool isPlayer);
    virtual ~Paddle();

    void update(float dt) override;
    void render(SpriteBatch& batch) override;

    void setInput(Input* input) { this->input = input; }
    void setAITarget(Ball* ball) { this->aiTarget = ball; }

private:
    bool isPlayer;
    float speed = 120.0f;
    Input* input = nullptr;
    Ball* aiTarget = nullptr;
};
