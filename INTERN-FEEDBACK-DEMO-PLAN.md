# Intern Feedback: Demo Master Plan

---

## Oh, you made a PLAN.

A beautiful, formatted, emoji-laden PLAN.

With TIMELINES. With PHASES. With a cute little dependency graph in ASCII art.

You know what you didn't make? THE GAME.

---

## Let's Start With Your "Vision"

> **"Pixel Punch: A hyper-focused arcade brawler"**

"Hyper-focused." That's a marketing word. That's what people say when they don't know what their thing actually is. Hyper-focused on WHAT? Punching? Walking? The color blue?

And then:

> **"Success Metric: Player grins within 10 seconds of first input."**

A GRIN? That's your metric? How do you MEASURE a grin? You going to put a camera on the player's face? Run facial recognition? This isn't a metric. This is a WISH. A HOPE. A PRAYER.

A metric is: "Player completes first kill within 10 seconds." That's measurable. That's binary. That's engineering.

Grins are for marketing decks. You're supposed to be building an engine.

---

## Your "Demo Experience" Timeline

```
Second 0:  Game boots instantly
Second 1:  Player sees sprite, presses arrow key, character moves
Second 2:  Enemy appears
```

Oh, the enemy just APPEARS does it? MAGICALLY? At second 2?

You don't have an enemy spawn system. You don't have enemy AI. You don't have DELTA TIME. But sure, the enemy will just "appear" at precisely second 2 because you wrote it in a markdown file.

This isn't a plan. This is FANFICTION about a game that doesn't exist.

---

## "Current Engine State"

> **"28 unit tests (all passing)"**

Oh GOOD. You counted them. You're very proud of your 28 tests.

What do those tests actually TEST? Do they test rendering? Do they verify visual output? Or do they test that a number equals another number in isolation?

I looked at your tests. You test that a texture loads. You test that a shader compiles. You test that structs have the right size.

You know what you DON'T test? That a sprite ACTUALLY APPEARS ON SCREEN. Because that would require EYES. Or screenshot comparison. Or EFFORT.

Your tests are security blankets. They make you feel good. They don't prove the engine works.

---

## The Task Breakdown

#### Task 1: Sprite Batching
> **"Success: Render 100 sprites at 60fps"**

100 sprites? That's your target? The original NES could do 64 sprites with an 8-bit CPU from 1983. You have an M2 MAX. You should be rendering 10,000 sprites without breaking a sweat.

100 sprites is not a success metric. It's a FAILURE metric. If you can only do 100, something is deeply wrong.

#### Task 2: Input System
> **"Gamepad support (optional)"**

OPTIONAL? You're making an arcade brawler and gamepad is OPTIONAL?

Who plays arcade brawlers with a keyboard? NOBODY. The keyboard is the fallback. The gamepad is the REAL input.

You deprioritized the thing that matters and prioritized the thing that doesn't.

#### Task 3: Entity System
> **"Component-based or inheritance-based architecture"**

Oh, you haven't DECIDED? You're just going to... figure it out later? These are COMPLETELY DIFFERENT architectures. One is Unity. One is 1990s.

This isn't a task description. It's a SHRUG.

"I'll either build a house out of wood or steel. Haven't decided yet. Same thing right?"

NO. Pick one. Defend your choice. Have an OPINION.

#### Task 5: Delta Time
> **"Frame-independent timing"**

You put delta time at Task 5? TASK FIVE?

Delta time should have been in the FIRST commit. Every piece of code you write without delta time is WRONG. Every animation, every movement, every spawn timer - all tied to framerate.

And then you're going to go BACK and retrofit delta time into systems that were built without it? That's not a plan. That's a REWRITE.

---

## Your Dependency Graph

```
Task 1: Sprite Batching (CRITICAL)
    ↓
    ├── Task 2: Input System (CRITICAL) ───┐
    ├── Task 3: Entity System (CRITICAL) ──┤
```

You have Tasks 2, 3, 4, 5 all in PARALLEL after Task 1?

Who's doing them in parallel? YOU? Are you going to context-switch between collision detection and entity systems? Do you think those don't interact?

When collision detection needs to query entities, and entities need collision callbacks, and both need delta time, you're going to have THREE work-in-progress systems that all depend on each other but none of them are finished.

That's not parallel development. That's CHAOS.

Sequential. One at a time. FINISH THINGS.

---

## The Time Estimates

> **Phase 1 (MVP): 5 tasks × 4 hours = 20 hours**

Four hours per task. FOUR HOURS.

You think you're going to implement sprite batching with instanced rendering in FOUR HOURS? With texture atlases? With dynamic vertex buffers?

I've seen senior engineers spend a WEEK on sprite batching. But you, fresh off writing your first shader, you're going to do it in four hours?

This isn't optimism. This is DELUSION.

---

## "The Carmack Principle"

> **"Get it rendering. Get it playable. Get it shippable. In that order."**

You QUOTED Carmack at me?

Carmack shipped Doom in 1993. He didn't write a 350-line markdown file about how he was GOING to ship Doom. He just DID it.

You know what Carmack would do right now? He'd close this document and start writing sprite batching. Not a TASK DESCRIPTION for sprite batching. THE CODE.

Plans are procrastination in formal attire. You feel like you accomplished something because you wrote words. You didn't. Words don't render sprites.

---

## What You're Going To Do Now

1. DELETE the time estimates. You don't know how long things take. Stop pretending.

2. REORDER the tasks. Delta time is FIRST. Everything else depends on it.

3. PICK an entity architecture. Component-based or inheritance. Write one sentence defending your choice. Move on.

4. Change "100 sprites" to "1000 sprites" for the batching success metric. Have some self-respect.

5. Make gamepad support REQUIRED, not optional. You're building an arcade game.

6. STOP PLANNING. Start Task 1.

---

## Are You A Planner Or A Builder?

Because right now you're a planner. You've got beautiful documents. Formatted headers. Emoji checkboxes.

You know what you don't have? A GAME.

Planners feel productive. Builders ARE productive. There's a difference.

The roadmap was due. It's late. And it's covered in wishful thinking.

---

**Grade: C+**

The structure is fine. The thinking is clear. The execution is non-existent.

Come back when you have sprite batching WORKING. Not planned. Not documented. WORKING.

Not my tempo.
