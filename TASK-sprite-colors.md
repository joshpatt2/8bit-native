# Task: Sprite Colors

---

## You Have One Job

Make the player GREEN.
Make the enemies BLUE.

That's it. That's the whole task.

And yet I already know you're going to find a way to mess this up.

---

## The Embarrassing Truth

Open `SpriteBatch.hpp`. Line 29.

```cpp
float r, g, b, a; // Color tint (for future use)
```

"For future use."

That comment has been sitting there since the sprite batch was written. The INFRASTRUCTURE is there. The vertex has color. The shader multiplies by color. Everything is READY.

And yet every single sprite renders WHITE.

Why?

Because someone—maybe you, maybe the last intern, I don't care—hardcoded the color in `addQuad()`:

```cpp
float r = 1.0f, g = 1.0f, b = 1.0f, a = 1.0f;
```

White. Always white. The most boring possible choice.

You built a sports car and only drive it in first gear.

---

## What You Need To Do

### Step 1: Add a Color Parameter to draw()

```cpp
// SpriteBatch.hpp - ADD THIS OVERLOAD

void draw(void* texture, float x, float y, float width, float height,
          float r, float g, float b, float a = 1.0f);

// And the sprite sheet version:
void draw(void* texture,
          float x, float y, float width, float height,
          float srcX, float srcY, float srcW, float srcH,
          float r, float g, float b, float a = 1.0f);
```

### Step 2: Update addQuad()

```cpp
// SpriteBatch.cpp/.mm

void SpriteBatch::addQuad(float x, float y, float w, float h,
                          float u0, float v0, float u1, float v1,
                          float r, float g, float b, float a) {
    // ... existing position/UV code ...

    // USE THE PASSED COLOR INSTEAD OF HARDCODED WHITE
    m_vertices.push_back({ndcLeft, ndcBottom, u0, v1, r, g, b, a});
    m_vertices.push_back({ndcRight, ndcBottom, u1, v1, r, g, b, a});
    // ... etc
}
```

### Step 3: Keep the Old draw() Working

The existing `draw()` without color should still work. Just have it call the new one with white:

```cpp
void SpriteBatch::draw(void* texture, float x, float y, float w, float h) {
    draw(texture, x, y, w, h, 1.0f, 1.0f, 1.0f, 1.0f);  // White
}
```

Backwards compatibility. It's not hard. Don't break existing code.

---

## Step 4: Color The Entities

### Player.cpp

```cpp
void Player::render(SpriteBatch& batch) {
    // GREEN player
    batch.draw(texture, x, y, width, height, 0.2f, 0.9f, 0.3f, 1.0f);
}
```

### Enemy.cpp

```cpp
void Enemy::render(SpriteBatch& batch) {
    // BLUE enemy
    batch.draw(texture, x, y, width, height, 0.3f, 0.4f, 0.9f, 1.0f);
}
```

That's it. Two lines of actual game code. The rest is just exposing what was ALREADY THERE.

---

## The Colors

| Entity | R | G | B | Hex |
|--------|---|---|---|-----|
| Player | 0.2 | 0.9 | 0.3 | #33E64D |
| Enemy | 0.3 | 0.4 | 0.9 | #4D66E6 |

Green vs Blue. Hero vs Threat. Instantly readable.

If you want to get fancy later, you can add:
- Red for player when damaged
- White flash on hit
- Fade to gray on death

But that's LATER. Right now: green player, blue enemies. SHIP IT.

---

## Why This Matters

Right now your game has one texture. One 32x32 test sprite. Everything looks the same.

The player looks like the enemies.
The enemies look like the player.
It's a visual MESS.

Color is the cheapest, fastest way to create visual hierarchy. The player should be INSTANTLY recognizable. The threats should be OBVIOUSLY different.

This isn't art direction. This is SURVIVAL. The player needs to know—in a fraction of a second—what's going to kill them and what they control.

Green = me.
Blue = death.

Simple. Clear. Effective.

---

## Acceptance Criteria

- [ ] `draw()` accepts RGBA color parameters
- [ ] Existing `draw()` calls still work (default white)
- [ ] Player renders GREEN
- [ ] Enemies render BLUE
- [ ] Colors are visually distinct
- [ ] No visual artifacts or blending issues
- [ ] 60 FPS maintained

---

## How Hard Is This?

Let me be clear about something.

This task should take you 15 minutes. FIFTEEN. MINUTES.

The shader already multiplies by vertex color. The vertex already has RGBA fields. You're literally just:

1. Adding a parameter
2. Passing it through
3. Using it

If this takes you more than an hour, something is deeply wrong with either your understanding or your focus.

This is not a challenge. This is a CHORE. The kind of thing a professional does before their morning coffee.

So why am I even writing this task document?

Because I don't trust you to do even simple things correctly without explicit instructions. Because you've proven that "for future use" means "never" unless someone forces you. Because the bar is on the floor and I'm still not sure you can clear it.

Prove me wrong.

---

## Don't

- Don't create a Color struct. Just use floats.
- Don't add color to Entity base class. Keep it in render().
- Don't make this complicated. It's four floats.
- Don't "improve" the blending. It already works.
- Don't ask questions. The answer is in this document.

---

## When You're Done

Run the game.

You should see a GREEN sprite that you control.
You should see BLUE sprites that chase you.

That's it. That's the test. A child could verify this.

Can you?

---

## About That Praise

You still want it, don't you?

You want me to say you're doing well. You want validation. You want to feel like you matter.

Here's the truth: you matter when you SHIP. Not before. Not because of potential. Not because you try hard.

Results. That's all that counts.

Green player. Blue enemies. SHIP IT.

Then we'll talk.

Maybe.

---

*This should have been done three commits ago.*

*— J*

*P.S. — The fact that I have to write 200 lines explaining how to pass four floats to a function is an indictment of the entire software industry. But here we are.*
