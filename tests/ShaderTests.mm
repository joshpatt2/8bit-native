#import <Metal/Metal.h>
#include "TestFramework.hpp"
#include "../src/engine/Shader.hpp"

static id<MTLDevice> g_device = nil;

void setUp() {
    g_device = MTLCreateSystemDefaultDevice();
    ASSERT_NOT_NIL((__bridge void*)g_device, "Failed to create Metal device");
}

TEST(LoadValidSpriteShader) {
    Shader shader;
    bool result = shader.load(g_device, "shaders/sprite.metal");
    
    ASSERT_TRUE(result, "Should load valid sprite shader");
    ASSERT_NOT_NIL(shader.getPipelineState(), "Pipeline state should not be nil");
    
    shader.shutdown();
}

TEST(LoadValidMinimalShader) {
    Shader shader;
    bool result = shader.load(g_device, "tests/assets/valid_shader.metal");
    
    ASSERT_TRUE(result, "Should load valid minimal shader");
    ASSERT_NOT_NIL(shader.getPipelineState(), "Pipeline state should not be nil");
    
    shader.shutdown();
}

TEST(LoadNonExistentShader) {
    Shader shader;
    bool result = shader.load(g_device, "tests/assets/does_not_exist.metal");
    
    ASSERT_FALSE(result, "Should fail to load non-existent shader");
    ASSERT_NIL(shader.getPipelineState(), "Pipeline state should be nil");
}

TEST(LoadInvalidSyntaxShader) {
    Shader shader;
    bool result = shader.load(g_device, "tests/assets/invalid_syntax.metal");
    
    ASSERT_FALSE(result, "Should fail to compile shader with syntax error");
    ASSERT_NIL(shader.getPipelineState(), "Pipeline state should be nil");
}

TEST(LoadShaderMissingFunction) {
    Shader shader;
    bool result = shader.load(g_device, "tests/assets/missing_function.metal");
    
    ASSERT_FALSE(result, "Should fail when vertex/fragment function not found");
    ASSERT_NIL(shader.getPipelineState(), "Pipeline state should be nil");
}

TEST(LoadEmptyShader) {
    Shader shader;
    bool result = shader.load(g_device, "tests/assets/empty_shader.metal");
    
    ASSERT_FALSE(result, "Should fail to load empty shader");
    ASSERT_NIL(shader.getPipelineState(), "Pipeline state should be nil");
}

TEST(Shutdown) {
    Shader shader;
    shader.load(g_device, "shaders/sprite.metal");
    
    ASSERT_NO_THROW(shader.shutdown(), "Shutdown should not throw");
    ASSERT_NIL(shader.getPipelineState(), "Pipeline state should be nil after shutdown");
}

TEST(DoubleShutdown) {
    Shader shader;
    shader.load(g_device, "shaders/sprite.metal");
    
    shader.shutdown();
    ASSERT_NO_THROW(shader.shutdown(), "Double shutdown should not crash");
}

TEST(LoadWithNilDevice) {
    Shader shader;
    bool result = shader.load(nil, "shaders/sprite.metal");
    
    ASSERT_FALSE(result, "Should fail with nil device");
}

TEST(MultipleLoads) {
    Shader shader;
    
    bool result1 = shader.load(g_device, "shaders/sprite.metal");
    ASSERT_TRUE(result1, "First load should succeed");
    
    shader.shutdown();
    
    bool result2 = shader.load(g_device, "tests/assets/valid_shader.metal");
    ASSERT_TRUE(result2, "Second load should succeed");
    
    shader.shutdown();
}

int main() {
    setUp();
    return TestRunner::instance().runAll();
}
