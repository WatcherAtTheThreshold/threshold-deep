# Threshold Deep — Tile Appearances

*Drafted 2026-07-28, settled 2026-07-29. How each world gets its own
look without baking demo numbering into the filesystem — set up now,
before Act II and Act III triple the count. Companion to
docs/start-screen-and-act-data.md (the act-data refactor this feeds)
and docs/roadmap.md (per-act reskins under "The three acts").*

## Vocabulary (so this never fogs up again)

| Word | Is the… | Example | How many |
|---|---|---|---|
| **world** | first label number | the `1` in `1-2` | 9 in the whole game — 3 per act |
| **stage** | second label number | the `2` in `1-2` | 3 per world |
| **act** | a group of 3 worlds | Act I = worlds 1-3 | 3 |

`RunState.world(depth)` returns 1/2/3/…; `RunState.stage(depth)`
returns 1/2/3.

## The model: one look per WORLD

A tileset's granularity is **one per world.** All three stages of a
world share it — `1-1`, `1-2`, `1-3` all pull world 1's tiles; every
`2-x` pulls world 2's. So the whole game is **9 world-looks**, and the
**demo is 3** — the worlds of Act I.

You are **not** making a "level 1 tileset." You are making an
**appearance** — a family of tiles with a look — and a world *points*
at one. The demo points worlds 1 / 2 / 3 at three appearances. Later,
any world in any act points at any appearance, and nothing is renamed.

**Act I's three appearances (the demo):**

```
world 1 (1-x) → assets/tiles/dry/    (start here; the base)
world 2 (2-x) → assets/tiles/damp/
world 3 (3-x) → assets/tiles/deep/
```

Still worked stone — Act I is "The Dungeon" — but drifting drier →
damper → deeper as the act descends. Names describe the *look*, never
a number; Act II and Act III worlds get their own descriptively-named
folders (`mossy/`, `scorched/`, whatever the theme is) **when those
acts are built** — not now. You only name what you paint.

**Deferred (not the demo):** a finer *within-world* drift, where `1-1`
differs from `1-3`. The same mechanism does it for free — key the
lookup on `(world, stage)` and split a folder into three — but the demo
holds one flat look per world. Don't build it until a world asks for it.

## The one rule that makes it work: filenames are a contract

**The folder is the only thing allowed to differ. The filenames inside
are fixed and identical across every folder.**

```
dry/floor_stone.png    damp/floor_stone.png    deep/floor_stone.png
dry/wall_stone.png     damp/wall_stone.png     deep/wall_stone.png
   …                        …                        …
```

A world says "point at `deep/`" and everything resolves because the
names match. The moment one filename drifts between folders, the swap
silently breaks for that tile. Same discipline as the creature
turnaround convention (front1/front2/side1… identical across every
`sprites/<creature>/` folder) — the swap is a directory pointer, so the
names underneath can't move.

**The canonical filename list (the contract), 8 environment textures:**

```
floor_stone.png    wall_stone.png      ceiling_stone.png
floor_wooden.png   wall_wooden.png     wall_wooden_partially_broken.png
wall_stone_upper1.png   wall_stone_upper2.png
```

When you add a tile to the contract, add it to *every* folder in the
same commit (same "update both reference sites" rule as renaming a
sprite). `floor_wood_pale` needs **no** file — it reuses
`floor_wooden.png` and keeps its own cool tint in the material. Break
frames, hole rims, hatch, and triggers are effects/props, deliberately
**out** of the contract (shared across worlds) — add them later if you
want per-world rubble.

## What swaps and what doesn't

The appearance is the **texture** layer only. The geometry contract
underneath stays put:

- **Swaps per world:** which `assets/tiles/<appearance>/` textures the
  shared tile materials load into their `albedo_texture`.
- **Never swaps:** `resources/dungeon_tiles.tres` (the MeshLibrary —
  BoxMesh + BoxShape3D + one StandardMaterial3D per surface) and the
  tile *keys* the generator emits (`floor_wood_pale`, `wall_fill`,
  `void`, the ASCII grid characters). The dungeon still generates the
  same `#/W/./,` layout; only the paint on the boxes changes.

So a world-swap never touches generation, collision, or the ASCII
blueprint — it re-skins. That's what keeps it safe to expand ×3 for the
later acts.

## The wiring (implemented — the stopgap)

Live in `dungeon.gd`:

- `WORLD_APPEARANCE := ["dry", "dry", "damp", "deep"]` — index by
  world; `[0]` and worlds past the demo (endless descent) clamp to the
  nearest built look.
- `APPEARANCE_TEXTURES` — the `{tile-material-name: filename}` contract map.
- `_apply_appearance(world)` — called from `_ready` at every floor load;
  reskins each shared material's `albedo_texture` from the world's
  folder (`ResourceLoader.exists` guarded, so a missing file just leaves
  the current paint). Reapplied per floor, so it's always correct and
  never leaks between worlds.

Adding a world's look = drop a folder of PNGs + one array entry. The
real home for the `world → folder` map is the act-data refactor
(start-screen-and-act-data.md): `resources/acts/act_1.tres` wants to
hold the tileset reference and `ActRegistry.get(world)` hands the
generator what to load — at which point the `WORLD_APPEARANCE` array
becomes a field in a `.tres` and adding an act is *writing a resource
and drawing PNGs*, zero code branching. Don't build the registry for
the demo; the array is a five-minute swap into it later.

## Build order

1. **Done:** `dry/ damp/ deep/` created as identical copies of the
   current tiles; `_apply_appearance` wired. Identical folders ⇒ the
   game looks exactly as before ⇒ the mechanism is proven with zero art.
   *(Open the editor once so Godot imports the new PNGs before playing.)*
2. Get `dry/` (world 1, the base) reading right in torchlight. This is
   the shot — judge it before drifting anything.
3. Drift `damp/` then `deep/` from the base by hand. Test each at low
   light; contrast that reads in the editor can vanish in the dark (same
   early-test rule as the mist tints).
4. Act II/III worlds: **not now.** New folders + new PNGs against the
   same filename contract + array entries — never new branches.
5. When the act-data refactor happens, move `WORLD_APPEARANCE` into the
   `.tres`. Folders and filenames don't change — only where the pointer
   lives.

## Done when

- Worlds 1, 2, 3 each read as their own place.
- Swapping a world's look is one folder + one array entry — no filename
  touched, no generator code touched.
- Adding Act II/III worlds later means new folders + PNGs against the
  same contract, not new branches.

## Scope guard

This step is *re-skinning*, nothing more. If it starts wanting new tile
*types*, new collision, or generation changes, that's a different task —
park it. The demo ships at 3-3 with three looks; the machinery just has
to not fight Act II when it comes.
