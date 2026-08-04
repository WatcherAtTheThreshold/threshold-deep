# Threshold Deep — The Necromancer Roster

*Drafted 2026-08-02. The asset + naming spec for the wizard variants:
what to draw, what to record, what to call it, and — the part worth
reading first — **what NOT to make twice.** Read alongside docs/acts.md
(the necromancer throughline this serves), docs/creature-polish.md (the
per-creature juice matrix this extends), docs/stations.md (where they
work), and the repo CLAUDE.md art/audio specs.*

Legend: **✓** exists · **—** needed · **~** partial / shared

> **The roster below is taken from acts.md's "elemental wizards" plan
> (blue / red / brown). If the variants you're drawing differ, the tables
> are the thing to edit — everything else in this doc is convention and
> holds regardless of how many variants there end up being.**

## The roster

| Variant | Robe | Attack | On hit | Status |
|---|---|---|---|:--|
| **Blue** | blue | electro bolt | — | ✓ |
| **Red** | red | fireball | Ember `Dot` (creatures only) | ✓ complete |
| **Brown** | brown | thrown rock | — | ~ wired; 4 frames + the arc outstanding |

**Brown's two open items:**

- **4 sprites not drawn** — `wizard_brown_front2.png` and the three
  `wizard_brown_shoot1/2/3.png`. They alias brown's OWN `front1` (marked
  `TODO` in `wizard.gd`), so the front walk holds still and the cast
  shows a neutral pose. Colour identity is intact, which is what
  matters; repoint the four lines when the art lands.
- **The heavier arc is NOT implemented.** Orbs fly dead straight
  (`position += direction * SPEED`). A real ballistic throw means gravity
  on the orb *and* the caster leading its aim upward to compensate —
  otherwise brown simply undershoots at range and stops being a threat.
  That's a gameplay feature with its own playtest, not a wiring job, so
  it was deliberately left out. Until it exists, brown is a distinct
  *look, voice and payload* firing on the same flat trajectory as blue.

Blue is not a new variant — it is the existing wizard, renamed into the
roster. Everything red and brown need is measured against it.

## What one wizard actually costs

Counted from the shipped blue wizard. This is the number to plan
against: **19 sprites, 11 sounds.**

| Group | Files | Names |
|---|--:|---|
| Walk turnaround | 6 | `front1/2`, `side1/2`, `back1/2` |
| Cast | 3 | `shoot1/2/3` |
| Take-hit | 6 | `front_takehit1/2`, `side_takehit1/2`, `back_takehit1/2` |
| Aggro pose | 1 | `front_aggro1` |
| Dead | 1 | `dead` |
| Projectile | 2 | `orb1/2` |
| **Sprites total** | **19** | |
| Aggro voice | 3 | `wizard_aggro1/2/3.ogg` |
| Take-hit | 3 | `wizard_take_hit1/2/3.ogg` |
| Death | 1 | `wizard_death1.ogg` |
| Orb impact | 3 | `wizard_orb_hit1/2/3.ogg` |
| Orb flight | 1 | `projectile-wizard.ogg` |
| **Audio total** | **11** | |

Three variants at full cost would be 57 sprites and 33 sounds. **Don't
pay that.** The next section is why.

## Shared vs per-variant — the cost lever

The identity of an elemental necromancer lives in **three** things: the
robe colour you read at distance, the projectile coming at you, and the
voice. Everything else is pose, and pose is identical across the roster —
they are the same silhouette in different dye.

| Asset | Per-variant? | Why |
|---|:--:|---|
| Walk turnaround (6) | **recolour** | Robe colour IS the tell (acts.md Pillar-3: read the robe, know the threat). Same drawing, new palette. |
| Take-hit (6) | **recolour** | Pure pose. Never redraw. |
| Aggro pose (1) | **recolour** | Pose + colour; the sting carries the character. |
| Dead (1) | **recolour** | Aftermath reads by colour — a red corpse says which one you killed. |
| Cast (3) | **recolour** | The glow does the elemental work (see below); the arms don't change. |
| Projectile (2) | **NEW ART** | The single most-looked-at thing they own. A fireball must not be a blue orb in red. |
| Aggro voice (3) | **NEW** | Cheapest possible character. acts.md's "cheap tier" is exactly this. |
| Cast / launch (1) | **NEW** | The moment of release. Absent for every variant *including blue* — see the code hooks below. |
| Orb impact (3) | **NEW** | Fire hisses, rock cracks. The payoff sound of the attack. |
| Orb flight (1) | **NEW** | Travels toward you for a full second — it's a warning, not a detail. |
| Take-hit (3) | **SHARE** | They are all people in robes. One set for the roster. |
| Death (1) | **SHARE** | Same. Vary it later if a variant earns it. |

**Per NEW variant: 2 sprites drawn, 19 recoloured, 8 sounds recorded.**
That is the difference between a weekend and a month.

*(Corrected 2026-08-02: this line said 7 and the table above was missing
the cast/launch row. It's 8 — aggro ×3, cast ×1, orb impact ×3, orb
flight ×1. Blue also needs its own `wizard_cast1.ogg`, since the launch
cue is missing across the board.)*

## Sprite naming

**The file prefix is the variant key**, and variants live in a subfolder
of `wizard/` — the `frogmen/frogmen-phase1/` shape. Blue's frames stay
loose in `wizard/` itself:

```
assets/sprites/wizard/                 wizard_front1.png       (blue)
assets/sprites/wizard/wizard_red/      wizard_red_front1.png
assets/sprites/wizard/wizard_brown/    wizard_brown_front1.png
```

Nesting keeps the whole necromancer family under one directory. The one
asymmetry to know about: blue is loose alongside the subfolders rather
than in a `wizard_blue/` of its own. Moving it would mean 19 preloads,
the scene, and the gallery — worth doing only if the roster grows enough
that the mixed layout actually bites.

Full checklist per new variant — all 19, same names, new prefix:

```
wizard_<v>_front1.png     wizard_<v>_front2.png
wizard_<v>_side1.png      wizard_<v>_side2.png      (drawn facing LEFT)
wizard_<v>_back1.png      wizard_<v>_back2.png
wizard_<v>_shoot1.png     wizard_<v>_shoot2.png     wizard_<v>_shoot3.png
wizard_<v>_front_takehit1.png    wizard_<v>_front_takehit2.png
wizard_<v>_side_takehit1.png     wizard_<v>_side_takehit2.png
wizard_<v>_back_takehit1.png     wizard_<v>_back_takehit2.png
wizard_<v>_front_aggro1.png
wizard_<v>_dead.png
wizard_<v>_orb1.png       wizard_<v>_orb2.png
```

Canvas 64×64, 32 px = 1 m, feet at the bottom edge, side art drawn facing
LEFT (code flips for right). Same as every creature.

## Audio naming

```
assets/audio/sfx/enemies/wizard_<v>_aggro1.ogg      2, 3
assets/audio/sfx/enemies/wizard_<v>_cast1.ogg       (launch — see below)
assets/audio/sfx/enemies/wizard_<v>_orb_hit1.ogg    2, 3
assets/audio/sfx/enemies/wizard_<v>_orb_flight1.ogg
```

The flight sound carries a `1` like every other set even though `orb.gd`
takes a single `flight_sound: AudioStream`, not an array. That's
deliberate future-proofing: if it ever wants variety per orb, the rename
is already done and the only change is `flight_sound` becoming an
`Array[AudioStream]` with a random pick, exactly like `impact_sounds`.

Shared across the whole roster, already recorded, do not duplicate:
`wizard_take_hit1/2/3.ogg`, `wizard_death1.ogg`.

**Always number a multi-take set from 1, even when you only record one.**
Adding takes 2 and 3 later then costs nothing. (`dash_bump1.ogg` and
`footsteps_player_dash1.ogg` follow this; several older files don't.)

## Irregularities in the existing names

Audited 2026-08-02. The rule applied: **rename when the bad name will sit
next to new correct ones and get copied; otherwise leave it alone.** Every
rename is a chance to break a reference for zero gameplay value.

**Fixed:**

- ~~`projectile-wizard.ogg`~~ → **`wizard_orb_flight1.ogg`** (4 refs).
  Renamed because `wizard_red_orb_flight1.ogg` is about to be its
  neighbour, and the natural move when adding red is to copy the pattern
  already in the folder. (Took its `1` in a second pass, to match — a
  numbered singleton next to an unnumbered one is the same defect this
  audit exists to remove.)
- ~~`frogmen_aggro.ogg`~~ → **`frogmen_aggro1.ogg`** (6 refs). Renamed
  because it was the one visible exception to the "always number a set
  from 1" rule, in the same folder the necromancer trios will land in. A
  rule with a counter-example in plain sight stops being a rule.

**Deferred — `assets/sprites/skeletal-wizard/` → `skeletal_wizard/`.**
Genuinely wrong (hyphen, while its script is `skeletal_wizard.gd` and
every other creature folder is one word), but **32 references** across
`index.html` (17), `skeletal_wizard.gd` (14), and its scene. No new asset
will ever land inside that folder, so it can't propagate. The real cost
isn't the rename — it's that verifying it means playing all the way to
3-3 to watch the amalgam assemble. Do it as its own isolated change on a
day when that's the only thing being tested, not mid-feature.

**Not a defect — `wizard_death1.ogg`.** An earlier draft of this doc
listed the `1` as the irregularity. It's backwards: by the convention
above, a numbered singleton is **correct**, and the eight unnumbered
death sounds (`skeleton_death.ogg`, `slime_death.ogg`, the four mush
tiers, `frogmen_frog_toad_death.ogg`, `skeletal_wizard_death.ogg`) are
the ones off-pattern. They stay that way: eight files across six
creatures, for singletons that will realistically never gain takes 2 and
3. **The convention binds new sounds, not old ones.**

## Code hooks — what is already free, and what isn't

**Free: no new projectile scene.** `orb.gd` overrides per instance —
`frame_a`, `frame_b`, `impact_sounds`, `damage`, `speed_scale`, `splash`.
A fireball is `orb.tscn` with different values. The Skeletal Wizard
already proves the pattern.

**Free: the Ember DoT.** `Dot.attach(target, self, "Ember")` exists and
works. Red's whole mechanical identity is one call in the orb's hit path.

**Free: the fiction name.** `wizard.gd`'s `kill_label()` returns
`"Wizard"`. Return `"Necromancer"` (or `"Red Necromancer"`) and the death
report, the kill tally, and the bestiary all say it. See the naming
decision below.

**Free as of 2026-08-02 — the orb's look and voice are now parameterized
too.** `glow_color` and `flight_sound` are plain vars on `orb.gd`,
defaulting to `WIZARD_GLOW` (`0.45, 0.9, 1`) and `projectile-wizard.ogg`,
so blue is unchanged and a variant overrides them exactly like `frame_a`:

```gdscript
orb.frame_a = RED_ORB_A
orb.frame_b = RED_ORB_B
orb.glow_color = Color(1.0, 0.45, 0.15)      # firelight, not bolt-blue
orb.flight_sound = RED_ORB_FLIGHT
orb.impact_sounds = RED_ORB_IMPACTS
```

`FlightSound`'s `autoplay` came off the scene to make this work — children
`_ready` before their parent, so autoplay started the *default* stream a
beat early, and assigning `stream` to a playing player stops it dead.
`orb.gd` now starts it explicitly in `_ready` after the overrides land.

**`glow_energy` — added 2026-08-02, when brown arrived.** Default 1.2
(orb.tscn's value); brown runs 0.6 with a dusty-amber colour.

The judgement call worth recording: a thrown rock arguably shouldn't glow
*at all*, and it doesn't get that. The dungeon is lit by your torch and
nothing else, so a projectile throwing no light is a projectile you
cannot see coming — and Pillar 3 says you can always tell what is about
to hurt you. Realism loses to readability here. **Dim it, never kill
it.** `omni_range` (3.5) is still a scene value; nothing has needed it
per-element yet.

**Also worth knowing:** `wizard.gd`'s `_fire_orb()` plays no sound of its
own — the whoosh you hear is the orb's own `FlightSound`, riding along
with the projectile. So a *launch* sound at the caster's position (the
`wizard_<v>_cast1.ogg` above) is genuinely absent for every variant
including blue. creature-polish.md lists this as an open item; adding it
once, parameterized, closes it for the whole roster at the same time.

## The naming decision: "wizard" in code, "Necromancer" in fiction

`wizard` is load-bearing across scripts, scenes, sprite folders, audio
files, the gallery manifest, and CLAUDE.md. Renaming it to `necromancer`
is a wide, purely cosmetic refactor with real breakage risk and no
gameplay payoff.

**Recommendation: don't.** Keep `wizard` as the code and asset family
name; make **Necromancer** the display name via `kill_label()`. The
player only ever sees the label — the death report, the kill tally, the
bestiary. The fiction lands in full for a one-line change, and the repo
stays greppable.

## Slicing order

Each step is independently testable and leaves the game shippable.

1. ~~**Parameterize the orb**~~ — **DONE 2026-08-02.** `glow_color` +
   `flight_sound` on `orb.gd`, blue's values as the defaults. (`glow_energy`
   for a non-luminous thrown rock is still open — see above.)
2. ~~**The launch sound**~~ — **DONE 2026-08-02.** `cast_sound` fires from
   `_fire_orb` for every element; blue's `wizard_cast1.ogg` closes
   creature-polish.md's outstanding wizard item.
3. ~~**One variant end to end** — red.~~ **DONE 2026-08-02, art and all.**
   `wizard.gd` is element-driven (`enum Element`, per-element const
   blocks, `_apply_element()` in `_ready`); red rolls at `RED_CHANCE` in
   `setup()`; its 19 sprites, voice, cast, impacts, flight, orb glow and
   Ember are all its own. The aliasing scheme paid off exactly as
   intended — landing the art was repointing 13 const lines, with no
   other change to the script.
4. ~~**`kill_label()` → Necromancer**~~ — **DONE 2026-08-02.** Returns
   "Necromancer" / "Red Necromancer"; the code family stays `wizard`.

### Ember on the PLAYER — DONE 2026-08-02

Red's burn now works on both sides of the fight, by two different routes,
and the split is deliberate:

- **Creatures** get an Ember `Dot` node (`orb.gd`'s `dot_kind`). Ticks
  credit the caster, so the victim turns on it — the same infighting rule
  the slime's caustic touch runs on.
- **The player** gets `player.take_burn()`, the twin of `take_poison`:
  its own tick channel outside `take_damage`, `BURN_TICKS` 3 at
  `BURN_INTERVAL` 0.8s (matching `Dot.gd`'s Ember rate), magic hearts
  soaking first, and an **orange** HUD pulse via the new `burned` signal
  — distinct from poison's green and the red hit-flash.

**Why not just Dot the player:** `Dot` ticks via `host.take_damage`, which
on the player runs i-frames, knockback and the hit sound. Burns would have
been swallowed at random and each surviving tick would have read as a fresh
blow. Burn and poison are kept as separate channels so a player can be
poisoned and burning at once.
5. **Brown** — **wired 2026-08-02** (15 of 19 sprites, all 8 sounds, dim
   amber orb, no DoT). Outstanding: the 4 undrawn frames and the
   ballistic arc — see the roster notes above.
6. **Stations** (docs/stations.md) — only once necromancers exist to
   stand at them.

*The expensive thing here is drawing, and the whole point of the shared
column is that most of the drawing is already done. Recolour, don't
redraw; the projectile and the voice carry the identity.*
