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

## Where we are (2026-07-10)

Core loop complete and pushed: procedural dungeons (rooms +
L-corridors → GridMap), textured tiles, FPS controller with carried
torch, animated skeletons with line-of-sight chase and touch attacks,
torch-swing melee, hearts HUD, corpses, death → new run.

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

### Phase 3 — Bestiary ✅ 2026-07-10 (wizard: ranged, retreating, telegraphed casts; corpse art pending)
- **Second creature** with a different verb — e.g. a ranged spitter
  (projectile sprite) or a fast fragile rat. *Art: 64×64 or 32×32
  creature, 2 frames + corpse.*
- **Spawn tables by depth.**
- *Done when: seeing a room's occupants changes how you enter it.*

### Phase 4 — Things to find
- **Items**: torch upgrades (light radius), weapons (swing arc/damage),
  Isaac-style stat trinkets. *Art: 32×32 item sprites.*
- **Pedestal rooms** in the generator (special room type).
- *Done when: two runs feel different because of what you found.*

### Phase 5 — Juice
- Sound (footsteps, swing, hits, ambient drips), torch flicker,
  screen-shake on hits, main menu, pause.
- *Done when: someone else plays it without you explaining anything.*

## Parking lot (ideas, not commitments)

- 4/8-directional creature sprites (Doom-style)
- Doors, keys, locked treasure rooms
- Bosses every N floors
- Minimap from the ASCII grid
- Web export for the portfolio site — **validated 2026-07-10**: runs in
  browser via the single-threaded Web preset; web builds use the
  Compatibility renderer (`rendering_method.web` override), desktop
  stays Forward+. Deploy whenever wanted.
