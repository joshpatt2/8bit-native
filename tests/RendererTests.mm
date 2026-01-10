#import <Metal/Metal.h>
#include "TestFramework.hpp"
#include "../src/engine/Renderer.hpp"

TEST(Construction) {
    Renderer renderer;
    // Just verify construction doesn't crash
}

TEST(ShutdownUninitialized) {
    Renderer renderer;
    ASSERT_NO_THROW(renderer.shutdown(), "Shutdown on uninitialized renderer should not crash");
}

TEST(MultipleShutdowns) {
    Renderer renderer;
    
    ASSERT_NO_THROW(renderer.shutdown(), "First shutdown should not crash");
    ASSERT_NO_THROW(renderer.shutdown(), "Second shutdown should not crash");
}

TEST(SetClearColorUninitialized) {
    Renderer renderer;
    ASSERT_NO_THROW(renderer.setClearColor(0.5f, 0.5f, 0.5f, 1.0f), 
                    "setClearColor should not crash on uninitialized renderer");
}

TEST(GetDeviceUninitialized) {
    Renderer renderer;
    void* device = renderer.getDevice();
    // Device might be nil or valid depending on implementation
    // Just ensure it doesn't crash
    (void)device;
}

TEST(DrawSpriteUninitialized) {
    Renderer renderer;
    
    ASSERT_NO_THROW({
        renderer.drawSprite(nullptr, nullptr, 0, 0, 32, 32);
    }, "drawSprite should handle uninitialized state gracefully");
}

TEST(FrameMethodsUninitialized) {
    Renderer renderer;
    
    ASSERT_NO_THROW(renderer.beginFrame(), "beginFrame should not crash uninitialized");
    ASSERT_NO_THROW(renderer.endFrame(), "endFrame should not crash uninitialized");
}

int main() {
    return TestRunner::instance().runAll();
}
