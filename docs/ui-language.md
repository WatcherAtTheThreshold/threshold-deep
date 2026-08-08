# Threshold Deep — UI Language

*Drafted 2026-08-07. The connective tissue between screens that are
already specced elsewhere. `start-screen.md` designs the title,
`structure.md` designs the run, the roadmap lists the endings — none of
them say what UI **is** in this game. This does.*

**Scope: the demo.** A 5–10 minute experience that ships and collects
feedback. Everything here is sized to that. Meta-progression UI is
deliberately out of scope — see the last section for why that's safe.

---

## The one rule

> **UI is drawn art in torchlight, not text on a surface.**

This is not a new decision. It's already written in
[start-screen.md](start-screen.md) and already true of the only two
finished UI pieces in the project:

> Font: Press Start 2P, **drawn into the plate art**, not a Label on top.
> … Hover is light, not color. The plate catches the torch, or an ember
> glow wakes behind the letters. Pillar 3 on a menu.

**Why the in-game UI currently has no character:** it's in the other
medium. The HUD is seven `Label` nodes — typeset text floating on
nothing. The title menu is drawn plates with three hand-made states
each. Nothing is wrong with either in isolation; the game just speaks
two languages and only one of them sounds like the game.

Ratifying this rule is the single decision that turns "design six
screens" into "execute six screens."

### The rule's three consequences

1. **Menu items are drawn, not typeset.** A button is a PNG with its
   word already on it. Draw ONE plate and vary the word — the same
   discipline as the crystal cuts and the creature turnarounds.
2. **State changes are light, not colour.** Hover means the torch
   catches it or an ember wakes behind the letters. Never a tint swap,
   never a highlight rectangle. This is Pillar 3 applied to menus:
   light equals meaning.
3. **Everything gets judged in torchlight.** Contrast that reads in the
   editor vanishes in the dark — the same trap the mist tints and the
   tile appearances both hit. Test on the dungeon's actual stone at
   actual light before calling a piece done.

### Where the rule does NOT apply

Live gameplay readouts — hearts, the run line, damage flashes. Those
must be legible in a fight, and drawn-in text can't reflow. They stay
functional. But see **UI over gameplay** below: they still need to
look like they belong to the same world.

---

## What exists today

The honest inventory, measured rather than remembered.

### Finished

| Piece | Spec | Notes |
|---|---|---|
| Title plates | **300 × 93**, 3 states (rest / hover / pressed) | `assets/ui/title/`. `texture_filter = 1` (nearest), no scale override — drawn at final size |
| Heart icons | **16 × 16**, shown 3× (48 px) | full / half / empty / magic / magic_half |

> **Note:** `start-screen.md` specs plates at 128 × 32. The shipped art
> is 300 × 93. The art won — update the older doc, not the plates.

### Typeset, not designed

Seven `Label` nodes in `player.tscn`'s HUD:

| Node | Size | Colour |
|---|---|---|
| `RunInfo` (floor · clock · score) | 16 | — |
| `LevelLabel` (the misted floor card) | 48 | `0.95, 0.95, 0.98` near-white |
| `DeathLabel` | 48 | `0.85, 0.20, 0.25` red |
| `DeathCause` | 24 | `0.85, 0.55, 0.45` salmon |
| `DeathStats` | 16 | `0.80, 0.75, 0.70` warm grey |
| `ToastName` | 40 | `0.91, 0.76, 0.35` gold |
| `ToastDesc` | 24 | `0.75, 0.73, 0.64` bone |

Sizes are disciplined — every one is a multiple of 8, per the existing
rule. **Colours are not.** Six distinct values arrived one at a time.
That's the palette to consolidate (see open questions).

### Not built

Pause menu · Options panel · designed death screen · designed victory
screen · the `click to descend` frame's typography.

---

## Specs

Carried forward from CLAUDE.md and start-screen.md so this file is the
one place to look.

| Asset | Canvas | Display |
|---|---|---|
| Menu plates | 300 × 93 | 1:1, nearest |
| UI icons (hearts, item strip) | 16 × 16 | 3× → 48 px |
| Item / crystal icons | 16 × 16 | 3× → 48 px |

- **Font:** Press Start 2P (`assets/fonts/`, OFL).
- **Sizes:** multiples of 8 only — 16 / 24 / 40 / 48 are the set in use.
  Don't add a size without a reason; four steps is a scale, seven is a
  mess.
- **Filtering:** nearest, always. Everything in this game is pixels.

---

## The unsolved problem: UI over gameplay

This is the part no existing doc covers, and it's why the **pause menu
is the right next piece to build**.

The title plates live on a hand-built wall in a controlled shot. You
choose the light. The pause menu has to sit over a live dungeon at
whatever the torch happens to be doing — sometimes a lit corridor,
sometimes near-black, sometimes an orb going off behind it.

Solve *"what does a plate look like on top of the dungeon"* once and it
answers the HUD, the toasts, the death report and the victory screen at
the same time. Solve the death screen first and you've answered it for
one screen that only ever appears on black.

Things that need an answer, all of them visual calls:

- Does the world dim behind a menu, and by how much? (A `ColorRect`
  scrim already exists as `HurtFlash` / `ScreenFade` — the mechanism is
  there.)
- Does the world keep animating behind the pause, or freeze?
- Do plates need a backing so they read over any tile, or does the
  scrim make that unnecessary?
- Do live HUD elements stay visible while paused?

---

## Screen by screen — what the demo needs

Ordered by leverage, not by appearance in play.

### 1. Pause menu — **demo gate**

The web-demo checklist's *"Controls surfaced somewhere in-game"* is
still unchecked, and this is what checks it. `ui_cancel` currently only
toggles mouse capture ([player.gd:447](../scripts/player.gd)) — the
hook is already where the menu belongs.

Contents: **RESUME · OPTIONS · QUIT TO TITLE**, plus the control list
(move / dash / attack / Esc). Reuses the title plates.

Quitting to title is free — `hud.gd` already does exactly that on death.

### 2. Options — needed more than usual for a web build

Specced in start-screen.md, unbuilt. Master / music / SFX volume, mouse
sensitivity, fullscreen. **Hide QUIT on web** (`OS.has_feature("web")`)
— there's nothing to quit to in a browser tab.

Volume matters disproportionately here: people play browser games in a
tab beside other audio, and the demo has no volume control at all.

Sliders are the one place the plate rule bends — a slider can't be a
drawn word. Keep them minimal and let the plates around them carry the
identity.

### 3. Death & victory — **demo gate**

Built and working, but typeset. The roadmap's finish work says it
plainly: *"a demo lives or dies on its endings."* This is the last
thing a player sees before deciding whether to tell anyone.

Structure is already decided in `structure.md` and shipped: SCORE
leads, kills are a line, the killer's name and portrait appear. This is
a **visual** pass on a working screen, not a redesign.

### 4. The `click to descend` frame

The literal first impression, currently a bare Label on black — the
most typeset thing in the game sitting at frame one.

**Keep the black frame.** start-screen.md rejected a 2D title card for
a good reason (Pillar 1: a title card would be the one screen that
isn't the dungeon), and the black frame is the browser gesture gate
besides. It doesn't need replacing, it needs *drawing*.

### 5. HUD identity

Last, deliberately. It works, it's legible, and it's the screen where
the plate rule applies least. Once the pause menu has established what
UI looks like over the dungeon, the HUD gets the same treatment for
free.

---

## Decided vs. open

**Decided** (in this doc or already in the codebase):

- UI is drawn art in torchlight, not text on a surface
- Hover is light, never colour
- Plates are 300 × 93, three states, nearest, drawn at final size
- Press Start 2P, multiples of 8
- The title is the hub; a run is minted there, death returns there
- The black `click to descend` frame stays
- Pause menu is the next piece built

**Open — Jessop's calls, not to be guessed:**

- **The colour palette.** Six font colours exist; how many should?
  Suggest picking three roles — *neutral* (read this), *gold* (you
  gained), *red* (you lost) — and mapping the seven labels onto them.
- **The scrim.** Does the world dim behind a menu, how much, and does
  it freeze?
- **Plate backing.** Do plates need to carry their own ground to read
  over arbitrary tiles?
- **Whether the HUD becomes drawn at all**, or stays functional text in
  a consolidated palette.

---

## Out of scope for the demo

**Meta-progression UI.** It's the post-demo headline and it will want
screens — unlock grids, run history, whatever the banked-runs system
turns out to be. It's safe to defer, and here's the structural reason:

> **A run is minted at the title, not at the dungeon.**
> — start-screen.md, and it's real: `title.gd:173` mints the run,
> `hud.gd:247` returns to the title on death.

The title is *already* the hub. When MetaState lands it adds a screen to
an existing hub — it doesn't rewire the flow. So designing the demo's UI
now creates no meta rework, provided the language scales. "Drawn plates,
hover is light" scales to an unlock grid without amendment.

Also out: the corridor-walk warmup and creature-silhouette intro
(start-screen.md's own "future polish"), and any per-act UI theming.

---

## Done when

- A player can pause, see the controls, change the volume, and resume.
- Death and victory look like they were made by the same hand as the
  title.
- Nothing in the demo is a bare Label on a black rectangle.
- Someone who has never seen the game can get through the first sixty
  seconds without being told anything out-of-game.
