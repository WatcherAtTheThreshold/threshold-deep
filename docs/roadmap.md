# Threshold Deep — Roadmap

*Rewritten 2026-07-17. Supersedes the three-act roadmap: the game we
have IS the game — now it gets finished. Acts 2 and 3 become their
own iterations after the demo ships, built the same way this one was.*

## Vision

A first-person dungeon crawler where every creature, item, wall, and
song is hand-made — Doom's presentation, Isaac's run structure,
Barony's dungeon feel. Runs are short, deaths are cheap, the dungeon
is different every time, and a run has a real ending.

## Pillars (test every feature against these)

1. **The art is the game.** Billboarded drawings in torchlight are
   the identity — no feature is worth breaking that look.
2. **Runs, not saves.** Death rerolls the world. Progression happens
   across runs (unlocks), not within them.
3. **Readable danger.** You can always tell what's about to hurt you —
   telegraphs, tells, glows. Light equals meaning: everything
   interactive glows, nothing decorative does.
4. **Aftermath is the art style.** Every death, split, and choice
   leaves persistent bright residue. The dungeon remembers.

## The reframe: Polish to Demo

The week-one loop worked because it had a finish line. So does this
phase: **the current game — worlds 1 through 3, victory at 3-3 —
polished into a shippable demo.** No new systems, no new worlds.
The demo is done when all the sound and art we can think of is in,
plus all the sound and art we find we need along the way.

**The retune rule:** getting an asset in place is half the job.
Every sprite and sound gets a second pass after it's seen and heard
in the game — first placement is a draft, not a delivery. Budget for
it; don't treat retunes as setbacks.

Meta-progression and secret rooms enter the demo **only if the
checklist below goes super quick**. Otherwise they lead the
post-demo phase.

## Where we are (2026-07-17)

A completable game. Worlds read as x-1 / x-2 / x-3 (explore → item
room → boss) with misted title cards; victory at 3-3, endless below.
Stages connect by pale mist gates in timber doorframes; sealed
arrival doors close the way back; only boss floors have the true
hatch and the fall. Five creature families with distinct verbs,
infighting, grudges, and different afterlives (bones rise, goo
respawns, mushes get eaten, flesh stays down). Boss tiers cascade;
the Skeletal Wizard assembles from the corpses the player made.
Weapon fork: sword → staff or boomerang (full flight audio). Relics:
boots, two armor tiers. **Half-heart units shipped**: 2 units = one
HUD heart, start 6 units, cap 16, magic cap 12 — the damage economy
now has room for item modifiers. Wooden walls break, wooden floors
collapse into wall-deep shafts, provably never trapping the player.
Original three-song score drifts in and out; foley era in full
swing (mic + interface). Death report with killer portrait.
Web export validated.

## The demo checklist

### Art (Jessop draws, Claude wires, both retune)

- **The item wave — COMPLETE.** All twelve shipped: the crystal
  family (Fleetfoot ×2, Rage ×2, Hasty ×2, Lucky Luck, Quickstep,
  Twice-Cut, Gapleaper, Wide Swing, Turning ×2, Rotstone,
  Emberstone), the untiered weapon pool (sword / staff / boomerang
  / halberd, last claimed wins), randomized boss drops, and the
  toast system. Rot and Ember are the Pillar 4 pair: ticking
  wounds, stained corpses as residue, and burning bodies char the
  planks they stand on. Original plan for reference:
  1. **Strength** — +hit damage (`attack_damage` modifier).
  2. **Dex** — better dash: longer or faster (dash constants).
  3. **Double Dash** — two dash charges before the cooldown.
  4. **Shot Speed Up** — faster staff orbs / boomerang flight
     (needs per-projectile speed vars, currently consts).
  5. **Halberd** — longer melee reach (upgrade or third rival;
     decide when art exists).
  6. **Hole-strider** — pass over single holes (design open).
  7. **Sands of Time** — enemies slowed (global speed factor).
  8. **Luck** — more golden heart drops (drop-chance modifier).
  9. **Splash Damage** — hits damage adjacent enemies.
- ~~**Full turnaround sprites for all mobs**~~ — **DONE.** Doom-style
  4-direction billboards (front/back/left/right) across the whole
  roster — skeleton, wizard, frogman/frog/toad, slime tiers, mush
  tiers, amalgam — via `_update_view` projecting facing onto the camera
  axes. 8-way wasn't needed; the snapping reads fine.
- ~~**Attack sprites for enemies**~~ — **DONE.** Every creature winds up
  a directional attack lunge (drawn wind-up + strike frames); the
  creature-polish Attack-anim column is fully ✓.
- **Boss plate art** — the consent plate still wears sword-plate
  art; it deserves its own.
- **Polish sprites** — the running list of frames that need a
  second pass once seen in place; grows as we look.
- **Weapon feedback parity** — the torch is the benchmark
  (2026-07-18: drawn swing arc + ember burst + knockback shove +
  three-take foley = the best-feeling weapon in the game). Sword,
  staff, and boomerang each rise to that bar with wide-canvas
  swing frames, an impact effect of their own, and their sfx
  retuned against the torch's.

### Sound (the wishlist, plus what the game asks for)

**Done:** the death-sound sweep and the aggro "sees-you" sweep across
the whole roster (see docs/creature-polish.md), plus the dedicated
`boss_floor_fall.wav` for the 3-3 cave-in. **Still on the wishlist:**
wall crack tick (non-breaking hits; break is in), mush merge/split
squelch, frogman reveal fwump, descending A-minor fall stinger,
falling wail + distant thud (bodies and cargo taken by the deep),
amalgam assembly (or its deliberate silence) + its cast/launch, a
dedicated pale-gate crossing voice, ambient drips. Plus retune passes
on everything already in — levels, tails, pitch spreads — as the mix
fills up.

### Finish work

- **UI — see [docs/ui-language.md](ui-language.md)** (drafted
  2026-08-07). The rule is that UI is drawn art in torchlight, not text
  on a surface; the reason the in-game UI reads as characterless is that
  the HUD is seven typeset Labels while the only finished pieces are
  drawn plates. Demo-scoped order: **pause menu + Options** (checks the
  web-demo checklist's unticked "controls surfaced in-game", and is the
  cheapest place to solve what UI looks like OVER gameplay), then the
  death/victory pass, then the `click to descend` frame, then the HUD.
  Meta UI stays out — the title is already the hub, so meta adds a
  screen rather than rewiring the flow.
- One pass on the death report and victory screen — a demo lives
  or dies on its endings.
- A fresh full-run balance pass once the item wave is in (the
  half-heart baseline was tuned pre-items).
- **Periodic web-build smoke tests** — sights are on eventual
  release, so the browser build is a testing habit, not a one-time
  check. The early validation predates the mist shader (web runs
  gl_compatibility, not Forward+ — shaders are the likeliest
  divergence), the full foley era, and gates. Re-run the web export
  after each major visual/audio batch; deploy to the portfolio
  site when the checklist is done.

## Post-demo (each unfolds the way the demo did)

- **Meta-progression** — still the highest-leverage missing system:
  a MetaState saved to disk banking runs into unlocks that enter
  the item pool. First candidate for the next phase — demos live
  on "one more run." figure out tiers for levels,what items are 
  added on what level and what is the condition met that 
  unlocks them. Boss Trophys?
- **Secret rooms** — the commoner is BUILT (x-1 floors: sealed
  chamber grafted at generation, trigger buried under one plank
  with a faint amber glimmer tell, revealed on stone by collapse
  or demolition, sliding wall + grind, three golden hearts). The
  trial remains (findable only while no red damage taken this
  floor; fight + item). The synergy is the design: golden hearts
  protect red hearts, which keeps the trial findable. Trial needs
  per-floor red-damage tracking and its own reveal rule.
- **The three acts** — repeat the world pattern to victory at 9-3:
  two new mini-bosses, two new act-final bosses, per-act reskins
  (triplanar makes a reskin = three 64×64 tiles), possibly bigger
  grids deeper down. Each act is its own project with its own
  finish line, built on a polished base.

## Parking lot (ideas, not commitments)

*Scope test for the last three entries (added 2026-08-06): they are
deliberately **adjustments to systems that already exist** — more of the
item pool, more draws from it, more variation inside the wizard roster —
not new systems. That is the argument for why they could fit the polish
phase at all: "adding to or taking away from an existing system, like
more items, is fitting at this stage." Weigh them against that test, not
against whether they're good ideas.*

- Fall-in hole state (pits/lava/spikes — collision plumbing ready)
- Doors, keys, locked treasure rooms
- Minimap from the ASCII grid
- Full-shroud mist room (aesthetic variant, shader ready)
- Sealed-variant doorframe art (arrival doors currently show bare
  stone through the open frame — works, but a drawn seal could
  read stronger)
- ~~**The 3-3 floor drop**~~ — **BUILT 2026-07-29** (early, ahead of its
  post-demo tier). After the wave clears, the arena floor caves in and the
  fight plunges into a real chamber built 3 cell-layers below, where the
  corpses tween down and the Skeletal Wizard rises. Shipped with REAL
  seamless geometry — NOT the scene-swap this entry guessed; the true-3D
  GridMap made real geometry the better path — plus Phase-3 polish (camera
  shake, dust cascade, dedicated `boss_floor_fall.wav`, staged rise). See
  threshold-deep/CLAUDE.md "3-3 floor drop". Watch item it taught: any
  y-threshold self-despawn (player `fall_death_y`, creature `fall_y`) must
  drop below the chamber or things delete themselves on landing.
- Art landed (Jessop's pipeline): slime + mush turnarounds ✓,
  floor + wall break animations ✓. Still incoming: orb singe marks.
- **Torch viability** — before 2026-07-18 the torch was a grind to
  escape; now it feels like it belongs. With the right upgrades
  (ember damage? bigger shove? fire spread?) keeping the torch
  could become a real build choice instead of a phase — the
  starting weapon as a keeper is classic roguelike depth.
- **More relics** — Knockback Stone (push 'em harder), a charm crystal
  (turn a creature to your side), Heart Stone (health over time).
  **Check the pool math before adding any:** `_relic_pool()` starts at 18
  entries and a run claims about 6 (three item rooms × one pedestal, plus
  three boss drops), so flat additions *dilute* — every existing relic
  gets rarer while the take stays 6. Tiered relics are the counter; they
  let a run double down instead of spreading thin. Per idea:
  - *Knockback* — best fit. The knock-skid window has no steering, so
    shoves already feed the shafts, and a creature that goes down takes
    its body AND its drops with it — the relic self-balances with no
    tuning. Scaling `MELEE_RECOIL` alongside buys real risk near your own
    rims. Does nothing to the amalgam (no skid, cannot fall).
  - *Charm* — mechanically the cheapest, because Doom-style infighting is
    already built: `take_damage(…, attacker)` flips aggro, grudges hold
    until the target dies, `alert(against)` rallies neighbours. Build it
    as a conversion-on-hit in the Rot/Ember shape — a `dot.gd`-style node
    that tints the host and runs the 5-phase overlay — not as a pet. It
    costs score for free (only player kills count), and expiry turning
    the creature back on you is the aftermath beat.
  - *Heart Stone* — **not as a flat trickle.** Time is never scored on
    purpose, because these levels reward lingering; passive regen on top
    of zero time pressure makes standing still optimal and guts potions
    and half-hearts. **Settled 2026-08-06 as the GoldenHeart Stone:** it
    raises the half-golden-heart drop chance instead of regenerating.
    No camping incentive, doesn't touch the red-heart economy (potions
    can't heal magic hearts anyway), and it feeds the trial's "golden
    hearts protect red hearts" synergy — the reason to take it is
    keeping the trial findable, not raw sustain. Two watch items: it
    overlaps Lucky Luck Stone (drop rolls ×0.6 already includes magic
    hearts), so it must be clearly stronger on that one axis or it reads
    as a worse Lucky Luck — and decide whether the two stack. And
    drop-rate relics are low-feel by nature; if it doesn't land in
    playtest, the felt version is a half golden heart granted on each
    floor load, which is equally camp-proof and actually noticeable.
- **More ways to earn a draw** — the real lever, since draws and not pool
  size are what deepen a build. Two ideas: a second hidden room under a
  different plank, and a lever/plate room that seals and spawns a wave
  for an item (cages). **The wave room is already designed — it's "the
  trial"** in the Secret rooms entry above: fight + item, gated on no red
  damage taken this floor, with the commoner's golden hearts keeping it
  findable. That gate beats a lever, because it makes the whole floor
  tense retroactively. Cheap, too: it recombines built parts —
  `arena_mists` + `seal()`, the consent plate, the wave spawn from
  `_start_boss_fight` — and mist grammar already says gold = bargain,
  cold = fight, so a gold door that seals cold is a new sentence in a
  language the game speaks. Ship on the mist seal; cages are the second
  pass (retune rule). For the second hidden room, make it a **variant**
  of the commoner — one type rolled per x-1, never both on one floor.
  The tell is the mechanic, and two secrets a floor turns finding one
  from an event into a chore.
- ~~**Elemental amalgams**~~ — **BUILT 2026-08-06**, both halves. The
  necromancers got per-element fight styles first (`wizard.gd`'s
  `_apply_element` now carries speed, fire rate, wind-up, reach and orb
  weight, not just art), then `skeletal_wizard.gd` got the same enum +
  const-block + `_apply_element` shape and the dungeon rises **three**
  amalgams instead of one — blue, then red, then brown, each heaving up
  when the previous drops past `AMALGAM_RISE_AT` (half). Each takes
  `AMALGAM_SHARE` (0.45) of the corpse-scaled pool, so the trio is ~1.35x
  the old single boss rather than 3x — the difficulty is three patterns,
  not a longer health bar. Red and brown wear **cloned placeholder art**
  under `skeletal_wizard_red/` and `skeletal_wizard_brown/`, awaiting
  recolour. Watch item it taught: the wave-clear branch had to learn to
  rise the next colour, or a fast player who killed one before it reached
  the half-health cue would end the climax one boss in with the reward
  already dropped. Original entry follows.
  - the 3-3 fight isn't hard enough (playtest,
  2026-08-06), and this answers difficulty and lore in one move: fight
  all three necromancer colours through the act, then the corpses
  assemble into three amalgams wearing the blue/red/brown hats and capes.
  Lore that tells itself, and it makes the wizard variants matter beyond
  variety. `_drop_into_assembly` already captures the arena corpses, so
  reading *which* colours died out of that capture is the natural hook.
  - **Stage the rises; don't spawn three at once.** Bosses hit 4 units
    against a 16 cap and the amalgam has no knock, so three simultaneous
    is a burst wall, not a harder fight. Blue first, red at two-thirds,
    brown at a third, so escalation reads as the fight getting worse.
    Cheaper cousin if three bodies fight the code: ONE amalgam that swaps
    hat and cape as it loses health.
  - **The behaviour half is the good part.** `wizard.gd`'s
    `_apply_element()` is **presentation-only today** — sprites, orb art,
    impacts, glow, the `ember` flag — while `SPEED`, `CAST_RANGE`, and
    `BASE_CAST_COOLDOWN` stay flat consts for every colour. Making brown
    slower and harder-hitting, red faster and more frequent, means moving
    those into per-element blocks; the switch to hang them on exists and
    already runs before movement. Do it on the **wizards first** — that
    dynamises every wizard fight, not just the boss — then hand the
    amalgams the same patterns.
  - "Add a charge attack" is already there: `skeletal_wizard.gd` cycles
    `RUSH (4 s @ 3.0) → CHARGE (0.55 s wind-up) → RECOVER`, and those
    consts are exactly the per-element knobs.
  - **Widening drop chamber:** a true frustum is real generator work —
    `_build_boss_chamber` fills a 1-cell border frame matching the arena
    footprint, and the "fill stops one layer short under a solid arena
    wall" rule is tuned to that assumption. Cheap 80%: keep the shaft at
    arena width and build the CHAMBER as a larger `Rect2i`, so the walls
    fall away as you land — the moment you actually perceive. Three
    amalgams means three `fall_y` values to lower below the chamber.
