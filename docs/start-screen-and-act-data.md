# Threshold Deep — Start Screen & Act-Data Notes

*Captured 2026-07-22 from a polish-phase design discussion. Two pieces
of advice worth not forgetting: (1) build the start screen now, and
(2) move act definitions into data before act 2 exists to tangle. The
code specifics below ("presumably", "almost certainly") are hypotheses
about the current code — confirm them when you actually pick this up.*

## The start screen — do it now

It's a small, clean piece of work and a genuinely good next thing:
it's the **first thing anyone sees on itch**, and right now the game
presumably drops you straight into 1-1.

Structurally it's trivial:

- `title.tscn` becomes the startup scene instead of `dungeon.tscn`.
- A `Control` root, a `TextureRect` for the splash, a `VBoxContainer`
  of buttons, one script.
- **Start** does `RunState.reset()` then
  `get_tree().change_scene_to_file("res://scenes/dungeon.tscn")`.
- Nothing about the dungeon needs to know the title exists.

If you want it animated: an `AnimatedSprite2D` or a few `Sprite2D`s
with tweens — cheap, and it **reuses art you already have** (a creature
turnaround, torchlight flicker, the mist shader on a plane behind the
logo). `MusicDrift` already survives reloads, so a title track is one
autoload call away.

### The one discipline to get right

The title scene is where **`RunState` gets reset** — not where the
dungeon starts. Right now death probably resets `RunState` on reload.
If the title becomes the hub, make it the **single place a run is
born.** That's what keeps the backend clean later:

- `MetaState` loads at title.
- `RunState` is **minted** at title.
- `dungeon.tscn` only ever **consumes** what it's handed.

## The backend-mess worry — two different cases

The instinct to worry about mess is right, and the answer differs for
the two kinds of new content.

### Pre-game content is NOT the risk

A title screen, a settings menu, a bestiary viewer — these are **leaf
scenes** that hang off the tree and touch nothing. They can't mess up
the dungeon because the dungeon never calls them. Build them freely.

### Past-3-3 content is where mess comes from

The failure mode is specific: **hardcoded `3`.** Victory-at-3-3 almost
certainly lives as a literal in a couple of places, and floor kinds
are derived from stage number. If you add worlds 4-6 by bolting
another `if world == 4:` branch beside the existing ones, you get a
switch statement that grows with every act, and creature spawn tables
that grow the same way. That's the organic-exception trap.

## The cheap insurance: act definitions as data

Move act definitions **into data before you write act 2, not after.**

- One resource per act — `resources/acts/act_1.tres` — holding: tile
  set, creature pool, boss scene, music track, mist tints, victory
  flag.
- The generator asks `ActRegistry.get(world)` and builds from what
  it's handed.
- Adding act 4 becomes **writing a `.tres` and drawing sprites**, with
  zero code branching.

That's maybe an afternoon of refactor now versus a week of untangling
after three acts have grown their own exceptions.

## Sequencing

- **Do the title screen now** — it's contained and demo-visible.
- **Do the act-data refactor as the first step of act 2**, before any
  new content exists to be tangled.
