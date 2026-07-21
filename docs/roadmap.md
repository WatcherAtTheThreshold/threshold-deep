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
- **Full turnaround sprites for all mobs** — Doom-style directional
  billboards (promoted from the parking lot). Needs code support:
  pick the frame from the viewer's angle to the creature's facing.
  **Decided: 4 directions** (front/back/left/right), judged in
  torchlight on the first creature before the bestiary follows;
  upgrade to 8 only if the snapping reads badly in play.
- **Attack sprites for enemies** — wind-up and strike frames so
  melee telegraphs are drawn, not just moved (pillar 3).
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

Wall crack tick (non-breaking hits; break is in), mush merge/split
squelch, frogman reveal fwump, descending A-minor fall stinger,
falling wail + distant thud (bodies and cargo taken by the deep),
amalgam assembly (or its deliberate silence), a dedicated pale-gate
crossing voice, ambient drips. Plus retune passes on everything
already in — levels, tails, pitch spreads — as the mix fills up.

### Finish work

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
  on "one more run."
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

- Fall-in hole state (pits/lava/spikes — collision plumbing ready)
- Doors, keys, locked treasure rooms
- Minimap from the ASCII grid
- Full-shroud mist room (aesthetic variant, shader ready)
- Sealed-variant doorframe art (arrival doors currently show bare
  stone through the open frame — works, but a drawn seal could
  read stronger)
- **The 3-3 floor drop** — after the wave, the arena floor gives
  way and the player falls into a larger chamber below where the
  corpses reassemble into the Skeletal Wizard. Endorsed: it's the
  game weaponizing its own floor-betrayal lesson at the climax,
  and it's buildable as a scene transition reusing the descent
  plumbing (special one-room arena floor, corpse props, existing
  assembly) rather than true two-story geometry. Post-demo-polish
  tier; pairs with per-act signature arenas.
- Art incoming (Jessop's pipeline): slime + mush turnarounds
  (partial redraws from existing poses; the mushes have cute
  butts), wall-break rubble tiles, break animations, orb singe
  marks.
- **Torch viability** — before 2026-07-18 the torch was a grind to
  escape; now it feels like it belongs. With the right upgrades
  (ember damage? bigger shove? fire spread?) keeping the torch
  could become a real build choice instead of a phase — the
  starting weapon as a keeper is classic roguelike depth.
