# Threshold Deep — Stations & Boxed Props

*Drafted 2026-08-02. **Parked, not roadmapped.** A construction
technique — walk-around 3D props built entirely from 2D face sprites —
plus the design payoff it unlocks (necromancer work stations as authored
points of interest). Captured so it's out of one head and in the repo.
Not a demo commitment. Read alongside docs/acts.md (the necromancer
throughline this serves) and the repo CLAUDE.md art specs.*

*Why its own doc and not a section of acts.md: the technique is useful
whether or not the necromancers ever get built. Tables, crates, cages,
altars, wrecked machinery — any of it. acts.md carries the pointer, the
same way it points at segmented-creatures.md.*

## The idea

A prop you can **walk around** — approach from any side and it stays
solid — built from five flat sprites on the faces of a box: front, back,
left, right, top. No modeling tool, no new import path, one PNG per face.

**The building block already exists in the game.** `hatch.tscn` is a
`Sprite3D` with billboarding *off*, rotated −90° on X so it lies flat on
the floor. A boxed prop is five of those, each rotated to face out.

## Construction

A `StaticBody3D` with a `BoxShape3D` collider and five `Sprite3D`
children, each positioned at half-depth from centre and rotated to face
outward. Every face carries the hatch's settings verbatim:

```
pixel_size = 0.03125
shaded = true
alpha_cut = 1
texture_filter = 0     # nearest
# billboard left OFF — that's the whole point
```

Skip the bottom face. Nothing ever sees it.

**Lighting is what sells it, not geometry.** `shaded = true` means each
face responds to the torch *independently*: walk around a station and the
lit face changes, the front brightens as you approach, the side falls
into shadow. That per-face response is what reads as "solid object," and
it is exactly what a billboarded creature can never do. Five flat quads
in torchlight look far more three-dimensional than "five flat quads"
sounds — this is the entire reason the trick works, and it works *because*
the game is lit by a carried torch rather than ambient light.

## Art spec

The project has ONE texel density everywhere: **32 px = 1 m.** Creatures
are 32 px/m; tiles are 64 px across a 2 m cell — the same number. Match
it or the prop looks pasted onto the wall behind it. A face canvas is
`32 × its size in metres`:

| Prop | Size | Face canvas |
|---|---|---|
| Work table | 2 m × 1 m | 64 × 32 |
| Tall machine / cabinet | 2 m × 2 m | 64 × 64 |
| Small apparatus | 1 m × 1 m | 32 × 32 |

**Don't draw a top face for anything taller than ~1.5 m.** First-person
eye height means you only look *down* onto things below eye level. A
waist-high work table shows its top constantly — that's where the
experiment lives and where the top face earns its keep. A 2 m cabinet
never shows its top at all; the sides do all the work.

## Cages are the strongest version

`alpha_cut = 1` discards transparent pixels outright, so bars drawn with
gaps let you see **through** the near face to the far face and to
whatever is inside. Four cutout sides plus an ordinary billboard creature
suspended in the middle gets a real cage with something alive in it — and
the billboard inside keeps turning to face you while the bars correctly
do not. That composition is the best thing this technique can do.

## The one weak spot: corners

Two flat faces meeting at a hard edge is fine head-on and thin at 45°.
Cheapest fixes: make the front art's outermost pixel column match the
side art's, or give both a deliberate 1 px dark edge so the corner reads
as an intentional edge rather than a seam. Doom and Build-engine props
lived on this trick — it holds up, but the corner is where it shows.

**Test this with junk art before drawing a real machine.** It's the only
open question in the whole approach, and a grey box with numbered faces
answers it in five minutes.

## Two practical gotchas

**Pathing comes free; placement does not.** Enemies already raycast
against layer 1 in `_wall_ahead`, so `_nav_dir` steers around a solid
station with no new code. But the generator proves solvability *before*
anything is placed, so a prop dropped in a doorway or corridor can wall
off the floor. **Rooms only, never doorways** — the same discipline the
pedestals follow.

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

## When to abandon the trick

The box is right for anything box-shaped: tables, cabinets, crates,
cages, altars, plinths. It is wrong for genuinely irregular silhouettes —
tangles of pipe, spindly armatures, anything organic. Those want either
real low-poly geometry with a pixel texture, or a decision that the prop
is decor and can go back to being a single billboard. Don't force a
seven-face box to be a machine it isn't.

## Smallest slice, when its turn comes

1. Hand-write `station.tscn` — five faces, placeholder art, box collider.
2. Walk around it in `main.tscn` (the CSG test room) with the torch.
   Judge the corners and the per-face lighting; that's the whole
   feasibility question answered.
3. Only then draw one real prop — a work table, since its top face is
   visible and it's the shape most likely to carry an experiment.
4. Station-as-spawn-point last, and only once a necromancer exists to
   stand at it.

*The technique is cheap and the art is the real cost. Prove the corners
with junk first.*
