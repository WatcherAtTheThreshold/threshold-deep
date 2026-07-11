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
- Balance values live as `const` at the top of scripts so playtest
  feedback is a one-number change.
- Typed GDScript: `:=` cannot infer from untyped sources (e.g.
  `get_nodes_in_group` items) — type loop vars (`for e: Node3D in ...`)
  or declare explicitly. Custom classes use `class_name` (see Player).

## Art Specs (settled — keep consistent)

| Asset type | Canvas | Rule |
|---|---|---|
| Creatures | 64×64 (small 32×32, brutes up to 96×96) | 32 px = 1 m; feet at bottom edge; front view only |
| Viewmodel (hands) | 128×128 | shown 3× nearest; art bleeds off bottom/right edges |
| UI icons (hearts etc.) | 16×16 | shown 3× (48 px) |
| Items (world pickups) | 16×16 | base at bottom edge; Area3D scenes, hover bob in code |
| Tiles (floor/wall textures) | 64×64 seamless | triplanar-mapped, repeats once per 2 m cell |

Sprites in world: `Sprite3D`, `pixel_size = 0.03125`, Y-billboard
(`billboard = 2`), `shaded = true`, `alpha_cut = 1`, nearest filtering.

Flat-on-ground sprites (hatch, slime puddle/splat): draw a top-down
view filling the canvas; placed as a Sprite3D with billboard disabled,
rotated -90° on X, ~0.03 m above the floor surface.

## Audio

- `assets/audio/sfx/` by category (`player/`, `enemies/`, `items/`).
  `.wav` preferred; Ableton `.asd` sidecars are gitignored.
- Footstep files are walking **loops**, not one-shots: scripts play
  them while the body moves and stop them when still/dead (no import
  loop flags needed). Own-player sounds are flat `AudioStreamPlayer`;
  world sounds are positional `AudioStreamPlayer3D` (max_distance 18).
- One-shots that outlive their emitter (e.g. potion pickup): spawn a
  self-freeing `AudioStreamPlayer3D` into the world.

## Layout

- `scenes/` — `dungeon.tscn` (the game, startup scene), `main.tscn`
  (CSG test room), `player.tscn`, creatures (`skeleton.tscn`,
  `wizard.tscn`, `slime.tscn`), `orb.tscn` (wizard projectile),
  `potion.tscn`, `hatch.tscn`
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
- Holes live in a second GridMap (`HoleMap`, collision layer 2):
  they block bodies (characters use `collision_mask = 3`) but not
  sight rays or orbs, which query only layer 1.
- Enemies: `CharacterBody3D` in group `"enemies"` with
  `take_damage(amount, push_dir, attacker = null)`. Damage from
  another enemy switches aggro to the attacker (Doom-style
  infighting) until that grudge target dies; only player kills
  increment `RunState.kills`. Player is in group `"player"`,
  class `Player`.
- Bestiary: **skeleton** (melee chaser, 3 HP), **wizard** (keeps
  distance, telegraphed dodgeable orb, 2 HP), **slime** (puddle →
  large 6 HP → splits at ≤3 HP into two smalls that re-merge on
  contact unless the player is within 5 m; also in group `"slimes"`
  and dissolves potions it touches; flat puddle/splat sprites).
  All leave persistent corpses and may drop potions (slimes don't).
- Player melee is a forgiving arc check against the enemies group —
  no physics areas involved.
- Input actions (`project.godot`): `move_*`, `jump`, `attack`
  (left mouse). Esc toggles mouse capture; R rerolls the dungeon.

## Testing

No test framework — playtest in editor. **F5** runs the real game
(`dungeon.tscn` is the startup scene); open `main.tscn` and press
**F6** for the controlled CSG test room. The generator prints its
ASCII blueprint to Output each run; R rerolls the current floor
without resetting the run (debug key).
