# Threshold Deep — Creature Polish Audit

*Generated 2026-07-25 by reading every creature script. The spiderweb,
laid flat: one row per creature, so juice becomes a checklist you pick
from instead of a worry you carry. Update the ✓/— as you go.*

Legend: **✓** present · **—** missing · **~** partial / generic

> **Status (updated 2026-07-25): the feedback pass is essentially DONE.**
> Every creature now: winds up an **attack lunge**, **startles** in an
> alert pose the first beat it notices you (visual — sounds still TODO,
> except the amalgam's roar), **recoils** with a directional **take-hit**
> animation when struck, and **dies with a sound**. The only remaining
> cross-cutting audio work is the aggro-SOUND sweep (§A) and the
> signature-mechanic sounds (split/merge/fuse/cast). Take-hit is
> knock-branch driven for mobs, `hit_anim`-timer driven for the amalgam.

| Creature | Attack anim | Hit flash | Aggro "sees you" SFX | Hit SFX | Death SFX | Death art |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| Skeleton | ✓ | ✓ | —¹ | ✓ | ✓ | ✓ |
| Wizard | ✓ (cast) | ✓ | —¹ | ✓ | ✓ | ✓ |
| Slime (+ boss) | ✓ | ✓ | —¹ | ✓ | ✓ | ✓ |
| Mush (+ boss) | ✓ | ✓ | —¹ | ✓ | ✓ | ✓ |
| Frogman (coated) | ✓ | ✓ | —¹ | ✓ | ✓ | ✓ |
| Frog | ✓ | ✓ | —¹ | ✓ | ✓ | ✓ |
| Toad | ✓ | ✓ | —¹ | ✓ | ✓ | ✓ |
| Skeletal Wizard (boss) | ✓ | ✓ | ✓ (roar) | ✓ | ✓ | ✓ |

¹ **Aggro column = the SOUND.** The *visual* aggro is done everywhere: a
front-facing alert sprite + ~0.35 s startle freeze on the rising edge of
noticing you. What's missing is the audio — a one-liner at that same
rising edge (see A). The Skeletal Wizard's roar (sprite + SFX on its rise)
is the one that's fully done, visual and sound.

---

## The two cross-cutting wins (do these first)

These are the biggest bang-for-buck because each is **one pattern applied
across every creature**, not bespoke work per enemy.

### A. The "sees you" cue — VISUAL done, SOUND is now a one-liner
**Update:** every creature (except the Skeletal Wizard) now has a
**visual aggro beat** — a single front-facing alert sprite shown during a
~0.35 s **startle freeze** the first frame it notices the player, via the
`noticed` rising-edge flag + `aggro_timer`. That means the hook the
sound needs **already exists and is wired in every combat script.**

To add the audio, drop one line at the rising edge that already sets the
freeze (`noticed = true; aggro_timer = AGGRO_TIME`):
```gdscript
Sfx.play_at(AGGRO_SOUNDS[randi_range(0, AGGRO_SOUNDS.size() - 1)],
        global_position, -3.0)
```
It'll land exactly on the startle pose — sprite and sound together. Per
tier, the sprite is chosen by `aggro_tex` (set in `_apply_state`); a
sound array can mirror that if tiers should sound different.

Split-spawned bodies (frog/toad, split slimes/minis) set `noticed = true`
on spawn so they DON'T startle-freeze mid-fight — a sound sweep should
respect that same gate (only the rising edge, never on spawn).

Still pending: the **Skeletal Wizard** aggro (the author is giving it a
roar), and the actual sound files for everyone else.

### B. Death sounds — DONE
Every creature now plays a death SFX in its `_die()` — wizard, slime,
frog/toad, the Skeletal Wizard (−2 dB, a heavier boss stinger), and the
mush **per tier** (mini/mush/mega/boss, switched on `state`). The whole
roster gained weight in one sweep.

---

## Per-creature notes (has / needs / where)

### Skeleton — [skeleton.gd](../scripts/skeleton.gd)
- **Has:** hit flash, hit SFX (×3), **death SFX**, revive/"stir" SFX for
  restless bones ([skeleton.gd:96](../scripts/skeleton.gd#L96)), dead +
  mid-rise art, and now a **directional attack lunge** (front/side via
  `_attack_view`, plays on each strike).
- **Needs:** aggro cue (see A).
- Note: the most complete creature; use it as the reference (the
  attack-lunge pattern here + frog/toad is the template for slime/mush).

### Wizard — [wizard.gd](../scripts/wizard.gd)
- **Has:** a real cast telegraph (charge/release/recover frames +
  swelling `cast_glow`), hit flash, hit SFX (×3), dead art.
- **Needs:** **death SFX** (silent `_die`), **aggro cue**, and — notably
  — **the orb fires with no sound.** `_fire_orb`
  ([wizard.gd:248](../scripts/wizard.gd#L248)) has no `Sfx.play`; a cast
  whoosh on release (and optionally a charge hum during `_start_cast_glow`)
  would give the telegraph teeth. Check whether `orb.tscn` plays its own
  impact — if not, that's a third cue.
- Best starting point for the aggro pass — the "sees you" incantation is
  the most characterful cue on the roster.

### Slime (+ Slime Boss) — [slime.gd](../scripts/slime.gd)
- **Has:** hit flash, hit SFX (×3), rich state art (spawn puddle,
  mid-spawn, respawn tell, splat), split/merge logic.
- **Also has:** a **directional attack lunge** (front/side via
  `_attack_view`; boss front-only), the **caustic touch** + **creep
  trail** poison system, and fading **death pools**.
- **Needs:** **death/burst SFX** (silent `_die`), aggro cue, and *split &
  merge* sounds — `_split` / `_merge` are visually juicy but silent.
- Boss: a distinct heavier death stinger when the whole cascade ends.

### Mush family (+ Mush Boss) — [mush.gd](../scripts/mush.gd)
- **Has:** hit flash, hit SFX (×3), a lovely **discover cue** when a mini
  finds kin/puddle to fuse ([mush.gd:325](../scripts/mush.gd#L325)) +
  surprise art, per-tier dead art.
- **Also has:** a **directional attack lunge** across all four tiers
  (front/side/back via `_attack_view`; boss front-only), and a **gold
  spore poof** (`_puff_spores`, CPUParticles) on any player hit.
- **Needs:** **death SFX** (silent `_die`), aggro cue, *fuse & split*
  sounds (the fusion is a signature mechanic and currently silent).

### Frogman → Frog / Toad — [frogman.gd](../scripts/frogman.gd)
- **Has:** coated walk turnaround, the comedic coat-off **reveal beat**,
  **frog & toad attack lunges (just added)**, hit flash, shared hit SFX
  (×3), dead art + crumpled-coat prop.
- **Needs:** **death SFX** (silent `_die`), aggro cue, and a **reveal
  stinger** — the coat-off freeze at [frogman.gd `_start_reveal`](../scripts/frogman.gd)
  is the game's best comic beat and plays in silence; a little sting would
  make it land. Coated frogman has no attack lunge (it mostly wanders), so
  low priority there.

### Skeletal Wizard — boss — [skeletal_wizard.gd](../scripts/skeletal_wizard.gd)
- **Has:** attack windup/release frames, orb frames, **orb impact SFX**
  (×3), hit flash, hit SFX (×3), dead art. The most animated fighter.
- **Needs:** **death SFX** (a boss deserves a real one — silent `_die` at
  [skeletal_wizard.gd:209](../scripts/skeletal_wizard.gd#L209)), a **cast/
  launch sound** for the volley (only the *impact* has audio now), and
  optionally a fight-start roar when the consent plate drops the seal.

---

## The generic-hit-flash note (later, not now)
Every creature's damage flash is the *same* `Color(1, 0.3, 0.3)` →
white tween. It reads fine, but if you ever want per-creature identity
(a green mush flash, a blue slime shudder), that's a one-color change in
each `take_damage`. Filed as ~, not a gap.

## Suggested slicing order
1. ~~**Death-sound sweep.**~~ **DONE** — every creature plays a death SFX
   (mush per tier, boss stingers louder). (Win B.)
2. **Aggro-SOUND sweep** — the ONE remaining cross-cutting win, and it's
   half-done: the rising-edge hook (`noticed` + `aggro_timer` + the startle
   freeze) is wired in every combat script. All that's left is one
   `Sfx.play_at` per creature at that spot. Start with the wizard
   incantation. (Win A.) The Skeletal Wizard's roar is the template.
3. **Signature-mechanic sounds** — slime split/merge, mush fuse/split,
   frogman reveal stinger, wizard/boss cast launch.
4. ~~**Melee attack lunges.**~~ **DONE** — every creature has a directional
   attack lunge; the Attack-anim column is fully ✓.

Each numbered step is independently testable and shippable. **The single
biggest remaining lever is the aggro-SOUND sweep (2)** — the hook is in,
so it's now the cheapest high-impact pass left.
