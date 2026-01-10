#pragma once
#import <Metal/Metal.h>
#include <string>

class Texture {
public:
    Texture();
    ~Texture();
    
    bool load(id<MTLDevice> device, const std::string& filename);
    id<MTLTexture> getTexture();
    int getWidth();
    int getHeight();
    void shutdown();
    
private:
    id<MTLTexture> texture;
    int width;
    int height;
};
