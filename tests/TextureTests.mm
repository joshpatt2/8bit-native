#import <Metal/Metal.h>
#include "TestFramework.hpp"
#include "../src/engine/Texture.hpp"

static id<MTLDevice> g_device = nil;

void setUp() {
    g_device = MTLCreateSystemDefaultDevice();
    ASSERT_NOT_NIL((__bridge void*)g_device, "Failed to create Metal device");
}

TEST(LoadValid1x1PNG) {
    Texture texture;
    bool result = texture.load(g_device, "tests/assets/valid_1x1.png");
    
    ASSERT_TRUE(result, "Should load valid 1x1 PNG");
    ASSERT_EQUAL(texture.getWidth(), 1, "Width should be 1");
    ASSERT_EQUAL(texture.getHeight(), 1, "Height should be 1");
    ASSERT_NOT_NIL(texture.getTexture(), "Texture should not be nil");
    
    texture.shutdown();
}

TEST(LoadValid16x16PNG) {
    Texture texture;
    bool result = texture.load(g_device, "tests/assets/valid_16x16.png");
    
    ASSERT_TRUE(result, "Should load valid 16x16 PNG");
    ASSERT_EQUAL(texture.getWidth(), 16, "Width should be 16");
    ASSERT_EQUAL(texture.getHeight(), 16, "Height should be 16");
    ASSERT_NOT_NIL(texture.getTexture(), "Texture should not be nil");
    
    texture.shutdown();
}

TEST(LoadNonPowerOf2PNG) {
    Texture texture;
    bool result = texture.load(g_device, "tests/assets/valid_13x17.png");
    
    ASSERT_TRUE(result, "Should load non-power-of-2 PNG");
    ASSERT_EQUAL(texture.getWidth(), 13, "Width should be 13");
    ASSERT_EQUAL(texture.getHeight(), 17, "Height should be 17");
    
    texture.shutdown();
}

TEST(LoadPNGWithAlpha) {
    Texture texture;
    bool result = texture.load(g_device, "tests/assets/valid_alpha.png");
    
    ASSERT_TRUE(result, "Should load PNG with alpha channel");
    ASSERT_NOT_NIL(texture.getTexture(), "Texture should not be nil");
    
    texture.shutdown();
}

TEST(LoadNonExistentFile) {
    Texture texture;
    bool result = texture.load(g_device, "tests/assets/does_not_exist.png");
    
    ASSERT_FALSE(result, "Should fail to load non-existent file");
    ASSERT_NIL(texture.getTexture(), "Texture should be nil");
}

TEST(LoadCorruptedPNG) {
    Texture texture;
    bool result = texture.load(g_device, "tests/assets/corrupted.png");
    
    ASSERT_FALSE(result, "Should fail to load corrupted PNG");
    ASSERT_NIL(texture.getTexture(), "Texture should be nil");
}

TEST(LoadInvalidFormat) {
    Texture texture;
    bool result = texture.load(g_device, "tests/assets/invalid.txt");
    
    ASSERT_FALSE(result, "Should fail to load non-image file");
    ASSERT_NIL(texture.getTexture(), "Texture should be nil");
}

TEST(MultipleLoads) {
    Texture texture;
    
    bool result1 = texture.load(g_device, "tests/assets/valid_1x1.png");
    ASSERT_TRUE(result1, "First load should succeed");
    
    texture.shutdown();
    
    bool result2 = texture.load(g_device, "tests/assets/valid_16x16.png");
    ASSERT_TRUE(result2, "Second load should succeed");
    
    texture.shutdown();
}

TEST(Shutdown) {
    Texture texture;
    texture.load(g_device, "tests/assets/valid_1x1.png");
    
    ASSERT_NO_THROW(texture.shutdown(), "Shutdown should not throw");
    ASSERT_NIL(texture.getTexture(), "Texture should be nil after shutdown");
}

TEST(DoubleShutdown) {
    Texture texture;
    texture.load(g_device, "tests/assets/valid_1x1.png");
    
    texture.shutdown();
    ASSERT_NO_THROW(texture.shutdown(), "Double shutdown should not crash");
}

TEST(LoadWithNilDevice) {
    Texture texture;
    bool result = texture.load(nil, "tests/assets/valid_1x1.png");
    
    ASSERT_FALSE(result, "Should fail with nil device");
}

int main() {
    setUp();
    return TestRunner::instance().runAll();
}
