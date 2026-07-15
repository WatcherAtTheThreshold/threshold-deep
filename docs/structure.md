# Threshold Deep — Run Structure

*Plan drafted 2026-07-13. Supersedes the two-stage trigger-plate hunt.*

*Status 2026-07-16: implemented, with deliberate deviations — the
cadence became explore/item/BOSS per world (item before boss, not
after), bosses are the crown tiers of their families, and the win
currently lands at 3-3. See docs/roadmap.md for the three-act plan
that extends this.*

## The problem

The run has no shape. Floors get denser, not different — depth 14 is
depth 8 with more bodies. There is no punctuation, no arrival, and no
way to win. Backtracking (step a plate, walk back across a cleared
floor to the item) was compensating for the missing structure rather
than providing it.

The maze is worth keeping. The walk back is not.

## The fix: mist doors

A floor now has somewhere you have to **find**, marked by a wall of
rolling mist you can see down a corridor. The mist is the landmark,
the lock, and the promise. No minimap — torchlight and disorientation
are the identity, and the mist is a diegetic navigation aid.

Two mists, two rules, same grammar (**mist = commitment**):

| Mist | Room | Seals until |
|---|---|---|
| Cold / pale | Boss room | the boss is dead |
| Warm / gold | Item room | you have taken a pedestal |

The seal is **not** the door — it's the plate. The mist is always
passable inward until the fight starts, so a player can peek, back
out, heal, and return. Free good design, and it removes the
"dashed into a closing door" edge case entirely.

## Floor cadence

```
1  regular
2  BOSS       → reward: the sword
3  item
4  regular
5  BOSS
6  item
7  regular
8  BOSS       → the Skeletal Wizard; run ends in victory
```

Boss *then* item, not item then boss — the treasure is earned by the
fight, not eaten before it. Three bosses lands the arc around depth 8,
comfortably inside the depth-14 playtest record: **a completable run.**
Death is no longer the only exit.

### Hatch rules by floor type

- **Regular** — hatch as now. Explore, find it, descend.
- **Boss** — *no hatch on the floor.* The mist door is the only way
  down; the hatch spawns in the boss room when the fight ends. Finding
  the mist **is** the floor.
- **Item** — hatch and mist both present. The item is optional; the
  player may leave without it. This is the only place a real choice
  lives. Enter and the mist seals until a pedestal is taken.

This preserves the maze on every floor, gives each floor type a
different question, and deletes the dead walk.

## Boss encounters

A boss is not a horde. Each creature family has **one verb** — a boss
is that verb turned up until it becomes a puzzle, never that verb
duplicated.

The player walks into an empty, quiet arena and sees a plate on the
floor. That pause is **consent**: a moment to read the room, note the
wooden floor patches, and pick a spot. Stepping the plate starts the
fight.

### Arena design

Boss rooms have **wooden floor patches**. Collapsing them into holes
blocks bodies but not sight or orbs — so the dungeon's own mechanic
becomes the boss strategy. You destroy the terrain to deny the merge.

### Boss 1 — Large Slime (depth 2)

Splits into smalls that re-merge unless the player is close. The fight
is **positioning**, not DPS: you body-block the merge lanes or collapse
the floor beneath them. Teaches the language of the boss fights.

**Reward: the sword.** First item, earned by the first fight, on the
floor where the game stops being a treadmill.

### Boss 2 — Mega Mush (depth 5)

Already built. Splits at ≤7 into two mushes that seek each other and
re-fuse after a 4 s cooldown. **You have four seconds to kill a mush
before the boss reassembles.** Same denial language, higher pressure.

### Boss 3 — The Skeletal Wizard (depth 8)

**Phase one:** a wave of skeletons and wizards. The whole game up to
this point — you clear the room the way you have cleared a hundred
rooms.

**Phase two:** the corpses drag themselves across the floor toward the
centre and assemble. A wizard skull on a skeletal frame, ribs made of a
dozen bodies. Everything stops; let the sprites *slide*; make it slow.
The assembly is the moment, and it costs nothing but a tween.

**The player builds this boss.** Every corpse in the arena is a body
for the amalgam. Kill efficiently and it is small. Panic, over-kill,
let infighting rack up bodies, and you have fed it. Infighting stops
being a toy and becomes a trap.

There is deliberately **no way to destroy corpses.** The aftermath is
the law of the world. You cannot undo it — you can only make less of it.

It fights with both verbs: skeleton **rush** and wizard **telegraphed
orb**, alternating, so no single rhythm works. On death it falls apart
into a heap — you walk out through the wreckage of the fight you had
twice.

*Performance:* if a floor's worth of persistent billboards in one room
chugs, cap the amalgam's contribution at ~12 bodies and leave the rest
on the floor as scenery. The visual lie is fine. The feeling is what
matters.

## Deep-floor flavour: mush eats slime

**Not a boss.** A hazard, from depth 10.

A **mini-mush that sees a slime puddle goes for it** and becomes a
green mush — which can fuse into a green mega like any other. One
rule, visible, no phases.

The **startle** is the whole point: a ~0.4 s freeze, a little hop —
*it just had an idea* — and then it runs. Steal the frogman's reveal
timing. Without the tell, the mush looks broken; with it, the player
watches a mushroom think. Deep-floor players will learn to hunt the
puddles preemptively, which is exactly the texture depth 10 wants.

> **Rejected:** the fuller slime/mush ecology (green puddles on timers
> spitting new mushes until "you beat them all"). It breaks Pillar 3 —
> the player cannot see the system from inside torchlight, and the win
> condition is genuinely unclear. It is a simulation to watch in the
> editor, and soup to fight. The amalgam needs no explanation: *the
> bodies got up.* Keep cross-family interaction as flavour, not as
> structure.

## Build notes

**Art needed**
- Skeletal Wizard sprite **and its corpse** — a heap, likely its own
  asset rather than a scaled sprite.
- Mini-mush startle frames.
- Two mist tints that read as different **across a dark corridor at
  low alpha.** Two variants of the same pale wash will be
  indistinguishable in torchlight — one probably has to be strongly
  off-hue (warm gold) rather than a near neighbour. Test this early.

**Mist**
- Sprite3D plane in the corridor cell, billboard off, alpha-blended,
  scrolling UV offset. Not a sprite — a texture.

**Amalgam state machine**
- Corpses are currently inert props; some now need to become
  animatable, tweened, and consumed.
- Phase two triggers on **last enemy dead**, not a timer. Clean is
  better, and it means no corpses are being created mid-assembly.
- The seal means corpses outside the arena are trivially out of scope.

**RunState**
- `bosses_defeated`; per-floor `boss_cleared` so a reroll cannot hand
  out a second sword.
- **Decide what R does on a boss floor.** Probably disabled.

**Win report**
- The run can now end in victory. Same stats as the death report,
  different frame. It is the last thing anyone builds and the first
  thing anyone screenshots.

## Still open

Meta-progression. Pillar 2 says *"progression happens across runs
(unlocks), not within them"* and there is currently none — nothing
survives death, so run 40 has the same stakes as run 2. A `MetaState`
autoload (saved to disk, unlike `RunState`) banking kills or depth into
unlocks that enter the item pool remains the single highest-leverage
thing not yet on the roadmap. Structure first, though: this plan is
what gives a banked run something to be banked *toward*.
