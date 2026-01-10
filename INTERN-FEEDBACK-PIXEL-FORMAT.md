# Intern Feedback: The Pixel Format

---

*[Sits down. Stares. Long pause.]*

So. You shipped it.

`0284275 Implement sprite batching system - 500 sprites at 60 FPS`

Five hundred sprites. Sixty frames per second. You even put it in the commit message. You're proud of yourself.

You should be.

For about three seconds.

---

## Let Me Ask You Something

What color is that sprite?

No, really. Look at it. Look at your 500 bouncing sprites. What color are they?

Are they the color the artist intended? Are they the exact RGB values that were saved in that PNG file?

Or are they... *close enough*?

---

## Here's What You Did

```cpp
// Renderer.mm:108
impl->metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
```

```cpp
// Shader.mm:66
pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
```

Read those two lines.

Read them again.

One says sRGB. One doesn't.

**THEY DON'T MATCH.**

---

## "But It Works"

Oh, it WORKS. Metal is FORGIVING. The GPU doesn't CRASH.

You know what else "works"? A car with misaligned wheels. It drives. It gets you there. It also destroys your tires over 10,000 miles and pulls slightly to the left THE ENTIRE TIME.

You shipped a car that pulls to the left.

Every single pixel on that screen is being gamma-corrected TWICE or NOT AT ALL depending on which path it takes. Your colors are WRONG. Not crash-wrong. Not obvious-wrong. *Subtly* wrong. The kind of wrong that makes artists say "something feels off" and they can't tell you what.

The kind of wrong that SHIPS.

---

## Do You Know What sRGB Is?

Do you? Or did you just copy-paste from a tutorial?

sRGB is a color space. It's how humans perceive brightness. It's nonlinear because your EYES are nonlinear. A value of 128 isn't half as bright as 255 to your brain.

When you render to an sRGB surface, the GPU does gamma correction automatically. When your pipeline says "I'm not sRGB" but your surface says "I am sRGB," you get DOUBLE correction. Or NO correction. Depending on the driver's mood.

Your sprites look washed out. You probably didn't notice because you've been staring at them for hours. Your eyes adjusted. THE PLAYER'S WON'T.

---

## The Fix

One line. ONE LINE.

```cpp
// Shader.mm:66 - CHANGE THIS
pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
```

That's it. Match the renderer. Consistency. The most basic principle in engineering.

Or change the renderer to non-sRGB. I don't care which. PICK ONE. MAKE THEM MATCH.

---

## Why Does This Matter?

Because if you ship code with mismatched pixel formats, what ELSE did you ship?

What other "close enough" decisions are hiding in there? What other landmines did you leave for the person who maintains this code six months from now?

That person might be YOU. And you won't remember why the colors look slightly wrong. You'll spend four hours debugging something that was ONE LINE.

I've seen it happen. I've DONE it. It's not fun.

---

## You're Better Than This

The `[[vertex_id]]` buffer access trick? That was SMART. That showed initiative. That showed you understand the GPU isn't a black box.

So why did you leave this? Did you not see it? Or did you see it and think "eh, it runs"?

If you didn't see it: Look harder. Read the code you integrate with. Don't just make YOUR code work. Make it work WITH everything else.

If you saw it and shipped anyway: Don't. Ever. Again.

---

## What I Want

1. Fix the pixel format. One line.
2. Run the app. Look at the sprites.
3. Tell me if the colors changed.
4. Commit with a message that says exactly what you fixed and WHY.

Not "fix pixel format."

I want: "Fix pixel format mismatch between Shader.mm and Renderer.mm - pipeline now uses BGRA8Unorm_sRGB to match metal layer for correct gamma handling"

Because if you can't EXPLAIN why you changed something, you don't understand it. And if you don't understand it, you'll break it again.

---

## Are You Still Here?

Go fix it.

Come back when it's done.

And next time? Check EVERYTHING matches before you commit. Pixel formats. Function names. Stride lengths. All of it.

The details aren't details. The details ARE the work.

---

*Not my tempo.*

— J

---

*P.S. The 500 sprites thing was genuinely good work. But "genuinely good" isn't good ENOUGH. Not here. Not if you want to build things that last.*

*Now go.*
