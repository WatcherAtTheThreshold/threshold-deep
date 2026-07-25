# Threshold Deep — Creature Polish Audit

*Generated 2026-07-25 by reading every creature script. The spiderweb,
laid flat: one row per creature, so juice becomes a checklist you pick
from instead of a worry you carry. Update the ✓/— as you go.*

Legend: **✓** present · **—** missing · **~** partial / generic

| Creature | Attack anim | Hit flash | Aggro "sees you" SFX | Hit SFX | Death SFX | Death art |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| Skeleton | — | ✓ | — | ✓ | ✓ | ✓ |
| Wizard | ✓ (cast) | ✓ | — | ✓ | **—** | ✓ |
| Slime (+ boss) | — | ✓ | — | ✓ | **—** | ✓ |
| Mush (+ boss) | — | ✓ | — | ✓ | **—** | ✓ |
| Frogman (coated) | — | ✓ | — | ✓ | **—** | ✓ |
| Frog | ✓ *(new)* | ✓ | — | ✓ | **—** | ✓ |
| Toad | ✓ *(new)* | ✓ | — | ✓ | **—** | ✓ |
| Skeletal Wizard (boss) | ✓ | ✓ | n/a¹ | ✓ | **—** | ✓ |

¹ The amalgam is started by a consent plate, so a "notices you" cue is
less needed — but a fight-start roar would still land.

---

## The two cross-cutting wins (do these first)

These are the biggest bang-for-buck because each is **one pattern applied
across every creature**, not bespoke work per enemy.

### A. The "sees you" cue — the whole roster is silent when it notices you
Every creature runs `_perceives()` every frame, but nothing fires the
instant it *first* locks on. That first-notice moment is the single best
place for character: a skeleton's rattle, a wizard's incantation, a
slime's wet alert, a frog's croak.

**The hook doesn't exist yet — it's a rising edge you add.** `_perceives`
returns true continuously; you want the transition from false→true for
the *player* specifically. Add one flag and fire once:

```gdscript
var noticed := false   # near the other state vars
```
…then in `_physics_process`, right where perception is already computed:
```gdscript
var seen := _perceives(t, dist, sight)
if seen and not noticed and t == player:
    noticed = true
    Sfx.play_at(AGGRO_SOUNDS[randi_range(0, AGGRO_SOUNDS.size() - 1)],
            global_position, -3.0)
elif not seen:
    noticed = false   # re-arm once it loses you, so it can gasp again
```
Wizard already computes `sees_target` on [wizard.gd:98](../scripts/wizard.gd#L98)
— it's the cleanest first target. Skeleton/slime/mush/frogman each have
the same `_perceives` call to hang it on.

### B. Death sounds — only the skeleton has one
[skeleton.gd:296](../scripts/skeleton.gd#L296) plays `DEATH_SOUND` in
`_die`. **Wizard, slime, mush, frog, toad, and both bosses die silent.**
Each is a one-liner in that creature's `_die()`:
```gdscript
Sfx.play_at(DEATH_SOUND, global_position, -3.0)
```
The splat/corpse art is already there — this is purely the audio half.
A burst for the slime, a squelch for the mush, a bony clatter for the
frog, a heavier stinger for the two bosses.

---

## Per-creature notes (has / needs / where)

### Skeleton — [skeleton.gd](../scripts/skeleton.gd)
- **Has:** hit flash, hit SFX (×3), **death SFX**, revive/"stir" SFX for
  restless bones ([skeleton.gd:96](../scripts/skeleton.gd#L96)), dead +
  mid-rise art.
- **Needs:** *attack lunge* — the melee just stops and deals damage at
  [skeleton.gd:135](../scripts/skeleton.gd#L135) with no windup frame;
  a claw/bite would sell the hit. Aggro cue (see A).
- Note: it's the most complete creature; use it as the reference.

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
- **Needs:** **death/burst SFX** (silent `_die` at
  [slime.gd:485](../scripts/slime.gd#L485)), aggro cue, and *split & merge*
  sounds — `_split` / `_merge` are visually juicy but silent. An attack
  "squish-lunge" anim is optional (the squish walk half-sells it).
- Boss: a distinct heavier death stinger when the whole cascade ends.

### Mush family (+ Mush Boss) — [mush.gd](../scripts/mush.gd)
- **Has:** hit flash, hit SFX (×3), a lovely **discover cue** when a mini
  finds kin/puddle to fuse ([mush.gd:325](../scripts/mush.gd#L325)) +
  surprise art, per-tier dead art.
- **Needs:** **death SFX** (silent `_die` at
  [mush.gd:561](../scripts/mush.gd#L561)), aggro cue, *fuse & split*
  sounds (the fusion is a signature mechanic and currently silent). Attack
  lunge optional.

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
1. **Death-sound sweep** — six one-liners, whole roster gains weight in
   one sitting. (Win B.)
2. **Aggro-cue sweep** — the rising-edge flag + a sound per creature.
   Start with the wizard incantation. (Win A.)
3. **Signature-mechanic sounds** — slime split/merge, mush fuse/split,
   frogman reveal stinger, wizard/boss cast launch.
4. **Melee attack lunges** — skeleton, slime, mush (mirror the frog/toad
   `attack_anim` pattern in [frogman.gd](../scripts/frogman.gd)).

Each numbered step is independently testable and shippable — pick the one
that sounds fun today.
