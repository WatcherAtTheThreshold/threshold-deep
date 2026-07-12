# Threshold Deep — Roadmap

## Vision

A first-person dungeon crawler where every creature, item, and wall is
hand-drawn pixel art living in a real 3D space — Doom's presentation,
Isaac's run structure, Barony's dungeon feel. Runs are short, deaths
are cheap, and the dungeon is different every time.

## Pillars (test every feature against these)

1. **The art is the game.** Billboarded drawings in torchlight are the
   identity — no feature is worth breaking that look.
2. **Runs, not saves.** Death rerolls the world. Progression happens
   across runs (unlocks), not within them.
3. **Readable danger.** You can always tell what's about to hurt you —
   slow enemies, visible telegraphs, forgiving melee.

## Where we are (2026-07-12)

Full run loop, live: procedural dungeons (rooms + L-corridors →
GridMap) with stone and wooden tiles under stone ceilings — torch-lit
interiors, wooden walls break open into shortcuts (two hits), wooden
floors collapse into impassable holes behind you. Five creature
families, each with its own verb: skeleton (rush), wizard (ranged,
telegraphed), slime (splits down, re-merges), mush (fuses up into
emergent megas, actively seeks kin), frogman (two frogs in a
trenchcoat — coat-off reveal, then a hopping frog and a toad).
Doom-style infighting. The signature look: every death and split
leaves persistent bright residue — corpses, splats, puddles, a
crumpled coat — battle aftermath accumulating on drab stone.
Torch/sword jab attacks (pull down, piston back), the sword as first
Item, hatch descent with depth scaling and carried health/gear,
dash instead of jump. Death report: killer portrait and name, depth,
kills, damage dealt/taken, per-creature tally, held 4 s. UI text in
Press Start 2P. Audio: per-creature positional footstep loops,
potion pickup, orb flight. Web export validated. Playtest record:
depth 14, 123 kills.

## Phases

Each phase is independently shippable and playtestable.

### Phase 1 — Staying alive is interesting ✅ 2026-07-10
- **Health pickups**: hearts dropped by skeletons (chance) or found in
  rooms. *Art: 16×16 world-heart or potion sprite.*
- **Score/depth counter** on the HUD: kills this run, or floor number
  once stairs exist.
- *Done when: a careful player survives noticeably longer than a
  reckless one.*

### Phase 2 — Descent ✅ 2026-07-10 (incl. on-screen death summary + floor-transition fades)
- **Stairs down** placed in the room farthest from spawn; walking in
  generates the next floor. *Art: 64×64 stairwell/hole sprite or tile.*
- **Depth scaling**: more/faster/tougher skeletons per floor.
- **Run summary on death**: floors reached, kills.
- *Done when: "how deep did you get?" is a meaningful question.*

### Phase 3 — Bestiary ✅ 2026-07-10/11
- **Wizard** (2026-07-10): keeps distance, telegraphed dodgeable orbs,
  full art including corpse.
- **Slime** (2026-07-11): puddle spawn → large → splits at half
  health → smalls re-merge unless the player is close; eats potions;
  first 32×32 creature.
- **Spawn tables by depth**; monster infighting with grudge aggro.
- **Mush family** (2026-07-11): mush splits into two minis at half
  health; two full mushes that meet fuse into a mega mush (splits
  back into mushes when hurt; 4s re-merge cooldown after any split).
  Mega never spawns naturally — reserved as a future boss. Mush
  spawn rate climbs with depth, so deep floors breed megas.
- **Frogman** (2026-07-12): two frogs in a trenchcoat. Melee chaser;
  at low HP an invulnerable 0.7 s coat-off reveal, then splits
  one-way into a hopping frog and a toad, leaving the crumpled coat
  on the floor. Depth 3+. Full art including corpses.
- *Done when: seeing a room's occupants changes how you enter it.* ✓

### Phase 4 — Things to find (started 2026-07-11: sword)
- **Sword** ✅: two-stage hunt — step on a trigger plate to summon
  the sword elsewhere on the floor (a fresh plate spawns each floor
  until claimed, per run). 2 damage, planted-in-stone pickup, moves
  the torch to the left hand; two-handed viewmodel.
- **Heart economy** ✅ (2026-07-12): start at 3 containers (cap 8);
  1-up plates grant a filled container, magic plates grant 3 yellow
  hearts (cap 6) that absorb damage first and can't be healed. One
  trigger plate per floor: sword until claimed, then 65% magic /
  35% container.
- **Items**: torch upgrades (light radius), weapons (swing arc/damage),
  Isaac-style stat trinkets. *Art: 32×32 item sprites.*
- **Pedestal rooms** in the generator (special room type) — future
  home of the choice chamber: all plates in one room, picking one
  seals the others.
- *Done when: two runs feel different because of what you found.*

### Phase 5 — Juice (started 2026-07-11)
- **Footsteps** ✅ (player flat loop; enemies/slimes positional 3D,
  slime pitch by size), **potion pickup** ✅, **orb flight** ✅.
- **Pixel UI font** ✅ (Press Start 2P, bundled + OFL).
- **Death report** ✅ (killer portrait/name, damage dealt/taken,
  per-creature kill tally).
- Remaining sound: swing, hits, wooden wall crack/break, floor
  collapse, mush merge/split, frogman reveal, ambient drips.
- Torch flicker, screen-shake on hits, main menu, pause.
- *Done when: someone else plays it without you explaining anything.*

### Interlude — the dungeon fights back ✅ 2026-07-11 (unplanned, Jessop's design)

Breakable wooden walls (guaranteed shortcuts), wooden floor patches
that collapse into holes behind the player, holes as a "wall you can
see over" (block bodies, not sight or orbs). Stone ceilings over
every walkable cell — interiors lit by torch and ambient only.
Jump removed in favor of a short dash (Space, ~1s cooldown) for a
grounded, heavy underground feel.

## Parking lot (ideas, not commitments)

- 4/8-directional creature sprites (Doom-style)
- Doors, keys, locked treasure rooms
- Bosses every N floors
- Minimap from the ASCII grid
- Fall-in state for holes (pits/lava/spikes — the collision-layer
  plumbing already supports it)
- Web export for the portfolio site — **validated 2026-07-10**: runs in
  browser via the single-threaded Web preset; web builds use the
  Compatibility renderer (`rendering_method.web` override), desktop
  stays Forward+. Deploy whenever wanted.
