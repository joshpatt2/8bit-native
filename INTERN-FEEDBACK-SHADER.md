# Intern Feedback: Sprite Shader Implementation

---

## Are you one of those single-tear people?

Because I'm about to make you cry.

---

## Let's start with what you DIDN'T do.

I gave you a task. A COMPLETE task. Shader. Texture loading. Integration. Test sprite.

What did you deliver? HALF. You gave me half a task and walked away like you accomplished something.

Where's Texture.hpp? **Not here.**
Where's Texture.mm? **Not here.**
Where's the test sprite? **NOT. HERE.**
Did you update CMakeLists.txt? **NO.**
Can I run this and see a sprite? **NO I CANNOT.**

You wrote a shader that renders NOTHING because there's no texture to sample. Congratulations. You made a very pretty recipe for a meal that doesn't exist.

---

## Now let's talk about what you DID do. Poorly.

### Shader.hpp - Line 2

```cpp
#import <Metal/Metal.h>
```

Oh, you just... you just IMPORT Metal directly into a C++ header? Did you not SEE the Renderer.hpp I wrote? Did you not notice I used FORWARD DECLARATIONS and a PIMPL PATTERN to keep Objective-C OUT of the headers?

I did that FOR A REASON. So the rest of the engine stays PURE C++. And you just... you just threw that away. Because reading existing code is BENEATH you apparently.

---

### Shader.mm - Line 52

```objc
pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
```

And what pixel format did I set in Renderer.mm?

**MTLPixelFormatBGRA8Unorm_sRGB.**

Do those look the same to you? DO THEY? One has sRGB. One doesn't. Metal is going to SCREAM at you when you try to render. Or worse - it'll silently give you garbage colors and you'll spend THREE HOURS wondering why your sprite looks like it was dipped in milk.

You had ONE file to check. ONE. Renderer.mm. Sixty-eight lines. And you couldn't be bothered to see what pixel format we're using.

---

### The Blend Mode

```objc
pipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
```

Oh you enabled blending. How THOUGHTFUL. Except in the shader you wrote:

```metal
if (color.a < 0.5) {
    discard_fragment();
}
```

You're DISCARDING transparent pixels. Hard cutoff. Binary alpha. So why do you need blend mode? YOU DON'T. You're doing both because you don't understand either.

Pick ONE. Discard for hard edges. Blend for soft edges. Not both. This isn't a buffet.

---

### Error Handling

```cpp
std::cerr << "Failed to open shader file: " << filename << std::endl;
```

Oh good, you print to cerr. And then what? The function returns false. And main.cpp does... what with that false? CRASHES? CONTINUES WITH A NULL PIPELINE?

There's no recovery path. There's no graceful degradation. You just... stop. "Welp, shader didn't load. Guess I'll die."

---

### The Vertex Descriptor

```objc
vertexDescriptor.attributes[0].offset = 0;
vertexDescriptor.attributes[1].offset = 2 * sizeof(float);
```

You calculated the offset manually. `2 * sizeof(float)`. What happens when someone changes the vertex struct and forgets to update this? EVERYTHING BREAKS.

Use `offsetof()`. That's what it's FOR.

```objc
vertexDescriptor.attributes[1].offset = offsetof(Vertex, texCoord);
```

Oh wait, you don't HAVE a Vertex struct defined anywhere. You just... assumed the layout matches. ASSUMED.

---

## Your "Feedback" On My Task

You had the AUDACITY to rate my task 9/10 and then NOT COMPLETE IT?

"Minor improvements" you said. "Specify which .cpp file" you said.

Here's a minor improvement for YOU: FINISH THE WORK.

---

## What You're Going To Do Now

1. Fix the pixel format. `MTLPixelFormatBGRA8Unorm_sRGB`. Match the renderer. This is not optional.

2. Fix the header. Forward declare or use void*. Keep Objective-C out of .hpp files.

3. Write Texture.hpp and Texture.mm. Actually load a PNG. Actually create a MTLTexture. Actually make it WORK.

4. Update CMakeLists.txt with the new source files.

5. Put a sprite on the screen. An ACTUAL sprite. That I can SEE. With my EYES.

6. Don't come back until there's a sprite on that blue background.

---

## Were you rushing or were you dragging?

Because right now you're doing NEITHER. You're just... stopping. Halfway through.

Not my tempo.

---

**Grade: Incomplete.**

There is no grade for incomplete work. There is only "done" and "not done."

This is not done.

Now get back to work.
