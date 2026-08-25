# Threshold Deep — Stations & Boxed Props

*Drafted 2026-08-02 as a parked idea. **Built and proven 2026-08-09.**
A construction technique — walk-around 3D props built entirely from 2D face
sprites — plus the design payoff it unlocks (necromancer work stations as
authored points of interest). The technique is now shipped: three tables and
a cage exist and read as solid objects in torchlight. What remains is
placement and occupants, not feasibility. Read alongside docs/acts.md (the
necromancer throughline this serves) and the repo CLAUDE.md art specs.*

*Why its own doc and not a section of acts.md: the technique is useful
whether or not the necromancers ever get built. Tables, crates, cages,
altars, wrecked machinery — any of it. acts.md carries the pointer, the
same way it points at segmented-creatures.md.*

## The idea

A prop you can **walk around** — approach from any side and it stays
solid — built from flat sprites on the faces of a box: front, back,
left, right, and (sometimes) top. No modeling tool, no new import path,
one PNG per distinct face.

**The building block already existed in the game.** `hatch.tscn` is a
`Sprite3D` with billboarding *off*, rotated −90° on X so it lies flat on
the floor. A boxed prop is five of those, each rotated to face out.

## What's built

| Scene | Box (W×H×D) | Faces | Art |
|---|---|---|---|
| `table1.tscn` / `table2.tscn` / `table3.tscn` | 2 × 1 × 1 m | 5 | `assets/structures/tables/table<N>_{front,side,top}.png` |
| `cage1.tscn` — sits on a table | 1 × 1 × 1 m | 4 (no top) | `assets/structures/cages/cage1_{front,side}.png` |
| `cage2.tscn` — stands on the floor | 1 × 2 × 1 m | 4 (no top) | `assets/structures/cages/cage2_{front,side}.png` |

Plus two occupants — `caged_mush.tscn` and `caged_skeleton.tscn`, see below.

Tables 2 and 3 currently carry **duplicates of table1's art** — placeholders
to get placement working, to be repainted in place later.

**Separate scenes, not one scene with a variant switch.** The props are pure
data with no script, so a switch would only add machinery; and separate
scenes leave table2 free to become a different *shape* later without a
refactor. The generator picks from an array of PackedScenes.

`scenes/main.tscn` is the bench: every prop type, an occupied cage on a
table, a tall cage with a skeleton, and a floor-level small cage for
comparison. Its lights were **deleted** — the dungeon's ceiling slabs block
the directional light, so interiors are ambient plus the carried torch, and
a static overhead lamp lights all four faces equally and hides the only
thing worth testing. Its Environment mirrors `dungeon.tscn`, except
`fog_height = 0.0` because that room's walking surface is y = 0, not 0.5.

## Construction

A `StaticBody3D` with a `BoxShape3D` collider and four or five `Sprite3D`
children, each positioned at half-depth from centre and rotated to face
outward. Every face carries the hatch's settings verbatim:

```
pixel_size = 0.03125
shaded = true
alpha_cut = 1
texture_filter = 0     # nearest
# billboard left OFF — that's the whole point
```

**The node origin sits at the BASE centre**, not the box centre, so placing
one on a dungeon floor is `position.y = 0.5` and nothing else. A cage goes
on a table with `position.y = 1.0`. Skip the bottom face; nothing sees it.

Rotations as shipped (Inspector degrees): Front 0, Back Y 180, SideRight
Y −90, SideLeft Y 90, Top **X +90**.

**Lighting is what sells it, not geometry.** `shaded = true` means each
face responds to the torch *independently*: walk around a station and the
lit face changes, the front brightens as you approach, the side falls
into shadow. That per-face response is what reads as "solid object," and
it is exactly what a billboarded creature can never do. This was the
central bet and it paid — five flat quads in torchlight look far more
three-dimensional than "five flat quads" sounds, and it works *because*
the game is lit by a carried torch rather than ambient light.

**Face normals don't matter.** Sprite3D defaults to `double_sided`, so a
face whose normal points into the box is still lit correctly from outside.
Don't spend time reasoning about which way a quad faces.

## Art spec

The project has ONE texel density everywhere: **32 px = 1 m.** Creatures
are 32 px/m; tiles are 64 px across a 2 m cell — the same number. Match
it or the prop looks pasted onto the wall behind it.

**Each face canvas is the two box dimensions it spans**, and the check that
catches every mistake: three axes, three pixel counts, and **each number
must appear on exactly two canvases.** If one shows up only once, something
is crossed. For the shipped table:

| axis | metres | px | appears as |
|---|---|---|---|
| width (X) | 2 | 64 | front's width · top's width |
| depth (Z) | 1 | 32 | side's width · top's height |
| height (Y) | 1 | 32 | front's height · side's height |

**THE TOP-FACE RULE: the top canvas's UP edge is the prop's FRONT.** Under
the shipped X +90° rotation, canvas-up maps toward +Z. Draw every top the
same way round or it reads 180° off.

**Don't draw a top face for anything taller than ~1.5 m.** First-person
eye height (~1.45 m) means you only look *down* onto things below it. A
waist-high work table shows its top constantly — that's where the
experiment lives and where the top face earns its keep. A cage sitting on
a table has its lid at 2 m and never shows it; that's why a cage is two
drawings, not three.

Naming is `<prop><N>_<face>.png` — **the number goes on the noun, not the
face.** In `sprites/`, a trailing number means *animation frame*
(`skeleton_front1`/`front2`); `table_front1.png` would read as frame 1 of a
table animation. Identical faces share one PNG (the back reuses the front,
rotated 180°, which reads MIRRORED — invisible while the art is symmetric,
and the day a drawer pull lands on one end it gets its own file).

Props are **not** world-subfoldered the way tiles are. Stone masonry drifts
per act; a wooden table is a wooden table in all three worlds. One set
serves the whole demo.

## Cages are the strongest version

`alpha_cut = 1` discards transparent pixels outright, so bars drawn with
gaps let you see **through** the near face to the far face and to whatever
is inside. Confirmed on `cage1` at 39.8% opaque.

**The unplanned payoff: the bars cast real shadows.** The player's torch is
a shadow-casting light and the discarded pixels genuinely don't cast, so a
cage throws separated bar-shadows across the floor that sweep as you walk
past. Nobody designed this; it falls out of the technique. It is the single
best argument for cages as the flagship prop.

**Two cages, two jobs, and the height is the whole difference.** A 1 m cage
at floor level sits below knee height, where you see its lid and barely see
the occupant — so `cage1` goes on a table, and `cage2` is 2 m and stands on
the floor. Never the other way round: a 2 m cage on a 1 m table puts its
occupant's feet at your eye line and its lid in the ceiling.

| | footprint | spans | at eye level (~1.45 m) |
|---|---|---|---|
| `cage1` on a table | 1×1 m | 1.5 – 2.5 m | the specimen, centred |
| `cage2` on the floor | 1×1 m | 0.5 – 2.5 m | the skull — and a flat corpse a metre below still reads |

Neither needs a top face: `cage1`'s lid lands at 2 m and `cage2`'s at 2.5 m,
both above eye height.

**Occupant sizes are measured, not guessed.** A skeleton's front view is
32 px — *exactly* 1.00 m — so it fills `cage2` flush to both bars with ZERO
clearance. In practice that reads as crammed in, confirmed in play. But the
tolerance is literally zero: redraw a creature one pixel wider and it clips
through. A wizard is 1.19 m and would NOT fit; a wider cage would be needed.

**Hitting the occupant through the bars is free.** Player melee
(`player.gd`, the `get_nodes_in_group("enemies")` sweep) flattens Y
(`to.y = 0.0`) and tests distance and arc only — no raycast, no
line-of-sight. Bars don't block it because nothing blocks it, and height is
irrelevant, so a caged thing on a table is as reachable as one on the floor.

## Occupants

`scripts/caged_specimen.gd`, ONE script shared by `caged_mush.tscn` and
`caged_skeleton.tscn`. The scenes carry the frames, sounds, health, label and
pitch; the script carries the logic. Shared rather than copied because its
header holds the boss-arena soft-lock rule, and that is the last thing that
should exist in two files free to drift. **If a third specimen wants
genuinely different BEHAVIOUR, give it its own script rather than growing
another flag here.**

They are `Node3D`, not bodies — no movement, no collider, no AI. They idle on
a two-frame loop, swap to the creature's existing `*_aggro1` frame within
`NOTICE_RANGE`, take hits with the house flash-and-frame pattern, and die.

**They join `"enemies"`, and that is the only reason melee finds them.** It is
also exactly what makes the boss-arena exclusion load-bearing — see Placement.

**No `alert()` method, deliberately.** dungeon.gd's rally poll and
`_alert_around` both guard with `has_method("alert")`, so a thing with no
brain is skipped rather than crashing.

**`base_tint` and `knock_timer` exist for `dot.gd`**, which restores a host's
sprite to `base_tint` and zeroes `knock_timer` on a tick. So a caged specimen
can be set on fire, and a slime's creep will poison one through the floor —
that sweep is flat XZ, so height doesn't save it. Both read as features.

**`corpse_lies_flat` is the one flag the two disagree on.** A mush corpse is
drawn TOP-DOWN like every splat in the game and must be laid flat —
billboarded, a top-down puddle reads as a disc standing on edge. A skeleton
corpse is an upright bone pile, and `skeleton.gd` deliberately leaves its
billboard alone. Match whichever the art is.

**Kills only count as yours if you dealt them.** A Dot tick passes a null
attacker, so infighting and creep deaths don't score. `kill_label()` comes
from the scene, so the death report reads "a caged mush" properly.

## Corners: answered

This was the technique's one open question — two flat faces meeting at a
hard edge, fine head-on and feared thin at 45°. The doc's plan was to prove
it with junk art before drawing anything real.

**They hold.** Real art went straight in, the corners read as edges from
every angle, and none of the contingency fixes were needed: no matched
outermost pixel column, no deliberate 1 px dark edge. Doom and Build-engine
props lived on this trick and it still works. Consider the question closed
and don't re-litigate it.

Skipping the junk-art step was correct. Real art answers the same question
better, and one real prop derisked all the rest.

## Gotchas that cost real time

**Give `BoxShape3D` an explicit `size`.** Godot omits properties sitting at
their default, so a missing `size` line silently means (1, 1, 1) — a 2 m
table whose collision covers only the middle metre. It happened here and is
invisible, because colliders don't render. Turn on **Debug → Visible
Collision Shapes** whenever building a prop.

**The CollisionShape3D needs lifting half the height** (`position.y` = half
the box height), because the node origin is the base, not the centre.
Otherwise the collider sits half-buried in the floor.

**Never edit a `.tscn` on disk while Godot has that scene open.** The editor
owns its in-memory copy and stamps it over the file on save; hand edits land
underneath and vanish. Close the tab first. This cost most of an afternoon
being misdiagnosed as a parser bug.

**Godot strips `.tscn` comments on save.** It regenerates these files from
the in-memory scene, so any comment in a scene the editor ever saves is
gone. Scene documentation belongs in a doc or a `.gd` script, not in the
`.tscn`. (`title.tscn`'s long note about the sword tangent is one editor
save away from being lost.)

**`#` between blocks is a parse error, not a comment.** Godot's text parser
only treats `#` as a comment while reading a block's properties; between
blocks it expects `[` and reads `#` as a colour literal — `Invalid color
code: #`.

## Placement — shipped 2026-08-09

**Pathing comes free; placement does not.** Enemies already raycast
against layer 1 in `_wall_ahead`, so `_nav_dir` steers around a solid
station with no new code. But the generator proves solvability *before*
anything is placed, so a prop dropped in a doorway or corridor can wall
off the floor. **Rooms only, never doorways** — the same discipline the
pedestals follow. A table is 2 m wide, **exactly one grid cell**, so a
careless one seals a corridor outright.

`dungeon.gd` does it in three functions:

- `_place_structures()` — walks `floor_rooms` from index 1 (the spawn room
  is skipped, so nothing is in your face on arrival), excludes the arena and
  item rooms, rolls per room.
- `_place_one_structure()` — `_stone_cells` only (never wood that might
  collapse under it); a cell qualifies **only if its neighbour in that
  direction is solid wall**, which is what makes placing IN a doorway
  impossible since a doorway neighbour is floor; skips the room centre and
  the cell left of it, where `_populate` spawns the room's enemies; pushes
  the position back by half the prop's DEPTH so the back face lands on the
  wall plane and a table's 2 m width spans the cell edge to edge. Rolls a
  **tall floor cage instead of a table** at `STRUCTURE_TALL_CAGE_CHANCE` —
  the two are alternatives, since both want the same wall-adjacent cell.
- `_room_doorways()` / `_near_doorway()` — the wall test stops a prop landing
  IN a doorway but not BESIDE one, where a 2 m table narrows the way in.
  Doorways are found without knowing anything about corridor carving: the
  generator rejects any room whose `grow(1)` overlaps another, so every room
  is guaranteed a one-cell wall ring, and a ring cell that ISN'T solid is
  precisely where a corridor broke through. Clearance is **Chebyshev**, so
  the exclusion is a square and covers the diagonal approach too.
- `_position_crowded()` — one distance sweep over the dungeon's direct
  children. **Structures run LAST of all the placement passes**, which is
  why that single check covers the hatch, pedestals, mist gates, arrival
  door and the whole spawned roster without knowing any of their names. Keep
  it last.

**THE RULE THIS BUG CREATED: the wall test only knows about walls that are
walls NOW.** A table was found standing in the mouth of a revealed commoner
chamber (2026-08-11). The secret door is ordinary `wall_id` stone until the
plate fires — so it *passes* the test a prop needs, and only becomes a
doorway afterwards. The ring scan can't see it either, because
`_is_open_cell` is false at build time.

Fix: `_room_doorways` appends `secret_door` and `secret_plank` outright.
Both are known from the generator by line 362, long before placement runs at
416 — the data was always there, it just wasn't asked for. Neither has to
belong to the room being scanned; the Chebyshev check simply never matches
for a room they're nowhere near.

The plank is in that list for a different reason than the door. Furniture
already can't stand ON it (`_stone_cells` returns stone only, and the plank
is wood), but a waist-high table BESIDE it hides the only tell the secret
gives you — "pattern recognition, no spotlight" stops working if the pattern
is behind a table.

**Breakable wooden walls have the same shape of risk and are already safe by
accident:** they're `wall_wood_id`, not `wall_id`, so the wall test rejects
them and no prop ever backs onto one. Worth knowing, because it means the
protection is incidental — if that test is ever loosened to "any solid
neighbour", breaking a wooden wall would start revealing furniture.

**Anything else that turns wall into floor later must join that list.**

**A table has three states, and they're mutually exclusive by design** — a
cage owns the tabletop, so the potion roll is an `elif`. Bare, occupied by a
specimen, or stocked with supplies; each reads as a different kind of place.

The potion sits **0.2 m toward the room-facing edge**, not centred, and that
is a REACH requirement rather than a style choice: the table's own collider
holds the player 0.9 m off its centre, while the pickup's 0.6 m sphere plus
the player's 0.4 m capsule reach exactly 1.0 m. Centred, it would only
trigger for someone standing perfectly square to the table; nudged, it works
from anywhere along the front. It looks better too — a thing set down near an
edge reads more natural than one placed dead centre.

Tunables at the top of `dungeon.gd`: `STRUCTURE_ROOM_CHANCE` (0.55),
`STRUCTURE_TALL_CAGE_CHANCE` (0.3), `STRUCTURE_CAGE_CHANCE` (0.45),
`STRUCTURE_OCCUPANT_CHANCE` (0.6), `STRUCTURE_POTION_CHANCE` (0.5 of
CAGELESS tables — roughly one potion every other floor once the chain is
multiplied out), `STRUCTURE_CLEARANCE` (1.6 m), `STRUCTURE_DOOR_CLEARANCE`
(2 cells).

**`STRUCTURE_DOOR_CLEARANCE` is the one with a hidden cost.** At 2 it blocks
the doorway cell and its two lateral neighbours — a 6 m clear threshold. But
rooms are only 3×3 to 7×7, so in a small room with two doors nearly every
edge cell falls inside somebody's exclusion and the room gets no furniture at
all. That's defensible (a 2 m table in a 3 m room IS the cramped case), but
if density looks wrong, **reach for `STRUCTURE_ROOM_CHANCE` first** — the
clearance is doing its job. Dropping it to 1 is the gentler correction.

**BOSS ARENAS GET NO PROPS. This is a soft-lock rule, not a taste rule**,
and it holds for two independent reasons — either alone is sufficient, so
don't relax it because one stops applying:

1. `_drop_boss_floor` caves every arena floor cell, and anything not
   explicitly brought down is left hanging over the shaft — the same trap
   that forced corpses to be tweened and combat drops into the `"drops"`
   group.
2. Once cages get occupants, a living thing inside the arena bounds keeps
   `_arena_has_living_enemies` returning true forever and the fight never
   ends.

Item rooms are excluded too, but only out of caution about crowding the
authored pedestals. That one is cheap to revisit.

**Aftermath applies.** The repo rule is that everything answers "what
does it leave behind?" A smashed station wants a wrecked variant, which
in this scheme is just a second set of face PNGs on the same scene.

## The design payoff: stations as points of interest

A necromancer *at* a station is a different creature from a necromancer
standing in a room, and it comes nearly free from systems that already
exist. Spawn the wizard adjacent with `noticed = false`, idling toward
the machine — and the aggro startle already built (the ~0.35 s freeze,
the front-facing alert pose, the "sees you" sting) suddenly means
something it cannot mean today. It isn't a monster noticing you. It's
someone **interrupted**.

That single beat does more for the necromancer fantasy than any new
attack would, and it's a re-use of existing code rather than a system.

It also delivers what acts.md's throughline is reaching for — *"you don't
clear rooms; you follow a trail deeper."* A room with a working station
and a wizard bent over it is authored intent, not a spawn table. The
hand-made glyphs are the obvious surface treatment: etched into the
machine faces, they tie the props to the wizards without a single new
system, and they can evolve across the acts the same way the tile
appearances do.

## Parked for Act II: breakable stations

*Discussed 2026-08-10. **Not demo scope.** Recorded because the reasoning is
worth more than the feature, and because playtest feedback may promote it.*

**The observation:** it feels odd that you can't destroy a wooden work
station. You cross the room, swing at it, nothing happens, and you conclude
that's the rule — no harm done. But you shouldn't have had to ask.

**Why the instinct is right:** this game has taught, thoroughly, that **wood
gives way.** Wooden walls break to two torch hits. Wooden floors collapse
under you and drop you into a shaft. Pale planks hide the commoner secret.
Wood is the material that yields, everywhere except here. A wooden table that
shrugs off a halberd is the exception to a rule the player has already
learned in three other places.

**And it dissolves the lighting question below far more elegantly than any
glow could.** If a station breaks and something is inside it, **the MATERIAL
is the promise** — no signal needed, because the player already knows what
wood means in this dungeon. Exactly the reasoning that makes the pale plank
work: pattern recognition, no spotlight.

**Why it's not in the demo:** it's a system, not a prop change. It needs
per-prop damage tracking, break frames, a wrecked-variant face set (the
"aftermath" rule applies — a smashed station wants a second set of PNGs on
the same scene), and a decision about what falls out. The demo is shipping;
this is Act II work, when the necromancer content expands and stations start
carrying experiments worth smashing.

**The trigger to pull it forward:** if playtesters report swinging at
furniture, that's the game asking for it and it earns a place in the demo
after all. Absent that signal, it waits.

**Rough shape when it comes:** reuse the plank/wall damage vocabulary rather
than inventing one — `damage_wall` already routes melee into the GridMap, and
`wall_wooden_break1-3` / `floor_wooden_break1-3` are the established break
frames. A station is a StaticBody3D rather than a GridMap cell, so it needs
its own small `take_damage`, which is the one genuinely new piece.

## Decided against: lighting on stations

*2026-08-10. Candles on tables and wall torches near stations were both
considered and rejected. Recorded so it isn't re-litigated.*

**Light already means something specific here, and the system has no
exceptions.** 32 scenes carry a `Glow` node, nearly all at `light_energy`
0.8–0.9 and `omni_range` 3.2 — and the COLOUR encodes the class:

| colour | means |
|---|---|
| red `(1, 0.32, 0.35)` | health — potions |
| gold `(1, 0.88, 0.4)` | magic hearts |
| orange `(1, 0.45, 0.15)` | a relic crystal |
| warm white `(1, 0.88, 0.65)` | the hatch, the way down |

A glowing point in this game says **come here, take this.** A decorative
candle would be the first lie an entirely honest system has ever told:
players would cross a dark room for it and find furniture. That's the same
teaching-lie ui-language.md already rules out for plates — *"a plate means
'this is pressable'... it teaches a lie and players click it."*

Two more reasons, either sufficient on its own:

- **The dark is the point.** Ceiling slabs block the directional light so
  interiors are ambient plus the torch you carry, which is what makes the
  carried torch a verb instead of a setting. A wall sconce lights a room the
  player was supposed to reveal, and says "dungeon" rather than "someone was
  here."
- **It would flatten the cages.** The bar shadows come from ONE moving light.
  A static light beside a cage produces competing shadow sets and kills the
  sweep as you walk past — the best thing the whole technique produces.

**The version that IS legal got built instead** (`STRUCTURE_POTION_CHANCE`,
same day): an actual item on a table, glowing honestly because there is
genuinely something to take. The light stops being decoration and becomes a
true promise, which is the only form this idea could ever have taken.

**A potion, deliberately not golden hearts.** Gold is the commoner secret's
currency — three hearts behind a pale plank, on x-1 floors only — and it
stops reading as a secret's reward the moment tables hand out gold light. Red
keeps the tiers honest:

| tier | source | light |
|---|---|---|
| everyday | combat drops from kills | red |
| exploration | a potion on a station | red |
| secret | three golden hearts | gold |
| the build | pedestal relics | orange |

The same logic bounds anything added here later: **if it glows it must be
takeable, and its colour must already mean what it is.**

## When to abandon the trick

The box is right for anything box-shaped: tables, cabinets, crates,
cages, altars, plinths. It is wrong for genuinely irregular silhouettes —
tangles of pipe, spindly armatures, anything organic. Those want either
real low-poly geometry with a pixel texture, or a decision that the prop
is decor and can go back to being a single billboard. Don't force a
seven-face box to be a machine it isn't.

## Closed since the first draft

- **Corners** — held, no fix needed. See above.
- **Generator placement** — shipped, see above, including doorway clearance.
- **Cage occupants** — shipped: `caged_specimen.gd` with a mush and a
  skeleton. Killable through the bars, no AI, and no soft-lock because boss
  arenas take no props.
- **The tall cage** — `cage2.tscn`, which is where the technique's best
  shadows come from.
- **ShaderWarm's billboard-disabled config** — a `Structure` sibling now
  exists in `title.tscn`. Every other warm-up node billboards, so nothing
  covered billboard-OFF; `hatch.tscn` had quietly sat on that uncovered
  variant since long before the props existed. **Billboard mode is part of
  the material config** — that's the part that's easy to miss.

## Still open

1. **Table art variation** — tables 2 and 3 are placeholder duplicates.
   Planned direction: carved glyphs and craftsman ornamentation (banding,
   visible joinery), which is the surface treatment this doc argued for from
   the start. Two notes for whoever draws them: the **top face is the money
   surface** (you look down onto it constantly from ~1.45 m eye height and
   see the front at a glancing angle), and an **asymmetric glyph will read
   mirrored on the back**, since `Back` reuses the front texture rotated
   180°. Keep glyphs symmetric, or give the back its own PNG — a one-line
   `ExtResource` swap per table.
2. **The wizard-at-a-station beat**, which is the whole design payoff above
   and still unbuilt. Everything it needs now exists — props place themselves
   in rooms, and the aggro startle has been in `wizard.gd` all along.

*The technique is cheap and the art is the real cost — one table's worth of
drawing derisked the entire approach.*
