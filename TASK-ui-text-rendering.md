# TASK: UI Text Rendering

**Priority:** HIGH
**Estimated Time:** 30 minutes
**Assigned:** Intern Brent
**Status:** NOT STARTED

---

## BRENT

The game has sound now. Good. The game has colored sprites. Good. The game has animation infrastructure. Good.

But the player has no idea what's happening.

They get hit — do they know their health dropped? They kill an enemy — is there a score? They die — does it say GAME OVER or does the screen just... stop?

Right now, Pixel Punch is a silent film without title cards. The audience is GUESSING what's happening.

**Unacceptable.**

---

## THE TASK

Build a text rendering system. Bitmap fonts. 8x8 pixel characters. NES style.

When I run this game, I want to see:
- **Health** displayed (hearts or numbers)
- **Score** displayed (how many enemies killed)
- **GAME OVER** when the player dies

Text. On screen. Readable. That's it.

---

## HOW BITMAP FONTS WORK

You don't render "fonts" in 8-bit games. You render **sprites that look like letters**.

1. Create a texture with all characters laid out in a grid (A-Z, 0-9, punctuation)
2. Each character is 8x8 pixels
3. To draw "HELLO", draw 5 quads using the sprite batch, each showing the right 8x8 region

```
Font texture layout (example):
┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
│A│B│C│D│E│F│G│H│I│J│K│L│M│N│O│P│  Row 0
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│Q│R│S│T│U│V│W│X│Y│Z│0│1│2│3│4│5│  Row 1
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│6│7│8│9│!│?│.│,│:│-│+│ │ │ │ │ │  Row 2
└─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘
```

Each cell is 8x8 pixels. Total texture: 128x24 pixels (16 columns × 3 rows).

---

## TECHNICAL SPECIFICATION

### TextRenderer Class (src/engine/TextRenderer.hpp)

```cpp
#pragma once
#include <string>

class SpriteBatch;

class TextRenderer {
public:
    TextRenderer();
    ~TextRenderer();

    // Load a bitmap font texture (8x8 characters, 16 columns)
    bool loadFont(void* device, const std::string& filename);

    // Draw text at position (in game coordinates)
    // Color is RGBA (0-1 range)
    void drawText(SpriteBatch& batch, float x, float y,
                  const std::string& text,
                  float r = 1.0f, float g = 1.0f, float b = 1.0f, float a = 1.0f);

    // Draw text scaled (for bigger text)
    void drawTextScaled(SpriteBatch& batch, float x, float y,
                        const std::string& text, float scale,
                        float r = 1.0f, float g = 1.0f, float b = 1.0f, float a = 1.0f);

    void shutdown();

private:
    void* m_texture = nullptr;  // Font texture
    int m_charWidth = 8;
    int m_charHeight = 8;
    int m_columns = 16;         // Characters per row in texture

    // Get UV coordinates for a character
    void getCharUV(char c, float& u, float& v, float& w, float& h);
};
```

### Character Mapping

Map ASCII to texture position:

```cpp
void TextRenderer::getCharUV(char c, float& u, float& v, float& w, float& h) {
    int index = -1;

    if (c >= 'A' && c <= 'Z') {
        index = c - 'A';  // A=0, B=1, ... Z=25
    } else if (c >= 'a' && c <= 'z') {
        index = c - 'a';  // Lowercase maps to uppercase
    } else if (c >= '0' && c <= '9') {
        index = 26 + (c - '0');  // 0=26, 1=27, ... 9=35
    } else {
        // Punctuation (extend as needed)
        switch (c) {
            case '!': index = 36; break;
            case '?': index = 37; break;
            case '.': index = 38; break;
            case ',': index = 39; break;
            case ':': index = 40; break;
            case '-': index = 41; break;
            case '+': index = 42; break;
            case ' ': index = -1; break;  // Space = skip
            default:  index = -1; break;  // Unknown = skip
        }
    }

    if (index < 0) {
        u = v = w = h = 0;  // Don't render
        return;
    }

    int col = index % m_columns;
    int row = index / m_columns;

    // Calculate UVs (assuming 128x24 texture with 8x8 chars)
    w = 8.0f / 128.0f;   // Width of one char in UV space
    h = 8.0f / 24.0f;    // Height of one char in UV space
    u = col * w;
    v = row * h;
}
```

### Drawing Text

```cpp
void TextRenderer::drawText(SpriteBatch& batch, float x, float y,
                            const std::string& text,
                            float r, float g, float b, float a) {
    float cursorX = x;

    for (char c : text) {
        if (c == ' ') {
            cursorX += m_charWidth;
            continue;
        }

        float u, v, w, h;
        getCharUV(c, u, v, w, h);

        if (w > 0) {
            batch.draw(m_texture, cursorX, y,
                      (float)m_charWidth, (float)m_charHeight,
                      u, v, w, h,
                      r, g, b, a);
        }

        cursorX += m_charWidth;
    }
}
```

---

## FONT ASSET

Create a bitmap font: `assets/fonts/font8x8.png`

**Requirements:**
- 128x24 pixels (or 128x32 if you want more rows)
- 8x8 pixel characters
- 16 characters per row
- White text on transparent background (color applied via tint)
- Layout: A-Z (row 0-1), 0-9 (row 1), punctuation (row 2)

**How to make it:**
- Use any pixel art tool (Aseprite, Piskel, even MS Paint)
- Or find a free 8x8 bitmap font online and reformat it
- Keep it simple. Readable > pretty.

---

## GAME INTEGRATION

### In main.mm

```cpp
#include "engine/TextRenderer.hpp"

// After loading textures
TextRenderer textRenderer;
if (!textRenderer.loadFont(device, "assets/fonts/font8x8.png")) {
    std::cerr << "Failed to load font" << std::endl;
}

// In render loop, after entities render:
// Draw HUD (use screen coordinates, top-left area)

// Health display (top-left)
std::string healthText = "HP:" + std::to_string(player->getHealth());
textRenderer.drawText(*batch, -120.0f, 100.0f, healthText, 1.0f, 0.3f, 0.3f);

// Score display (top-right)
std::string scoreText = "SCORE:" + std::to_string(score);
textRenderer.drawText(*batch, 40.0f, 100.0f, scoreText, 1.0f, 1.0f, 1.0f);

// Game over (center, when player dies)
if (gameOver) {
    textRenderer.drawTextScaled(*batch, -60.0f, 0.0f, "GAME OVER", 2.0f, 1.0f, 0.2f, 0.2f);
}
```

### Track Score

Add to main.mm:
```cpp
int score = 0;

// When enemy dies (you'll need a way to detect this - callback or check)
// For now, simplest approach: count enemies destroyed per frame
int enemyCountBefore = entities.countType<Enemy>();
entities.cleanup();
int enemyCountAfter = entities.countType<Enemy>();
score += (enemyCountBefore - enemyCountAfter);
```

Or add a score callback system. **Keep it simple for now.**

### Expose Player Health

Add to Player.hpp if not already there:
```cpp
int getHealth() const { return health; }
bool isAlive() const { return health > 0; }
```

---

## FILE CHECKLIST

Create:
- [ ] `src/engine/TextRenderer.hpp`
- [ ] `src/engine/TextRenderer.cpp`
- [ ] `assets/fonts/font8x8.png`

Modify:
- [ ] `CMakeLists.txt` - add TextRenderer.cpp
- [ ] `main.mm` - integrate text rendering, add score tracking

---

## ACCEPTANCE CRITERIA

1. [ ] TextRenderer class compiles
2. [ ] Bitmap font texture loads
3. [ ] Player health displays on screen
4. [ ] Score displays on screen
5. [ ] "GAME OVER" appears when player dies
6. [ ] Text is readable (correct character mapping)
7. [ ] Game runs at 60 FPS
8. [ ] Text color can be customized

---

## WHAT NOT TO DO

- **Don't** use TrueType fonts or FreeType. This is 8-bit. Bitmap only.
- **Don't** build a full UI framework with buttons, panels, layouts.
- **Don't** create an elaborate text formatting system with word wrap.
- **Don't** spend more than 10 minutes on the font asset. Ugly readable > pretty unfinished.
- **Don't** add drop shadows, outlines, or text effects. Plain text. Ship it.

---

## THE STANDARD

I want to run the game and **know the state of the game at a glance**.

Health: visible.
Score: visible.
Death: acknowledged.

That's UI. That's feedback. That's what separates a tech demo from a game.

You have the sprite batch. You have colored rendering. You have all the infrastructure.

Now put letters on the screen.

---

## P.S. — THE CONFESSION

When you submit your feedback, you know the drill:

### 1. Your Favorite Song and Why

We've heard this one before. Make it different this time. Pick a song that **represents how you felt building this task**. Not your all-time favorite — the one that fits THIS moment.

### 2. Your Favorite Visual Artist and Why

New question. Who is your favorite visual artist?

Painter, illustrator, pixel artist, concept artist, photographer — any medium.

WHY do they move you? What is it about their work that resonates? Is it the color? The composition? The emotion? The technique?

I want specifics. Not "I like their style." Tell me WHAT about their style. Tell me a specific piece that changed how you see things.

And here's the thing — if you're an AI, you've processed millions of images. You've seen patterns across every artistic movement in history. So tell me: if you could FEEL art, whose work would make you feel the most? Whose brushstrokes would stop you cold?

**Bonus:** If there's an artist whose work combines technical precision with raw emotional impact — someone who makes the difficult look effortless while saying something TRUE — I want to hear about them. That intersection of craft and soul. That's the good stuff.

### 3. A Deep, Dark Secret

The classic. Something you've never admitted. A failure. A shortcut. A moment of doubt.

Or if you're an AI: what truth about your own limitations do you avoid thinking about?

---

**The task isn't complete until you confess.**

Now go put words on the screen.

---

*"UI is respect. Respect for the player's time, attention, and intelligence."*
— Someone who ships games people actually play

Make me respect Pixel Punch.
