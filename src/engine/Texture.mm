#define STB_IMAGE_IMPLEMENTATION
#import "Texture.hpp"
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "stb_image.h"
#include <iostream>

Texture::Texture() : texture(nil), width(0), height(0) {
}

Texture::~Texture() {
    shutdown();
}

bool Texture::load(id<MTLDevice> device, const std::string& filename) {
    // Load image using stb_image
    int channels;
    unsigned char* imageData = stbi_load(filename.c_str(), &width, &height, &channels, 4);
    
    if (!imageData) {
        std::cerr << "Failed to load texture: " << filename << std::endl;
        return false;
    }
    
    // Create texture descriptor
    MTLTextureDescriptor* textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    textureDescriptor.storageMode = MTLStorageModeShared;
    
    // Create texture
    texture = [device newTextureWithDescriptor:textureDescriptor];
    
    if (!texture) {
        std::cerr << "Failed to create Metal texture" << std::endl;
        stbi_image_free(imageData);
        return false;
    }
    
    // Upload image data to texture
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    NSUInteger bytesPerRow = 4 * width;
    [texture replaceRegion:region mipmapLevel:0 withBytes:imageData bytesPerRow:bytesPerRow];
    
    // Free image data
    stbi_image_free(imageData);
    
    std::cout << "Loaded texture: " << filename << " (" << width << "x" << height << ")" << std::endl;
    
    return true;
}

id<MTLTexture> Texture::getTexture() {
    return texture;
}

int Texture::getWidth() {
    return width;
}

int Texture::getHeight() {
    return height;
}

void Texture::shutdown() {
    texture = nil;
    width = 0;
    height = 0;
}
