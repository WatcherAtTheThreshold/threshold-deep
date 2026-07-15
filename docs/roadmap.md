# Threshold Deep — Roadmap

*Rewritten 2026-07-16. Supersedes the phase-era roadmap and folds in
docs/structure.md (implemented) and the item/act plans.*

## Vision

A first-person dungeon crawler where every creature, item, wall, and
song is hand-made — Doom's presentation, Isaac's run structure,
Barony's dungeon feel. Runs are short, deaths are cheap, the dungeon
is different every time, and a full run is a three-act descent with
a real ending.

## Pillars (test every feature against these)

1. **The art is the game.** Billboarded drawings in torchlight are
   the identity — no feature is worth breaking that look.
2. **Runs, not saves.** Death rerolls the world. Progression happens
   across runs (unlocks), not within them.
3. **Readable danger.** You can always tell what's about to hurt you —
   telegraphs, tells, glows. Light equals meaning: everything
   interactive glows, nothing decorative does.
4. **Aftermath is the art style.** Every death, split, and choice
   leaves persistent bright residue. The dungeon remembers.

## Where we are (2026-07-16)

A completable game. Worlds read as x-1 / x-2 / x-3 (explore → item
room → boss) with misted title cards; victory at 3-3, endless below.
Five creature families with distinct verbs, infighting, grudges, and
different afterlives (bones rise, goo respawns, mushes get eaten,
flesh stays down). Boss tiers cascade (Slime Boss → larges → smalls;
Mush Boss → megas → mushes → minis; the Skeletal Wizard assembles
from the corpses the player made). Weapon fork: sword → staff or
boomerang. Relics: boots, two armor tiers, heart economy (3 red
start, cap 8; magic hearts absorb first). Wooden walls break (melee
and orbs), wooden floors collapse into wall-deep shafts, provably
never trapping the player. Original three-song score drifts in and
out; per-creature positional footsteps; per-item pickup voices;
floor stingers; door-lock and mist sounds. Death report with killer
portrait; the fall between floors. Web export validated.

## Next: the item wave

Planned items (art incoming), with the system each touches:

1. **Strength** — +hit damage (`attack_damage` modifier).
2. **Dex** — better dash: longer or faster (dash constants).
3. **Double Dash** — two dash charges before the cooldown.
4. **Shot Speed Up** — faster staff orbs / boomerang flight
   (needs per-projectile speed vars, currently consts).
5. **Halberd** — longer melee reach (melee-weapon upgrade or third
   rival; decide when art exists).
6. **Hole-strider** — pass over single holes (movement/collision
   trick; design open).
7. **Sands of Time** — enemies slowed (global enemy speed factor
   all creatures read).
8. **Luck** — more golden heart drops (drop-chance modifier; could
   grow into a general luck stat).
9. **Splash Damage** — hits damage adjacent enemies.

### Damage rework (prerequisite for the wave)

Weapons should feel equal-but-different so item pools stay random:
damage-modifying items only work if damage has room to gradiate.
**Plan: half-heart internal units** — multiply every HP and damage
number by 2 and let "1" mean half a heart. Integers stay integers
(no float damage), the HUD needs half-heart states (art: half-full
red and magic hearts), and items like Strength can add +1 (half a
heart) without breaking the economy. Enemy HP re-tuned in the same
pass so current feel is preserved as the baseline.

## Secret rooms

Two kinds, sharing the sliding-wall reveal (sfx: wall grinding open):

- **The commoner** — always discoverable. A collapsed wooden tile
  can expose a floor trigger (or a lever in a revealed alcove);
  activating it slides open a wall section. Prize: golden hearts or
  a modest treasure.
- **The trial** — only discoverable while **no red-heart damage has
  been taken this floor**; take red damage before finding it and the
  chance is gone. Prize: a special fight, then an item.
- The synergy is the design: finding the commoner's golden hearts
  armors you in yellow, which protects your red hearts, which keeps
  the trial findable. One secret feeds the other.
- Needs: per-floor red-damage tracking in RunState, sliding-wall
  door (GridMap cell swap + sfx + maybe a tween), lever art,
  secret-room generation (a sealed room the main proof ignores,
  connected only by the hidden door).

## The three acts

Repeat the world pattern to three chapters — victory at 9-3:

- **Act structure**: each act = three worlds (explore/item/boss ×3)
  ending in a Skeletal-Wizard-tier finale. Acts 2 and 3 need:
  **two new mini-bosses** (Slime Boss / Mush Boss tier) and
  **two new act-final bosses** (Skeletal Wizard tier).
- **Environment changes per act**: new floor/wall/ceiling textures
  (triplanar makes a reskin = three 64×64 tiles), possibly bigger
  grids and rooms deeper down.
- Spawn tables, escalation curves, and music can also shift per act.
- Open question: whether acts 2/3 reuse the existing mini-bosses in
  harder forms or field entirely new ones — decide when the new
  bestiary art starts arriving.

## Sound wishlist (mic era)

Bone rattle (the rise), swing/hit, wooden wall crack + break, floor
collapse, mush merge/split squelch, frogman reveal fwump, boomerang
whirr + catch slap, descending A-minor fall stinger, amalgam
assembly (or its deliberate silence), secret-wall grind, ambient
drips.

## Parking lot (ideas, not commitments)

- **Meta-progression** — still the highest-leverage missing system:
  a MetaState saved to disk banking runs into unlocks that enter
  the item pool. Structure now exists for it to feed.
- Fall-in hole state (pits/lava/spikes — collision plumbing ready)
- 4/8-directional creature sprites (Doom-style)
- Doors, keys, locked treasure rooms
- Minimap from the ASCII grid
- Full-shroud mist room (aesthetic variant, shader ready)
- Web deploy to the portfolio site (validated, deploy whenever)
