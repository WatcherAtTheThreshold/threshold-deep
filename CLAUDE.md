# Threshold Deep — Claude Code Guide

First-person 3D roguelike dungeon crawler in **Godot 4.7** (GDScript,
Forward+, Jolt physics). Inspired by The Binding of Isaac and Barony.
This is the portfolio's only Godot project — use Godot 4 idioms
(scenes, signals, typed GDScript), never web patterns.

## Working Style

- Claude hand-writes `.tscn`, `.tres`, and `.gd` files directly; Jessop
  draws pixel art and playtests. Scene files are text — edit them like
  code, keeping `load_steps` = ext_resources + sub_resources + 1.
- Commit `.uid` and `.import` sidecar files. Never commit `.godot/`.
- When an asset is renamed, update BOTH reference sites: the
  script's preloads AND the scene's `ext_resource` (the initial
  sprite texture in the .tscn). Then grep the repo for the old
  name — .gd, .tscn, .tres, and index.html can all hold paths.
- Balance values live as `const` at the top of scripts so playtest
  feedback is a one-number change.
- Typed GDScript: `:=` cannot infer from untyped sources (e.g.
  `get_nodes_in_group` items) — type loop vars (`for e: Node3D in ...`)
  or declare explicitly. Custom classes use `class_name` (see Player).
  Scripts in scenes that player.gd preloads (projectiles, pickups)
  must not declare class-level `Player`-typed members — that forms a
  preload cycle ("Parse Error: Busy"); type them CharacterBody3D and
  call dynamically. Function-body `is Player` checks are safe.

## Art Specs (settled — keep consistent)

| Asset type | Canvas | Rule |
|---|---|---|
| Creatures | 64×64 (small 32×32, brutes up to 96×96) | 32 px = 1 m; feet at bottom edge. Turnarounds: 6 drawings — front1/2, side1/2 (drawn facing LEFT; code flips for right), back1/2 — in a per-creature folder (sprites/skeleton/). The view is picked by projecting the creature's `facing` onto the camera's axes (see skeleton.gd `_update_view`); creatures without turnaround art yet stay front-only |
| Viewmodel, right hand | 256×128 (standard; legacy 128×128 still renders correctly) | shown 3× nearest; art anchors to the bottom-right corner and bleeds off the bottom + right edge, extra width sweeps inward. The code sizes to whatever canvas it's given — migrate art gradually under the same filenames |
| Viewmodel, left hand (torch) | 128×128 | bottom-left corner, own script (left_torch.gd); not part of the wide standard |
| UI icons (hearts etc.) | 16×16 | shown 3× (48 px) |
| UI text | Press Start 2P (`assets/fonts/`, OFL) | sizes in multiples of 8 (16/24/48) |
| Items (world pickups) | 16×16 | base at bottom edge; Area3D scenes, hover bob in code |
| Tiles (floor/wall textures) | 64×64 seamless | triplanar-mapped, repeats once per 2 m cell |

Sprites in world: `Sprite3D`, `pixel_size = 0.03125`, Y-billboard
(`billboard = 2`), `shaded = true`, `alpha_cut = 1`, nearest filtering.

Flat-on-ground sprites (hatch, slime puddle/splat, mush splat): draw a
top-down view filling the canvas; placed as a Sprite3D with billboard
disabled, rotated -90° on X, ~0.03 m above the floor surface.

Viewmodel is two-handed once the sword is claimed: right hand holds
the weapon (`viewmodel.gd`, bottom-right), torch moves to the left
hand (`left_torch.gd`, bottom-left, body-lean on strikes). Swing
motion values are per-weapon in `viewmodel.gd.set_sword()`.

## Audio

- `assets/audio/sfx/` by category (`player/`, `enemies/`, `items/`).
  `.wav` preferred; Ableton `.asd` sidecars are gitignored.
- Footstep files are walking **loops**, not one-shots: scripts play
  them while the body moves and stop them when still/dead (no import
  loop flags needed). Own-player sounds are flat `AudioStreamPlayer`;
  world sounds are positional `AudioStreamPlayer3D` (max_distance 18).
- One-shots that outlive their emitter (e.g. potion pickup): spawn a
  self-freeing `AudioStreamPlayer3D` into the world.
- Music: `assets/audio/music/` (mp3 is fine — Ableton can't export
  ogg; convert only if web build size matters someday). The
  `MusicDrift` autoload drifts random segments of the track in and
  out with 8 s fades and long silences, surviving reloads.

## Layout

- `scenes/` — `dungeon.tscn` (the game, startup scene), `main.tscn`
  (CSG test room), `player.tscn`, creatures (`skeleton.tscn`,
  `wizard.tscn`, `slime.tscn`, `mush.tscn`, `frogman.tscn`),
  `orb.tscn` (wizard
  projectile), pickups (`potion.tscn`, `sword_pickup.tscn`),
  `hatch.tscn`
- `scripts/` — one script per scene/system; `dungeon_generator.gd` is a
  static `class_name DungeonGenerator`
- `resources/dungeon_tiles.tres` — hand-written MeshLibrary (BoxMesh +
  BoxShape3D per tile)
- `assets/sprites/`, `assets/tiles/`, `assets/ui/` — PNGs
- `docs/roadmap.md` — vision, pillars, phased plan

## World Conventions

- GridMap `cell_size = (2, 4, 2)`: one map cell = 2×2 m, walls 4 m.
  Dungeon layouts are ASCII grids (`#` stone wall, `W` breakable
  wooden wall — two torch hits open it to floor, `.` stone floor,
  `,` wooden floor — may collapse into a hole behind the player) —
  the generator produces them, `dungeon.gd` instantiates them.
  Cell → world: `(x*2+1, y, z*2+1)`; floor walking surface is y = 0.5.
- Ceilings are slabs at grid layer y = 1 over every walkable cell
  (breaking a wooden wall must also lid the opened cell). They block
  the directional light: interiors are lit by ambient + carried torch
  only, and that darkness is intentional.
- `RunState` autoload = everything that must survive scene reloads:
  depth, kills (total + per-creature tally), damage dealt/taken,
  carried health/max health/magic hearts, sword ownership, and the
  killer's name + sprite for the death report. Descent keeps it,
  death resets it. New persistent run state belongs there.
- Health and damage are in **half-heart units**: 2 units = one HUD
  heart (full/half/empty states). Start 6 units (3 hearts), cap 16;
  magic cap 12; containers add 2, filled. Torch deals 2, all other
  weapons 4; enemy touch attacks 2 (bosses 4). When adding numbers,
  think in units, not hearts. Magic hearts absorb damage before red
  and can't be healed by potions; half potions/half heart drops
  grant 1 unit.
- Relics (flags/tiers in RunState, pedestal pool in item rooms).
  Crystals follow docs/item-plan.md (hue = family, cut = shape,
  tier = same hue bigger cut; art in assets/items/crystals/ as
  crystal_<key><tier>.png, always numbered): Fleetfoot Stone
  (speed ×1.15 / ×1.28), Rage Crystal (+1/+2 attack units), Hasty
  Little Stone (player projectile speed ×1.3 / ×1.6 AND melee
  swing rate by the same factor; ranged fire rate unchanged),
  Lucky Luck Stone (drop rolls ×0.6 — more of everything). Armor
  (Turning Stone) in two tiers — leather (25% chance a blow is
  fully turned) then steel (40%), offered as an upgrade only after
  leather; blocks flash steel-blue, no damage/invuln. Every
  build-defining pickup shows a two-line toast (hud.show_toast:
  NAME + lowercase descriptor, no numbers); combat drops don't. Weapons are UNTIERED pool items — sword, staff, and boomerang
  each appear once per run, any time, from pedestals or boss drops;
  the hand holds whichever was claimed LAST (RunState.weapon is the
  single source of truth — never branch on has_* flags for combat
  behavior, those only gate pool availability). All deal base 4;
  crystals apply to whatever is held. The staff fires a rapid orb
  along the camera aim; the boomerang pierces, hits each enemy once
  per leg, returns from walls or 9 m, one in flight at a time.
  relic_pickup.gd + `grant` method name is the pattern for new
  relics; tiered relics gate the next tier on the previous.
  Asset split: `items/` = pickup art only; `sprites/` = viewmodel
  hands + projectile frames.
- Run structure (docs/structure.md): floors read as world - stage
  (1-1, 1-2… via RunState.floor_label) with a misted title card at
  each floor start, tinted by floor kind. Each world runs
  explore (x-1) → item (x-2) → BOSS (x-3); victory at 3-3,
  continuing below for endless descent. Worlds are places: stages
  within a world connect by standing pale mist gates (mist_gate.tscn
  — walk through, the screen whitens into the next title card); only
  boss floors have a true hatch and the fall. Mist grammar:
  cold = fight, gold = bargain, pale = passage. Mist
  doors (mist_door.tscn: cold = boss, gold = item) fill a special
  room's doorways — passable until sealed. Boss floors have no
  hatch; a consent plate starts the fight, the seal drops, and the
  hatch + reward spawn on clear — the reward is ONE RANDOM DRAW
  from _relic_pool() (the same availability pool item-room
  pedestals draw two from; the sword is in the pool like anything
  else, so a swordless run is a torch run); boss 3 triggers the
  victory report. Item rooms announce on entry
  (stinger) but never seal — leaving empty-handed is respected;
  taking one pedestal (always_consume) dissolves the mist and
  removes the other. Pedestal pairs carry AT MOST ONE weapon. R is inert
  during a boss fight. Trigger-plate item hunts are retired.
- The commoner secret (x-1 floors): the generator grafts a sealed
  2×2 chamber outside walkable space (after the solvability proof —
  sealed space is invisible to it) and buries a trigger under one
  wooden plank, marked by a faint amber glimmer (the tell). That
  plank breaks to STONE + trigger plate, not void; the plate slides
  the door wall open (floor + ceiling lid + upper-band clear +
  grind sfx) onto three golden hearts. Reveal hooks live in both
  plank-death paths.
- Holes live in a second GridMap (`HoleMap`) and are **open lethal
  shafts** — no collision. A collisionless `void` tile (black slab,
  same look) sits under every wooden floor cell from build time;
  collapse swaps the plank away and the shaft is simply open.
  Falling below y = -1.5 kills the player ("the Dark Below", no
  portrait) and despawns creatures — kill credited if the player's
  shove sent them over (`last_attacker`), but the body and its
  drops are gone. **Steering respects rims, momentum doesn't**:
  every creature gates voluntary movement on a `_floor_ahead` ray
  probe (include it in new creatures), but the knock-skid window
  has no steering, so knockback can carry any staggerable creature
  into a shaft. The amalgam has no skid and cannot fall. Wooden
  floors also break under 2 damage-units of anyone's fire — and
  deliberate damage has the FINAL SAY: no guards, it can drop a
  plank under an enemy or under the player's own feet. The
  plank-that-holds rule protects only passive walk-collapse.
- Enemies: `CharacterBody3D` in group `"enemies"` with
  `take_damage(amount, push_dir, attacker = null)`. Hits stagger:
  a 0.35 s knock window where the chase logic stands down and the
  body skids under friction — steering hard-sets velocity every
  tick and would otherwise erase the knockback impulse. New
  creatures must include the knock_timer skid branch. Knockback
  scales with push_dir's length (torch passes a long vector). Damage from
  another enemy switches aggro to the attacker (Doom-style
  infighting) until that grudge target dies; only player kills count.
  Every enemy implements `kill_label()` (state-aware display name)
  and passes it to `RunState.record_kill()`; the fatal blow against
  the player records the attacker's label + current sprite for the
  death report. Player is in group `"player"`, class `Player`.
- **Aftermath is the art style**: every death and split leaves
  persistent bright residue (billboard corpses, flat splats with
  random spin + height jitter, the frogman's coat). New creatures
  and events should always answer "what does it leave behind?"
- Bestiary: **skeleton** (melee chaser, 3 HP; 15% of bone piles are
  restless — they stir when the player comes within 3.5 m after a
  4 s grace, take 1 s to rise at 2 HP, and one hit mid-rise scatters
  them for good), **wizard** (keeps
  distance, telegraphed dodgeable orb, 2 HP), **slime** (puddle with random
  1–10 s incubation → large 6 HP → splits at ≤3 HP into two smalls
  that re-merge on contact unless the player is within 5 m; in group
  `"slimes"`, dissolves potions; 15% of corpses respawn as a 2 HP
  small after 8–20 s — the splat swaps to spawn-puddle art 3 s
  before rising), **mush family** (mush 8 HP →
  two minis at ≤4; mushes actively seek visible kin to fuse with —
  grudges override; two full mushes within 1.2 m fuse into a mega —
  14 HP cap, 2-damage hits, splits back at ≤7; 4 s merge cooldown
  after any split; group `"mushes"`; mega never spawns naturally,
  reserved as a future boss), **frogman** (trenchcoat, 7 HP, depth
  3+; at ≤3 HP freezes invulnerable for a 0.7 s coat-off reveal,
  then splits one-way into a hopping frog (2 HP, lunge-rest cycle)
  and a toad (3 HP), leaving the crumpled coat behind as a prop).
  All creatures leave persistent corpses; only skeletons and wizards
  drop potions.
- Player melee is a forgiving arc check against the enemies group —
  no physics areas involved.
- Input actions (`project.godot`): `move_*`, `dash` (Space — short
  forward burst, ~1s cooldown; there is deliberately no jump),
  `attack` (left mouse). Esc toggles mouse capture; R rerolls the
  dungeon.

## Testing

**index.html** at the repo root is a sprite-and-sound gallery wired
to the live asset files — open it in a browser (double-click works,
no server needed), click any tile to animate it with its real sound
at real game timings. It's the art-review loop and the
granddaughter-friendly toybox. Its manifest is hand-written: when
wiring new sprites or sounds into the game, add them to the gallery
too.

No test framework — playtest in editor. **F5** runs the real game
(`dungeon.tscn` is the startup scene); open `main.tscn` and press
**F6** for the controlled CSG test room. The generator prints its
ASCII blueprint to Output each run; R rerolls the current floor
without resetting the run (debug key).
