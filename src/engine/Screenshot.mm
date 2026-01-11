/**
 * Screenshot implementation - Metal framebuffer capture
 */

#include "Screenshot.hpp"
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <fstream>
#include <vector>
#include <iostream>

// Simple BMP file writer (no external dependencies)
static bool writeBMP(const std::string& filename, int width, int height, const uint8_t* pixels) {
    // BMP file header (14 bytes)
    uint8_t fileHeader[14] = {
        'B', 'M',           // Signature
        0, 0, 0, 0,         // File size (will fill in)
        0, 0, 0, 0,         // Reserved
        54, 0, 0, 0         // Pixel data offset
    };

    // BMP info header (40 bytes)
    uint8_t infoHeader[40] = {
        40, 0, 0, 0,        // Header size
        0, 0, 0, 0,         // Width (will fill in)
        0, 0, 0, 0,         // Height (will fill in)
        1, 0,               // Planes
        24, 0,              // Bits per pixel (RGB)
        0, 0, 0, 0,         // Compression (none)
        0, 0, 0, 0,         // Image size (can be 0 for uncompressed)
        0, 0, 0, 0,         // X pixels per meter
        0, 0, 0, 0,         // Y pixels per meter
        0, 0, 0, 0,         // Colors used
        0, 0, 0, 0          // Important colors
    };

    // Calculate row size (must be multiple of 4)
    int rowSize = (width * 3 + 3) & ~3;
    int imageSize = rowSize * height;
    int fileSize = 54 + imageSize;

    // Fill in sizes
    fileHeader[2] = fileSize & 0xFF;
    fileHeader[3] = (fileSize >> 8) & 0xFF;
    fileHeader[4] = (fileSize >> 16) & 0xFF;
    fileHeader[5] = (fileSize >> 24) & 0xFF;

    infoHeader[4] = width & 0xFF;
    infoHeader[5] = (width >> 8) & 0xFF;
    infoHeader[6] = (width >> 16) & 0xFF;
    infoHeader[7] = (width >> 24) & 0xFF;

    infoHeader[8] = height & 0xFF;
    infoHeader[9] = (height >> 8) & 0xFF;
    infoHeader[10] = (height >> 16) & 0xFF;
    infoHeader[11] = (height >> 24) & 0xFF;

    std::ofstream file(filename, std::ios::binary);
    if (!file) {
        std::cerr << "Failed to open file for screenshot: " << filename << std::endl;
        return false;
    }

    file.write(reinterpret_cast<char*>(fileHeader), 14);
    file.write(reinterpret_cast<char*>(infoHeader), 40);

    // Write pixel data (BMP is bottom-up, BGR order)
    std::vector<uint8_t> row(rowSize, 0);
    for (int y = height - 1; y >= 0; y--) {
        for (int x = 0; x < width; x++) {
            int srcIdx = (y * width + x) * 4;  // BGRA source
            row[x * 3 + 0] = pixels[srcIdx + 0];  // B
            row[x * 3 + 1] = pixels[srcIdx + 1];  // G
            row[x * 3 + 2] = pixels[srcIdx + 2];  // R
        }
        file.write(reinterpret_cast<char*>(row.data()), rowSize);
    }

    file.close();
    std::cout << "Screenshot saved: " << filename << std::endl;
    return true;
}

bool Screenshot::capture(void* drawablePtr, const std::string& filename) {
    if (!drawablePtr) {
        std::cerr << "Screenshot::capture - null drawable" << std::endl;
        return false;
    }

    id<CAMetalDrawable> drawable = (__bridge id<CAMetalDrawable>)drawablePtr;
    id<MTLTexture> texture = drawable.texture;

    if (!texture) {
        std::cerr << "Screenshot::capture - null texture" << std::endl;
        return false;
    }

    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
    NSUInteger bytesPerRow = width * 4;  // BGRA

    // Allocate buffer for pixel data
    std::vector<uint8_t> pixels(bytesPerRow * height);

    // Read texture contents
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [texture getBytes:pixels.data()
          bytesPerRow:bytesPerRow
           fromRegion:region
          mipmapLevel:0];

    // Write to BMP file
    return writeBMP(filename, (int)width, (int)height, pixels.data());
}
