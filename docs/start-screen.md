# Threshold Deep — Start Screen

*Drafted 2026-07-23. The first thing anyone sees on itch. A short
in-engine flythrough that ends facing a dungeon wall, where the menu
is carved into the stone. No 2D title card — the menu is the game's
own world, seen before you can move in it.*

## The pitch

Click-to-descend on black → the camera walks a corridor, torch in
hand → around a corner, the sword planted in stone, lit → the camera
settles facing a wall → three plates fade up on the stone: START,
OPTIONS, QUIT. Music starts sparse at the click and swells as the
plates land.

**Why this instead of a splash image:** Pillar 1. The art is the
game — a 2D title card would be the one screen in the project that
isn't the dungeon. The wall-menu costs three sprites and a hand-built
room and buys a first impression made of the actual game.

## Why the sword, not the wizard

The alternative pitch — a wizard rounds the corner and shoots you —
was rejected. It implies the camera is a character about to die, and
then the menu appears and nothing happens. It's a promise the screen
doesn't keep.

The sword planted in stone is a still image that carries the whole
game: a dungeon, a weapon, torchlight doing the work. It's also the
first weapon in the pool, historically the boss-1 reward, and the art
already exists. **Nothing has to happen for it to read.**

## The browser gate (this decides the opening frame)

Browsers block audio AND pointer-lock until a user gesture. Mouse
movement does not count — it must be a click, key, or touch. So don't
fight it; spend the gesture once and get everything.

- First frame is **black** with a single line: *click to descend*
  (Press Start 2P, small, centered, slow pulse).
- The click starts **everything**: flythrough, music, ambient. One
  gesture, and it's the same gesture the web build already needs for
  mouse capture (see web-demo-checklist.md).
- Nothing audible plays before the click. Don't design a silent-walk
  opening that assumes drips or torch crackle — those are gated too.

## Scene structure

`scenes/title.tscn` becomes the **startup scene** in project.godot
(replacing `dungeon.tscn`). The dungeon never learns the title exists
— one-way dependency, no coupling.

- **Hand-authored room.** A small fixed corridor + corner + end wall.
  GridMap with the existing tile library, or placed meshes; nothing
  needs to be walkable, there is no player body. Reuse
  `dungeon_tiles.tres` so the stone matches the game exactly.
- **Camera3D on a Path3D** via PathFollow3D. Tween
  `progress_ratio` 0 → 1. Camera at player eye height (y = 0.5 floor
  + player eye offset) so the scale reads identical to gameplay.
- **Torch light on the camera** — same OmniLight3D setup and flicker
  as the player's, parented to the camera. This is what makes it look
  like the game and not a cutscene.
- **Sword: Sprite3D**, billboard as in-game, placed by hand at the
  corner, with its pickup glow. Optionally a slow hover bob (same
  code path as world pickups).
- **Menu: CanvasLayer Control** faded in at tween end. Plates are 2D
  over the settled camera view, not world-space quads — simpler,
  pixel-crisp, and the camera is static by then so it reads as
  on-the-wall regardless.
- **MusicDrift** is bypassed here; the title track plays as a plain
  AudioStreamPlayer, one shot, started by the click.

## Timing

Author the track to a **fixed length** and tween the camera to match.
Timing a 12 s camera to a 12 s piece is easy; looping-and-hoping is
not.

| Beat | Approx | What |
|---|---|---|
| Black | — | *click to descend* |
| Walk | 0–6 s | corridor, torch flicker, sparse music |
| Corner + sword | 6–10 s | the reveal; music begins to build |
| Settle on wall | 10–12 s | camera eases to a stop, drift begins |
| Plates | 12 s | fade up on the swell |

Solstice-style structure: sparse walk, swell on arrival. **The music
cue and the plate fade-in fire on the same signal** (tween
`finished`), so they can't drift apart.

## After the tween — keep it alive

The screen must not freeze into a still. On settle:

- Camera keeps a **tiny idle drift** (slow sine on rotation, ~1–2°).
- **Torch keeps flickering.** This alone animates the whole frame.
- Plate hover states react to the light (below).

## Second visit — the skip rule

Twelve seconds is charming once and irritating on run 20.

- **Any input during the flythrough skips to the settled state**
  (menu up, music jumps to its swell or just starts there).
- **Returning from death or victory goes straight to the settled
  camera**, menu already up, no flythrough. Only a cold boot plays
  it. A `MetaState`/session flag (or a bool passed on scene change)
  decides which.

## Run lifecycle — the title is the hub

The important structural rule, and the reason to do this now:

> **A run is minted at the title, not at the dungeon.**

- START does `RunState.reset()` then
  `change_scene_to_file("res://scenes/dungeon.tscn")`.
- Death and victory return **to the title**, not to a dungeon reload.
- When `MetaState` lands, the title is where it loads and where
  banked unlocks are applied before a run begins.

`dungeon.tscn` only ever consumes state it was handed. This is what
keeps pre-game and post-3-3 content from tangling later.

## Art specs — the plates

Three plates: **START**, **OPTIONS**, **QUIT**.

| Spec | Value |
|---|---|
| Canvas | 128×32 per plate (larger if carving needs it) |
| Display | 3× nearest, as with all UI |
| Font | Press Start 2P, **drawn into the plate art**, not a Label on top |
| States | 2 minimum — resting, hovered |
| Base | Draw ONE plate, vary the text — same discipline as the crystal cuts |

**Hover is light, not color.** The plate catches the torch, or an
ember glow wakes behind the letters. Pillar 3 on a menu, and the
torch flicker animates the hover for free.

**Test in torchlight before finishing.** The plates sit on the
existing stone tile at low light — same early-test rule as the mist
tints. Contrast that reads in the editor may vanish in the dark.

Optional later: a drawn title logo above the plates, or the game's
name carved into the wall as part of the tile art.

## Options — scope now, contents later

Ship the plate; keep the panel minimal. Likely contents:
master/music/SFX volume, mouse sensitivity, fullscreen. QUIT should
be hidden on web builds (`OS.has_feature("web")`) — there's nothing
to quit to in a browser tab.

## Build order

1. Hand-build the corridor room and set the camera path. Grey-box it
   with existing tiles; get the walk feeling right first.
2. Place the sword and the torch light. This is the shot — judge it
   before drawing anything.
3. Draw the plates. Test in torchlight, retune (the retune rule
   applies: first placement is a draft).
4. Wire the click gate, the tween, the fade, and the skip rule.
5. Move `RunState.reset()` to START and route death/victory back
   here.
6. Web smoke test — click gate, pointer lock, audio, and the
   Compatibility renderer's take on the torch light.

## Done when

- Cold boot: click → flythrough → plates, and it reads as the game.
- Any input skips it; death returns to the settled menu with no
  replay.
- START begins a clean run; the dungeon has no knowledge of the
  title scene.
- Runs clean in the browser build with audio and pointer lock alive
  after the first click.
