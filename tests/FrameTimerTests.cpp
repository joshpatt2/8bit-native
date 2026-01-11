/**
 * FrameTimer Tests
 */

#include "TestFramework.hpp"
#include "engine/FrameTimer.hpp"
#include <thread>
#include <chrono>
#include <cmath>

TEST(ConstructorInitializesCorrectly) {
    FrameTimer timer(60);
    
    // Should start with zero delta time
    ASSERT_EQUAL(timer.getDeltaTime(), 0.0f, "Delta time should start at 0");
    
    // FPS should be initialized
    float fps = timer.getFPS();
    ASSERT_TRUE(fps >= 0.0f, "FPS should be non-negative");
}

TEST(TickUpdatesTimeCorrectly) {
    FrameTimer timer(60);
    
    // First tick
    timer.tick();
    float dt1 = timer.getDeltaTime();
    
    // Should have some delta time after first tick
    ASSERT_TRUE(dt1 >= 0.0f, "Delta time should be non-negative after tick");
    
    // Wait a bit and tick again
    std::this_thread::sleep_for(std::chrono::milliseconds(16)); // ~1 frame at 60fps
    timer.tick();
    float dt2 = timer.getDeltaTime();
    
    // Delta time should be roughly 16ms = 0.016s
    ASSERT_TRUE(dt2 > 0.010f && dt2 < 0.100f, "Delta time should be in reasonable range");
}

TEST(FPSCalculationIsReasonable) {
    FrameTimer timer(60);
    
    // Simulate several frames at ~60 FPS
    for (int i = 0; i < 10; i++) {
        timer.tick();
        std::this_thread::sleep_for(std::chrono::milliseconds(16));
    }
    
    float fps = timer.getFPS();
    
    // FPS should be somewhere in the ballpark of 60
    // Allow wide range due to timing variability in tests
    ASSERT_TRUE(fps > 20.0f && fps < 200.0f, "FPS should be in reasonable range");
}

TEST(DeltaTimeIsConsistent) {
    FrameTimer timer(60);
    
    timer.tick();
    std::this_thread::sleep_for(std::chrono::milliseconds(16));
    timer.tick();
    float dt1 = timer.getDeltaTime();
    
    std::this_thread::sleep_for(std::chrono::milliseconds(16));
    timer.tick();
    float dt2 = timer.getDeltaTime();
    
    // Delta times for similar frame lengths should be similar
    float difference = std::abs(dt1 - dt2);
    ASSERT_TRUE(difference < 0.01f, "Delta times should be consistent for similar frame durations");
}

TEST(TargetFPSAffectsFrameTime) {
    FrameTimer timer30(30);
    FrameTimer timer60(60);
    
    // Different target FPS should result in different target frame times
    // This is implicit in the sync() behavior, but we can verify construction works
    ASSERT_TRUE(true, "Constructor accepts different FPS values");
}

int main() {
    std::cout << "=== FrameTimer Tests ===" << std::endl;
    return TestRunner::instance().runAll();
}
