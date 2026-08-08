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

### 1. Pause menu — **BUILT 2026-08-08**

`scenes/pause_menu.tscn`. **RESUME · OPTIONS · QUIT TO TITLE** over a 0.6
scrim, plus the control list — which checks the web-demo checklist's
*"Controls surfaced somewhere in-game."*

The list is a 4-column grid, keyboard on the left and mouse on the right,
so the layout carries information. **RIGHT CLICK / shove is on it** — the
off-hand torch is the mechanic nobody discovers unaided, and omitting it
guaranteed they wouldn't. `R` is deliberately absent: the checklist itself
says it's debug-only and to hide it for the public build.

Traps this hit, all worth remembering: quit-to-title must **unpause before
changing scene** or the title loads frozen; the menu is parented to the
scene, not the player, or it dies with the body; and it's blocked while
`controls_enabled` is false so nobody can pause on top of their own death
report.

### 2. Options — **BUILT 2026-08-08**

`scenes/options_panel.tscn`, one scene instanced by both the title and the
pause menu so they can't drift. Master / Music / SFX volume, mouse
sensitivity, fullscreen (hidden on web — the browser owns the viewport).
QUIT is hidden on web too; nothing to quit to in a tab.

**It needed audio buses that didn't exist.** Everything played on Master,
so "music volume" had nothing to move. `default_bus_layout.tres` now has
Music and SFX, with all 13 scene-embedded players and both autoloads
routed.

Applies live while dragging, saves on close — a slider that only takes
effect on OK is a slider you can't set by ear, and saving per tick would
hit the disk a hundred times a drag.

### 3. Death & victory — **partly done 2026-08-08**

The death report has a **CLOSE plate** now. It used to hold a fixed 5 s and
jump to the title on its own, with no way to say "I've read it, let me go
again." `DEATH_HOLD_TIME` is 20 s and has changed meaning — it's the net
for someone who walked away, not the intended exit.

Three things that would have broken it, all worth remembering for the next
screen: the **mouse was still captured** from the fight (a visible,
unclickable plate is worse than no plate); the outro was welded into one
tween so CLOSE had to kill a queued callback, with a guard because the
button and the timer can land on the same frame; and `ScreenFade` goes
fully opaque, so the plate had to sit **later in sibling order** or it
would have faded out underneath the darkness.

**Victory is untouched and isn't an ending screen** — it's a banner that
fades in, holds 6 s, fades out and drops you back into play for the
endless descent. Nothing to close.

The remaining work here is the **visual** pass, below.

### 3b. Death & victory visuals — **demo gate**

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
- Plates are 300 × 93, three states, nearest, drawn at final size; the
  full-width `click_to_descend` prompt is 600 × 93
- Press Start 2P, multiples of 8
- The title is the hub; a run is minted there, death returns there
- The black `click to descend` frame stays — it got *drawn*, not replaced
- Pause menu is the next piece built

**Settled in build, 2026-08-08:**

- **A plate means "this is pressable."** Never put non-interactive text on
  one. The OPTIONS heading was nearly given a plate and shouldn't have
  been — players would click it. Headings are Labels; plates are buttons.
- **Never scale a plate non-integer.** They're pixel art at 1:1, so
  shrinking one to 0.75 shreds it. When a plate looks too big next to a
  heading, **resize the heading** — that's a font number. A genuinely
  smaller button means drawing a smaller plate, and that plate would then
  be the reusable "secondary action" size.
- **The scrim: dim, and freeze.** Pause runs `get_tree().paused = true`
  behind a 0.6 black scrim; Options adds 0.55 of its own. Menus set
  `PROCESS_MODE_ALWAYS` to work against it. Plates read fine on an
  arbitrary dungeon frame at that level — **no plate backing needed**,
  which closes that question.
- **A panel hides what it covers.** Options hides the pause plates and the
  control list rather than sitting on top of them; two screens showing
  through each other reads as unfinished.
- **Ticks mark a DEFAULT, not a recommendation.** Only the MOUSE slider has
  them — 1.0 is the tuned baseline and was unfindable at 32% of the old
  0.3–2.5 track. Volume has no correct value; your ears are the readout.
- **Two-tone lists.** Keys are gold `0.91, 0.76, 0.35`, actions bone
  `0.75, 0.73, 0.64`. Gold was chosen because it's ALREADY this UI's word
  for interactive — the plate hover glow and the OPTIONS heading — so the
  control list says "these are the things you press" in the language the
  interface already speaks. No new palette entries were invented.
- **Aligned columns are a container's job, not a monospace-padding job.**
  The control list is a 4-column `GridContainer` of 12 Labels. The hand-
  padded version was one character out twice, and centre-alignment centres
  each line independently so it showed.

**Still open — Jessop's calls, not to be guessed:**

- **The colour palette.** Still six-plus font colours. Suggest three roles
  — *neutral* (read this), *gold* (you gained / you press), *red* (you
  lost) — and mapping every label onto them.
- **Whether the HUD becomes drawn at all**, or stays functional text in a
  consolidated palette.
- **The stock widgets.** The fullscreen `CheckButton` is the single most
  out-of-place element on screen — it's the only thing that looks like it
  came from another program. Sliders are second. The panel background is
  third. Recommended order if the art time exists: toggle, panel, sliders;
  the labels can stay.

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
