# Threshold Deep — Level Gen Fix: Collapse Solvability

*Drafted 2026-07-13. Implemented 2026-07-13 (all-at-once strictness;
flood source is the player spawn so boss floors without hatches are
covered; hatch/trigger cells are additionally hardened to stone at
placement so key objects never hover over holes).*

## The problem

Wooden floor patches sometimes sit in a doorway. When they collapse,
they can seal the player into a room or cut off the hatch. It doesn't
happen every floor, but often enough that `R` (the debug reroll) has
quietly become a real mechanic.

## Rejected: the mirror

The tempting fix is to make the reroll diegetic — a mirror that
"restarts the floor's reality." Don't. Players will read it as exactly
what it is: a bug with a story on it. Worse, an escape hatch is a
free exit from any encounter the player is losing, which quietly guts
the boss floors — walk into the mist, get hurt, mirror out.

**A game with no escape hatch is a game that trusts itself.** Fix the
generator instead.

## The insight

We are solving the wrong problem. Collapses are player-triggered and
one-way, so the invariant is **not** "the dungeon must always be
traversable at runtime." It is:

> **A hole must never be the thing that severs the graph.**

Which is checkable at **generation time**, before a single tile has
fallen. No runtime pathfinding, no rescue mechanic, no repair.

## The rule

At generation, after the layout is built:

1. Take the set of wooden floor cells (`,`).
2. **Remove all of them at once** — treat every one as already a hole.
3. **Treat breakable wooden walls (`W`) as passable.**
4. Flood-fill from the hatch. Is every walkable cell still reachable?
5. If not, demote wooden floor cells to stone (`.`) until it is.

If the dungeon is fully traversable in the **worst case** — every
wooden cell collapsed, breakable walls as doors — then **no sequence of
collapses can ever trap the player.** One flood-fill, at generation,
and the problem is provably gone.

## Why breakable walls must count as passable

This is the part that preserves the design.

A corridor **can** be severed by a hole — as long as a wooden wall
offers a way around. The wall is the guarantee. So the interesting
scenario — *"the floor collapsed behind me and now my only way out is
to break through"* — isn't merely still legal. It becomes the **reason
holes are allowed in tight spots at all.**

We are not removing that moment. We are making it the only moment.

## Notes on strictness

Removing *all* wooden cells simultaneously is stricter than strictly
necessary, and it will thin the wooden floors somewhat.

**Start there anyway.** It is one flood-fill and it is provably safe.

If floors end up too sparse, relax to a per-cell **articulation point**
check: for each wooden cell, flood-fill with only that cell removed. It
yields more wooden floor, but accepts a rare edge case — two individually
safe patches that bracket a corridor and cut it *together*. The
all-at-once check has no such gap.

Either way the cost is trivial: a few hundred cells, a few dozen
candidates, once per floor.

## Consequences

- **`R` leaves the release build.** It stays as a debug key. Once the
  generator cannot trap you, the escape hatch is dead weight — and
  removing it closes the boss-room exploit before it exists.
- **Mist doors are protected for free.** A boss room whose approach
  corridor collapses would be a far worse bug than a stranded player.
  The same check fixes both.
- The generator's ASCII blueprint print is the natural place to verify
  this: log a warning if any wooden cell had to be demoted, so unusual
  layouts are visible during playtesting rather than silent.
