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
| **Blue** | blue | electro bolt | — | ✓ ships today (the current wizard) |
| **Red** | red | fireball | Ember `Dot` | — |
| **Brown** | brown | thrown rock | — (heavier arc, no DoT) | — |

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
| Orb impact (3) | **NEW** | Fire hisses, rock cracks. The payoff sound of the attack. |
| Orb flight (1) | **NEW** | Travels toward you for a full second — it's a warning, not a detail. |
| Take-hit (3) | **SHARE** | They are all people in robes. One set for the roster. |
| Death (1) | **SHARE** | Same. Vary it later if a variant earns it. |

**Per NEW variant: 2 sprites drawn, 19 recoloured, 7 sounds recorded.**
That is the difference between a weekend and a month.

## Sprite naming

Convention in this repo: **the folder name is the file prefix.** Keep it.

```
assets/sprites/wizard/            wizard_front1.png        (blue, exists)
assets/sprites/wizard_red/        wizard_red_front1.png
assets/sprites/wizard_brown/      wizard_brown_front1.png
```

This sorts the whole family together in a listing, and it means a preload
path is derivable from the variant key alone. Full checklist per new
variant — all 19, same names, new prefix:

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
assets/audio/sfx/enemies/wizard_<v>_orb_flight.ogg
```

Shared across the whole roster, already recorded, do not duplicate:
`wizard_take_hit1/2/3.ogg`, `wizard_death1.ogg`.

**Always number a multi-take set from 1, even when you only record one.**
Adding takes 2 and 3 later then costs nothing. (`dash_bump1.ogg` and
`footsteps_player_dash1.ogg` follow this; several older files don't.)

## Irregularities in the existing names — do NOT copy these

Real inconsistencies already in the repo. New variants should follow the
*convention*, not the precedent:

- `projectile-wizard.ogg` — hyphenated and reversed. Should have been
  `wizard_orb_flight.ogg`. New variants use the corrected form.
- `assets/sprites/skeletal-wizard/` — hyphen, while its script is
  `skeletal_wizard.gd` and every other creature folder is one word.
- `wizard_death1.ogg` carries a `1` while `skeleton_death.ogg` does not.
- `frogmen_aggro.ogg` / `2` / `3` — the first take is missing its `1`.

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

**NOT free — two things `orb.tscn` hardcodes as scene nodes:**

1. **`Glow` is a blue `OmniLight3D`** (`light_color = (0.45, 0.9, 1)`).
   In a dungeon lit only by your torch, a red fireball casting blue light
   onto the walls will read as broken instantly — and worse, it wastes
   the best telegraph the game has. CLAUDE.md's Pillar 3 is *light equals
   meaning*; a coloured light travelling toward you through the dark IS
   the readable threat. Needs a `glow_color` var on `orb.gd`, same
   pattern as `frame_a`.
2. **`FlightSound.stream` is hardcoded** to `projectile-wizard.ogg` with
   `autoplay = true`. Needs a `flight_sound` var, applied in `_ready`
   before the player starts.

Both are small, and both must land before any variant can look or sound
like itself.

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

1. **Parameterize the orb** — `glow_color` + `flight_sound` on `orb.gd`.
   No art needed; blue keeps its current values as the defaults. This is
   the gate on everything else looking right.
2. **The launch sound** — `wizard_<v>_cast1.ogg` fired from `_fire_orb`.
   Closes creature-polish.md's outstanding wizard item for blue at the
   same time.
3. **One variant end to end** — red. 19 recolours, 2 new orb frames, 7
   sounds. Proves the whole pipeline on a single creature before the
   second one multiplies any mistake.
4. **`kill_label()` → Necromancer**, once there is more than one to name.
5. **Brown** — repeat step 3 with the arc/no-DoT differences.
6. **Stations** (docs/stations.md) — only once necromancers exist to
   stand at them.

*The expensive thing here is drawing, and the whole point of the shared
column is that most of the drawing is already done. Recolour, don't
redraw; the projectile and the voice carry the identity.*
