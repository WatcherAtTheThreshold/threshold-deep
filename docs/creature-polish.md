# Threshold Deep — Creature Polish Audit

*Generated 2026-07-25 by reading every creature script. The spiderweb,
laid flat: one row per creature, so juice becomes a checklist you pick
from instead of a worry you carry. Update the ✓/— as you go.*

Legend: **✓** present · **—** missing · **~** partial / generic

> **Status (updated 2026-07-29): the feedback pass is DONE, and so is the
> aggro-SOUND sweep.** Every creature now: winds up an **attack lunge**,
> **startles** in an alert pose AND plays a "sees-you" sting the first
> beat it notices you, **recoils** with a directional **take-hit**
> animation when struck, and **dies with a sound**. The only remaining
> cross-cutting audio work is the **signature-mechanic sounds**
> (split/merge/fuse/reveal/cast launch). Take-hit is knock-branch driven
> for mobs, `hit_anim`-timer driven for the amalgam.

| Creature | Attack anim | Hit flash | Aggro "sees you" SFX | Hit SFX | Death SFX | Death art |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| Skeleton | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Wizard | ✓ (cast) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Slime (+ boss) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Mush (+ boss) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Frogman (coated) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Frog | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Toad | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Skeletal Wizard (boss) | ✓ | ✓ | ✓ (roar) | ✓ | ✓ | ✓ |

**Aggro column = the SOUND, now DONE (2026-07-29).** Visual + audio
together: a front-facing alert sprite + ~0.35 s startle freeze on the
rising edge of noticing you, and a random `AGGRO_SOUNDS` "sees-you" sting
at that same edge (per-family trios; frogman's clips are the irregular
`frogmen_aggro`/`2`/`3`). Player-only trigger; split/spawn-born bodies are
`noticed = true` so they never sting mid-fight. The Skeletal Wizard uses
its rise **roar** in place of a startle; a separate in-battle re-aggro
sting is the one small open sub-item (parked until playtests show it
gets far enough away to re-trigger).

---

## The two cross-cutting wins (do these first)

These are the biggest bang-for-buck because each is **one pattern applied
across every creature**, not bespoke work per enemy.

### A. The "sees you" cue — DONE (visual + sound)
Every creature has a **visual aggro beat** (a front-facing alert sprite
during a ~0.35 s **startle freeze** the first frame it notices the player,
via the `noticed` rising-edge flag + `aggro_timer`) **and** an audio
sting at that same edge:
```gdscript
Sfx.play_at(AGGRO_SOUNDS[randi_range(0, AGGRO_SOUNDS.size() - 1)],
        global_position, -4.0)
```
Wired in skeleton / wizard / frogman / slime / mush — one per-family
`AGGRO_SOUNDS` trio each. It lands exactly on the startle pose, sprite and
sound together. Player-only (`t == player` / `goal == player`);
split-spawned bodies (frog/toad, split slimes/minis) set `noticed = true`
on spawn so they never sting mid-fight. The Skeletal Wizard uses its
**rise roar** instead of a startle.

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
- **Needs:** nothing outstanding — fully done (aggro cue wired 2026-07-29).
- Note: the most complete creature; use it as the reference (the
  attack-lunge pattern here + frog/toad is the template for slime/mush).

### Wizard — [wizard.gd](../scripts/wizard.gd)
- **Has:** a real cast telegraph (charge/release/recover frames +
  swelling `cast_glow`), hit flash, hit SFX (×3), dead art.
- **Needs (signature sound):** **the orb fires with no sound.** `_fire_orb`
  ([wizard.gd:248](../scripts/wizard.gd#L248)) has no `Sfx.play`; a cast
  whoosh on release (and optionally a charge hum during `_start_cast_glow`)
  would give the telegraph teeth. Check whether `orb.tscn` plays its own
  impact — if not, that's a third cue. (**Death SFX and aggro cue: DONE.**)

### Slime (+ Slime Boss) — [slime.gd](../scripts/slime.gd)
- **Has:** hit flash, hit SFX (×3), rich state art (spawn puddle,
  mid-spawn, respawn tell, splat), split/merge logic.
- **Also has:** a **directional attack lunge** (front/side via
  `_attack_view`; boss front-only), the **caustic touch** + **creep
  trail** poison system, and fading **death pools**.
- **Needs (signature sounds):** *split & merge* sounds — `_split` /
  `_merge` are visually juicy but silent. (**Death SFX and aggro cue:
  DONE.**)
- Boss: a distinct heavier death stinger when the whole cascade ends.

### Mush family (+ Mush Boss) — [mush.gd](../scripts/mush.gd)
- **Has:** hit flash, hit SFX (×3), a lovely **discover cue** when a mini
  finds kin/puddle to fuse ([mush.gd:325](../scripts/mush.gd#L325)) +
  surprise art, per-tier dead art.
- **Also has:** a **directional attack lunge** across all four tiers
  (front/side/back via `_attack_view`; boss front-only), and a **gold
  spore poof** (`_puff_spores`, CPUParticles) on any player hit.
- **Needs (signature sounds):** *fuse & split* sounds (the fusion is a
  signature mechanic and currently silent). (**Death SFX and aggro cue:
  DONE.**)

### Frogman → Frog / Toad — [frogman.gd](../scripts/frogman.gd)
- **Has:** coated walk turnaround, the comedic coat-off **reveal beat**,
  **frog & toad attack lunges (just added)**, hit flash, shared hit SFX
  (×3), dead art + crumpled-coat prop.
- **Needs (signature sound):** a **reveal stinger** — the coat-off freeze
  at [frogman.gd `_start_reveal`](../scripts/frogman.gd) is the game's best
  comic beat and plays in silence; a little sting would make it land.
  (**Death SFX and aggro cue: DONE.**)

### Skeletal Wizard — boss — [skeletal_wizard.gd](../scripts/skeletal_wizard.gd)
- **Has:** attack windup/release frames, orb frames, **orb impact SFX**
  (×3), hit flash, hit SFX (×3), dead art. The most animated fighter.
- **Needs (signature sound):** a **cast/launch sound** for the volley
  (only the *impact* has audio now). (**Death SFX: DONE**, −2 dB boss
  stinger; **rise roar: DONE** on assembly. A separate in-battle re-aggro
  sting is parked — see the matrix note.)

---

## The generic-hit-flash note (later, not now)
Every creature's damage flash is the *same* `Color(1, 0.3, 0.3)` →
white tween. It reads fine, but if you ever want per-creature identity
(a green mush flash, a blue slime shudder), that's a one-color change in
each `take_damage`. Filed as ~, not a gap.

## Suggested slicing order
1. ~~**Death-sound sweep.**~~ **DONE** — every creature plays a death SFX
   (mush per tier, boss stingers louder). (Win B.)
2. ~~**Aggro-SOUND sweep.**~~ **DONE (2026-07-29)** — a per-family
   `AGGRO_SOUNDS` trio fires at the `noticed` rising edge in skeleton /
   wizard / frogman / slime / mush, landing on the startle pose. (Win A.)
   Auditionable in the gallery (each creature's aggro view plays its sting).
3. **Signature-mechanic sounds** — the ONE remaining cross-cutting audio
   pass: slime split/merge, mush fuse/split, frogman reveal stinger,
   wizard/boss cast launch.
4. ~~**Melee attack lunges.**~~ **DONE** — every creature has a directional
   attack lunge; the Attack-anim column is fully ✓.

Each numbered step is independently testable and shippable. **The single
remaining cross-cutting lever is the signature-mechanic sounds (3)** —
everything else on this audit is done.
