/**
 * Screenshot - Capture framebuffer to PNG file
 */

#pragma once
#include <string>

class Screenshot {
public:
    // Capture the current Metal drawable to a PNG file
    // Must be called after rendering but before presenting
    static bool capture(void* drawable, const std::string& filename);
};
