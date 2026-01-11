/**
 * TextRenderer - Bitmap font text rendering
 * 
 * Renders text using an 8x8 bitmap font texture.
 * Characters are sprites laid out in a grid.
 */

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
    int m_textureWidth = 128;   // Total texture width
    int m_textureHeight = 24;   // Total texture height

    // Get UV coordinates for a character
    void getCharUV(char c, float& u, float& v, float& w, float& h);
};
