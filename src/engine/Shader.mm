#import "Shader.hpp"
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <fstream>
#include <sstream>
#include <iostream>

Shader::Shader() : library(nil), pipelineState(nil) {
}

Shader::~Shader() {
    shutdown();
}

bool Shader::load(id<MTLDevice> device, const std::string& filename) {
    if (!device) {
        std::cerr << "Device is nil!" << std::endl;
        return false;
    }
    
    // Read shader source from file
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Failed to open shader file: " << filename << std::endl;
        return false;
    }
    
    std::stringstream buffer;
    buffer << file.rdbuf();
    std::string source = buffer.str();
    file.close();
    
    NSString* sourceString = [NSString stringWithUTF8String:source.c_str()];
    
    // Create compile options
    MTLCompileOptions* options = [[MTLCompileOptions alloc] init];
    options.languageVersion = MTLLanguageVersion2_4;
    
    // Compile shader
    NSError* error = nil;
    library = [device newLibraryWithSource:sourceString options:options error:&error];
    
    if (!library) {
        if (error) {
            NSLog(@"Failed to compile shader: %@", error.localizedDescription);
            NSLog(@"Error details: %@", error);
        } else {
            NSLog(@"Failed to compile shader: library is nil but no error reported");
        }
        return false;
    }
    
    // Get vertex and fragment functions
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"sprite_vertex"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"sprite_fragment"];
    
    if (!vertexFunction || !fragmentFunction) {
        std::cerr << "Failed to find shader functions" << std::endl;
        return false;
    }
    
    // Create pipeline descriptor
    MTLRenderPipelineDescriptor* pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.fragmentFunction = fragmentFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    
    // Enable alpha blending
    pipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    // Set vertex descriptor
    MTLVertexDescriptor* vertexDescriptor = [[MTLVertexDescriptor alloc] init];
    // Position (attribute 0)
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    // TexCoord (attribute 1)
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[1].offset = 2 * sizeof(float);
    vertexDescriptor.attributes[1].bufferIndex = 0;
    // Layout
    vertexDescriptor.layouts[0].stride = 4 * sizeof(float);
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    // Create pipeline state
    pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    
    if (!pipelineState) {
        NSLog(@"Failed to create pipeline state: %@", error);
        return false;
    }
    
    return true;
}

id<MTLRenderPipelineState> Shader::getPipelineState() {
    return pipelineState;
}

void Shader::shutdown() {
    library = nil;
    pipelineState = nil;
}
