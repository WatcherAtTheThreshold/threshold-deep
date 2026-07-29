# Threshold Deep — The Three Descents

*Drafted 2026-07-25. **Parked, not roadmapped.** These are story and
world beats for the game beyond the demo — the shape of the descent
past world 3. The demo (worlds 1–3, victory at 3-3) ships first and
ships complete; nothing here is a demo commitment. This exists so that
if there's a sprint after the demo lands, there's something to sprint
toward — and so the beats are out of one head and into the repo.*

*Read alongside docs/roadmap.md ("The three acts" under Post-demo) and
docs/structure.md (the world/stage/boss cadence these extend).*

## The frame: three ontologies, not three difficulties

The demo already solved "depth 14 is depth 8 with more bodies" at the
floor scale — mist doors and boss cadence gave a run its shape. This
doc solves the same problem at the **act** scale.

Each act is not the dungeon with more enemies. It is a change in **what
the world is made of.** The descent is not "harder" as it goes — it is
*less like anything you understand.*

| Act | World is made of | Register |
|---|---|---|
| **I — The Dungeon** | worked stone | the game you already have |
| **II — The Deep Earth** | living earth, roots, strange geology | transformation as a rule |
| **III — The Threshold** | mist, distance, wrong geometry | the bardo meets cosmic horror |

The title *Threshold Deep* is already pointing at Act III. That's the
place the whole descent was always falling toward.

## Why the earth act is load-bearing

The tempting version skips stone → cosmic and the seam shows. Act II is
the connective tissue: it is where **transformation gets introduced as
a rule before it gets weaponized as cosmic.**

The game already has one seed of this — the mini-mush that sees a slime
puddle and *becomes* a green mush (docs/structure.md, deep-floor
flavour). That's matter changing what it is on contact. Act II is where
that stops being a single piece of flavour and becomes the theme of a
world: **things down here become other things.** Strange earth magic
takes the foreground. By the time the player reaches Act III,
transformation is a language they already read — so the cosmic version
lands as escalation, not as a non-sequitur.

## The transformation principle (the strongest move in the whole plan)

Act III's most powerful creatures are **not new.** They are the
skeleton, the slime, the mush, the frogman — *ascended and twisted into
cosmic versions of what was fought in the stone.*

The player spent worlds learning each family's verb. In the deep, they
meet a slime that has become something vast and wrong, and **the
recognition is the horror.** This is the Sprunki hook (the origin of
this whole direction): a stable, known thing undergoing corruption into
a horror version of itself that is *still recognizably the same thing.*
The recognizability is the payload. Random new monstrousness is weaker
than a familiar creature made terrible.

This is also the amalgam lesson generalized: the Skeletal Wizard
weaponizes corpses the player made. Act III weaponizes *knowledge the
player earned.* The game keeps turning what you know against you.

Practical bonus: this leans on partial redraws of existing creatures
rather than a from-scratch bestiary — same discipline as the
slime/mush turnarounds already in the parking lot. A cosmic slime is a
slime that has *become*, not a blank sheet.

### New creature *shapes*, not just skins (parked → segmented-creatures.md)

One shape worth having in the drawer for the acts: **segmented,
multi-body creatures** — a horizontal centipede, a vertical dragon,
built from many small chained billboards each with its own hitbox
(never one giant PNG). Full write-up in **docs/segmented-creatures.md**.
It belongs here because its most interesting version is the
transformation principle applied *linearly*: a **severable** segment
chain is the slime/mush split turned continuous and persistent — cut it
mid-body and it becomes two shorter things. Same grammar the player
already reads, arranged in a line. Feature-sized (a movement model + a
damage model), so it's Act II/III or mini-boss material, not demo work
— parked with the rest.

## The guardrail: cosmic horror must not break Pillar 3

**This is the one that will try to sink the act if it's not written
down.** Pillar 3 is *readable danger — you can always tell what's about
to hurt you.* Cosmic horror's native move is the opposite: *you cannot
comprehend what you are seeing.* These are in direct tension, and the
tension has to be resolved on purpose, not felt out per-encounter.

The resolution: **the horror lives in the art and the aftermath, never
in the fairness.**

- Creatures may be incomprehensible in **silhouette** and
  beautiful-wrong in **colour.**
- Their **telegraphs stay legible.** A cosmic being still winds up
  before it strikes, still glows on the interactive parts, still obeys
  "light equals meaning" (Pillar 3).
- The wrongness is what the thing *is* and what it *leaves behind* — not
  whether the fight is fair.

If Act III ever gets unfair *because unfair feels cosmic*, it has
traded the game's best pillar for a vibe. Keep the vibe in the drawing.
The player should always be able to say what killed them and why — and
still not be able to say *what it was.*

## Story beats (the shape, not the script)

The descent as a bardo — a journey through states, each a further
undoing of the self that walked in:

1. **The Dungeon (worlds 1–3, the demo).** Stone, torchlight, things
   that eat each other. Indifferent, ecological. The world has no
   morality in it — it is a place, not a punishment. *This stays true
   all the way down; that's why "hell" was the wrong frame.*

2. **The floor gives way.** Not a hatch — a *fall.* The transition into
   the Deep Earth is the game's own floor-betrayal lesson at the scale
   of a whole act. (Compare the parked 3-3 floor drop in roadmap.md —
   same instinct, bigger drop.)

3. **The Deep Earth (Act II).** Roots, wet stone, geology that behaves
   like it's alive. New tilesets. Strange earth magic — transformation
   as the world's rule. Bosses here are about *becoming*: matter that
   changes state, terrain that changes what it is. The player learns
   the grammar of transformation as a survivor, before meeting it as a
   god. Lean into cutesiness of slimes, mush and frogmen. Music shifts 
   to adventure themes, out of lament.

4. **The threshold thins.** The boundary between states starts to fail.
   Mist stops being a door and starts being *weather.* Geometry stops
   agreeing with itself. This is the seam into Act III, and it should
   feel like the world losing confidence in its own solidity.

5. **The Threshold / The Deep (Act III).** Mist and distance and wrong
   dimensions. The known creatures return transformed into cosmic
   beings — twisted, vast, recognizable. This is where the descent was
   always going. The bardo's far shore. Cutesy transforms to horror and
   music goes twisted adventure time, think techno-lament?

6. **The end (open).** What's at the bottom is deliberately unwritten
   here — an ending that is *arrival,* not just a dead boss. The bardo
   frame wants a destination. Naming it now would be guessing; the point
   of this doc is to guarantee there's a *there* to walk toward, not to
   build it in advance.

## Scope discipline (read this before touching any of it)

The bardo framing quietly wants a **narrative** — stations, a
destination, an ending with meaning. That is a lovely thing to have in
your head and a **dangerous thing to let leak into the demo.** This is
exactly the shape scope creep takes: a good idea, expanding quietly
before anything ships.

So, explicitly:

- **This doc is the parking lot for the whole back half of the game.**
  Recording it here is what *lets* it stay out of the demo. The idea is
  preserved; the commitment is not made.
- **The demo ships first, complete, at victory 3-3.** Its job is to be
  a clean, reproducible base — everything set up so a later act can be
  built *the way the demo was built* (roadmap.md: "each act is its own
  project with its own finish line, built on a polished base").
- Each act, when its turn comes, gets its own roadmap with its own
  "done when." Not before.
- The transformation principle is the highest-leverage idea in here and
  the cheapest to protect — it's redraws of known creatures, not a new
  bestiary. If any single beat survives into production first, let it be
  that one.

*The descent has a bottom now. It just isn't the demo's job to reach
it.*
