#pragma once
#import <Metal/Metal.h>
#include <string>

class Shader {
public:
    Shader();
    ~Shader();
    
    bool load(id<MTLDevice> device, const std::string& filename);
    id<MTLRenderPipelineState> getPipelineState();
    void shutdown();
    
private:
    id<MTLLibrary> library;
    id<MTLRenderPipelineState> pipelineState;
};
