/**
 * TextRenderer Implementation
 */

#include "TextRenderer.hpp"
#include "Texture.hpp"
#include "SpriteBatch.hpp"
#include <iostream>

TextRenderer::TextRenderer() {}

TextRenderer::~TextRenderer() {
    shutdown();
}

bool TextRenderer::loadFont(void* device, const std::string& filename) {
    Texture* fontTexture = new Texture();

    // Cast void* back to id<MTLDevice>
    id<MTLDevice> mtlDevice = (__bridge id<MTLDevice>)device;

    if (!fontTexture->load(mtlDevice, filename)) {
        std::cerr << "Failed to load font texture: " << filename << std::endl;
        delete fontTexture;
        return false;
    }

    m_texture = (__bridge void*)fontTexture->getTexture();
    m_fontTextureOwner = fontTexture;  // Keep Texture alive to prevent ARC release

    std::cout << "Font loaded: " << filename << std::endl;
    return true;
}

void TextRenderer::getCharUV(char c, float& u, float& v, float& w, float& h) {
    int index = -1;

    if (c >= 'A' && c <= 'Z') {
        index = c - 'A';  // A=0, B=1, ... Z=25
    } else if (c >= 'a' && c <= 'z') {
        index = c - 'a';  // Lowercase maps to uppercase
    } else if (c >= '0' && c <= '9') {
        index = 26 + (c - '0');  // 0=26, 1=27, ... 9=35
    } else {
        // Punctuation
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

    // Calculate UVs (normalized 0-1 coordinates)
    w = (float)m_charWidth / (float)m_textureWidth;
    h = (float)m_charHeight / (float)m_textureHeight;
    u = col * w;
    v = row * h;
}

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

void TextRenderer::drawTextScaled(SpriteBatch& batch, float x, float y,
                                  const std::string& text, float scale,
                                  float r, float g, float b, float a) {
    if (!m_texture) {
        std::cerr << "TextRenderer::drawTextScaled - no texture!" << std::endl;
        return;
    }

    static bool debugOnce = true;
    if (debugOnce) {
        std::cout << "TextRenderer: texture=" << m_texture << " text='" << text << "'" << std::endl;
        debugOnce = false;
    }

    float cursorX = x;
    float scaledWidth = m_charWidth * scale;
    float scaledHeight = m_charHeight * scale;

    for (char c : text) {
        if (c == ' ') {
            cursorX += scaledWidth;
            continue;
        }

        float u, v, w, h;
        getCharUV(c, u, v, w, h);

        if (w > 0) {
            batch.draw(m_texture, cursorX, y,
                      scaledWidth, scaledHeight,
                      u, v, w, h,
                      r, g, b, a);
        }

        cursorX += scaledWidth;
    }
}

void TextRenderer::shutdown() {
    if (m_fontTextureOwner) {
        delete static_cast<Texture*>(m_fontTextureOwner);
        m_fontTextureOwner = nullptr;
    }
    m_texture = nullptr;
}
