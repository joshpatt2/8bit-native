#include "TestFramework.hpp"
#include "engine/SpriteBatch.hpp"
#include "engine/Texture.hpp"
#import <Metal/Metal.h>

static id<MTLDevice> g_device = nil;

void setUp() {
    g_device = MTLCreateSystemDefaultDevice();
}

TEST(SpriteBatchSingleTexture) {
    SpriteBatch batch;
    batch.init((__bridge void*)g_device, nullptr);
    
    Texture tex1;
    bool loaded = tex1.load(g_device, "assets/sprites/white_square.png");
    ASSERT_TRUE(loaded, "Failed to load texture");
    
    // Draw multiple times with same texture
    batch.begin();
    batch.draw((__bridge void*)tex1.getTexture(), 0.0f, 0.0f, 8.0f, 8.0f, 1.0f, 0.0f, 0.0f, 1.0f);
    batch.draw((__bridge void*)tex1.getTexture(), 10.0f, 10.0f, 8.0f, 8.0f, 0.0f, 1.0f, 0.0f, 1.0f);
    batch.draw((__bridge void*)tex1.getTexture(), 20.0f, 20.0f, 8.0f, 8.0f, 0.0f, 0.0f, 1.0f, 1.0f);
    
    int count = batch.getSpriteCount();
    ASSERT_EQUAL(count, 3, "Expected 3 sprites queued");
    
    batch.end(nullptr);
    batch.shutdown();
}

TEST(SpriteBatchTextureSwitch) {
    SpriteBatch batch;
    batch.init((__bridge void*)g_device, nullptr);
    
    Texture tex1, tex2;
    bool loaded1 = tex1.load(g_device, "assets/sprites/white_square.png");
    bool loaded2 = tex2.load(g_device, "assets/fonts/font8x8.png");
    ASSERT_TRUE(loaded1 && loaded2, "Failed to load textures");
    
    batch.begin();
    
    // Queue texture 1
    batch.draw((__bridge void*)tex1.getTexture(), 0.0f, 0.0f, 8.0f, 8.0f, 1.0f, 0.0f, 0.0f, 1.0f);
    int count1 = batch.getSpriteCount();
    
    // Queue texture 2 (PROBLEM: batch doesn't track texture switches)
    batch.draw((__bridge void*)tex2.getTexture(), 10.0f, 10.0f, 8.0f, 8.0f, 1.0f, 1.0f, 1.0f, 1.0f);
    int count2 = batch.getSpriteCount();
    
    // Both sprites are in the batch, but GPU will only use last texture for both
    ASSERT_EQUAL(count2, 2, "Both sprites queued in single batch");
    
    batch.end(nullptr);
    batch.shutdown();
}

TEST(SpriteBatchProperFlushing) {
    SpriteBatch batch;
    batch.init((__bridge void*)g_device, nullptr);
    
    Texture tex1, tex2;
    bool loaded1 = tex1.load(g_device, "assets/sprites/white_square.png");
    bool loaded2 = tex2.load(g_device, "assets/fonts/font8x8.png");
    ASSERT_TRUE(loaded1 && loaded2, "Failed to load textures");
    
    // Texture 1 batch
    batch.begin();
    batch.draw((__bridge void*)tex1.getTexture(), 0.0f, 0.0f, 8.0f, 8.0f, 1.0f, 0.0f, 0.0f, 1.0f);
    int count1 = batch.getSpriteCount();
    ASSERT_EQUAL(count1, 1, "One sprite in tex1 batch");
    batch.end(nullptr);  // FLUSH
    
    // Texture 2 batch (separate)
    batch.begin();
    batch.draw((__bridge void*)tex2.getTexture(), 10.0f, 10.0f, 8.0f, 8.0f, 1.0f, 1.0f, 1.0f, 1.0f);
    int count2 = batch.getSpriteCount();
    ASSERT_EQUAL(count2, 1, "One sprite in tex2 batch");
    batch.end(nullptr);  // FLUSH
    
    batch.shutdown();
}



