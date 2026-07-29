# Threshold Deep — Segmented Creatures

*Drafted 2026-07-29. **Parked, not roadmapped.** A creature *archetype*
— multi-body chained enemies (a horizontal centipede, a vertical
dragon) — captured so it's out of one head and in the repo. This is
feature-sized post-demo / act content, not a demo commitment. Read
alongside docs/acts.md (the transformation principle this extends) and
the repo CLAUDE.md bestiary/creature conventions.*

## The idea

A large creature built from **many small billboards chained together**,
each with its own hitbox — instead of one enormous PNG that spans the
whole body. A giant single billboard reads as exactly what it is: a
flat card that pivots to face you as one rigid slab, and it gets worse
the bigger it is. Composing the body from small segments — each
Y-billboarding at the camera *independently*, each at a different point
on a curve — is what buys "big **and** alive." It also makes the art a
reusable small piece (one body-link sprite, repeated N times), not a
bespoke giant.

Two shapes, same mechanism:

- **Horizontal — the centipede.** A head leads; body links trail behind
  it and undulate.
- **Vertical — the dragon.** Segments stack *upward* (the game is true
  3D with real Y-stacking — same verticality the boss chamber uses):
  base on the floor, neck links rising, head on top, rearing and
  swaying.

## How it works (the enabling trick)

**A position history.** One node is the "brain" — a normal
`CharacterBody3D` in group `"enemies"` that does the AI, pathing, and
the `_floor_ahead` probing every creature already has. Each frame it
records where it has been. Body segments just **sample that trail a
fixed distance back**: segment 2 sits where the head was N steps ago,
segment 3 at 2N, and so on.

That's the whole centipede. The undulation comes *for free* — the body
traces the head's winding path, so it curves and ripples with no
bespoke animation. And because the followers only ever stand where the
head already walked, they **inherit safe footing automatically** (no
rim-steering headaches for the tail; the head's probe did the work).

The dragon is the same logic on the vertical axis — segments follow a
target/curve upward rather than a floor trail; the head leads, the neck
sways behind it.

## Hitboxes plug into the existing melee for free

Player melee is **not** a physics interaction — it's a forgiving arc
check against the `"enemies"` group (see `player.gd _attack`). So if
each segment is its own node **in that group**, the existing swing
already hits whichever link is in reach. No new targeting system. Each
segment gets the usual `take_damage(amount, push_dir, attacker)`.

That opens the one real design fork:

- **Shared health** — hitting any segment damages the one creature;
  segments are reach + spectacle, and it dies as a unit. Simple; a fine
  first version.
- **Severable segments** — each link has its own health, and cutting
  the body *matters* (kill the head, or sever the middle). This is just
  the **slime/mush split turned linear and persistent**: a slime bursts
  into separate blobs; a centipede is blobs that stay chained — cut it
  mid-body and you get two shorter centipedes, or a thrashing tail. It
  lands squarely on the game's aftermath + transformation pillars, so
  it reads as the game's own grammar extended, not a foreign system.

## Edge cases to decide up front

- **Knockback.** A rigid chain and a shove don't obviously mix. Likely:
  shove the head and let the body trail, or make segments
  knock-resistant (the amalgam already precedents "no skid"). Decide
  before building, not per-encounter.
- **Pits.** A centipede draped over a hole is either a gorgeous
  sag-into-the-dark moment or a simulation rabbit hole, depending how
  much body physics you want. The safe default: the head obeys the
  floor probe (never walks a segment over open air) and the body,
  following the head's proven trail, never ends up over a pit either.
- **Turnarounds.** The head wants the normal front/side/back turnaround
  treatment; symmetrical body links may not need views at all
  (a segment looks the same from most angles), which keeps the art cost
  down.

## Scope

Feature-sized — a new **movement model** (trail/chain following) plus a
**damage model** (shared vs severable), not a tweak. Not demo work.
Natural fit as **Act II / III content or a mini-boss** — a known thing
made stranger, exactly the direction acts.md points at (a cosmic
centipede that's really one segment repeated, severable, is on-theme).
Park it here; when its turn comes it gets its own small "done when,"
built on the polished base like every other act piece.
