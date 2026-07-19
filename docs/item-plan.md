# Threshold Deep — Item & Crystal Design

*Drafted 2026-07-19. Companion to docs/roadmap.md ("the item wave").*

## The grammar

Three classes of pickup, three different reads:

| Class | Look | Reads as |
|---|---|---|
| **Weapons** | The actual object, glowing | "that changes how I fight" |
| **Hearts / lives** | What they are (hearts, 1-Up) | "that changes how long I live" |
| **Crystals** | Shared gem family, hue + cut | "that changes my build" |


| Hue | Family | Members |
|---|---|---|
| **Red** | Damage output | Strength, Fire |
| **Cyan** | Movement | Speed, Dex, Double Dash, Hole-strider |
| **White / steel** | Defense | Armor (both tiers) |
| **Gold** | Fortune | Luck |
| **Violet** | Projectiles | Shot Speed |
| **Green** | Corruption | Poison |
| **Orange** | Reach | Splash |


## Cuts

One base gem, five silhouettes. Draw the base once, vary from there.

- **Shard** — single tall spike. The default; first tier of anything.
- **Cluster** — three or four spikes from a shared base. Second tier,
  or "more of the same."
- **Split** — two separated halves floating apart. Anything with a
  count or a doubling.
- **Ring** — hollow, hole in the middle. Anything about space or gaps.
- **Rough** — uncut, lumpy, unfaceted. Corruption / fire / poison —
  the ones that aren't clean.

**Tiering rule:** same hue, bigger or more complex cut. Never a new
color. Tier 2 should read as "that one again, more so" — no relearning.

## The table

### Weapons (real objects, not crystals)

| # | Name | Effect | Notes |
|---|---|---|---|
| 1 | Sword | Base melee upgrade, 4 dmg | Boss 1 reward. Shipped. |
| 6 | Magic Staff | 2-dmg orb, rapid, camera aim | Rival. Shipped. |
| 7 | Boomerang | 2 dmg, pierces, returns | Rival. Shipped. |
| 12 | Halberd | Longer melee reach | **See open question below** |

### Hearts & lives (self-explanatory art)

| # | Name | Effect | Notes |
|---|---|---|---|
| 2 | 1-Up | Survive one death | Shipped |
| 3 | Three Golden Hearts | +3 magic heart units | Shipped |

### Crystals

| # | Name | Descriptor | Hue | Cut | Tiers |
|---|---|---|---|---|---|
| 4 | **Fleetfoot Stone** | *moves you faster* | Cyan | Shard | 2 — Cluster at tier 2 |
| 5 | **Turning Stone** | *some blows glance off* | White/steel | Shard → Cluster | 2 — leather, then steel |
| 8 | **Rage Crystal** | *hits harder* | Red | Shard → Cluster | 2 possible |
| 9 | **Quickstep Crystal** | *dash goes further* | Cyan | Split | 1 |
| 10 | **Twice-Cut Crystal** | *dash twice* | Cyan | Split (two gems) | 1 |
| 11 | **Hasty Little Stone** | *shots fly faster* | Violet | Shard | 2 possible |
| 13 | **Gapleaper** | *cross the gaps* | Cyan | Ring | 1 |
| 15 | **Lucky Luck Stone** | *the deep is generous* | Gold | Cluster | 1 |
| 16 | **Wide Swing Crystal** | *strikes spread* | Orange | Cluster | 1 |
| 17 | **Rotstone** | *wounds fester* | Green | Rough | 1 |
| 18 | **Emberstone** | *wounds burn* | Red | Rough | 1 |


Take the funny names. "Lucky Luck Stone" is memorable in a way "Luck
Up" isn't, and memorable is the whole job — the pairing has to survive
from run 3 to run 30. It also gives the items a *voice*, which the game
currently gets from creatures and aftermath but not from pickups. Costs
one string.

**Toast format** — two lines, fading, on walk-over:

```
RAGE CRYSTAL
hits harder
```

- **No numbers.** "+2 damage" invites math about a system the player
  can't see. "Hits harder" is honest and gets read in the 1.5 s it's
  on screen.
- **Descriptor is lowercase italic**, name is caps. Different weight
  = different job: one is the mnemonic, one is the one-time teach.
- **Tier 2 changes the descriptor, not the name.** Turning Stone at
  steel reads *"most blows glance off."* Same name, escalated line.



**Poison and Fire are Pillar 4 items, not stat items.** They're the only
two that change what a hit *leaves behind* — burning corpses, festering
enemies that keep ticking after you walk away. Their real teach isn't
the toast, it's the first enemy that keeps dying after you stopped
hitting it. Budget residue art for both. They probably deserve the
strongest identity in the crystal family for that reason, and the
"rough/uncut" cut is doing that work.

**Fire on wooden floors.** The dungeon already has "wooden floors break
under 2 damage-units of anyone's fire." Emberstone plus a plank floor is
either a great emergent moment or an accident that drops the player into
the Dark Below. Worth an explicit decision — deliberate damage has the
final say by design, so this will happen.

**Red/orange collision.** Test Rage Crystal against Wide Swing in
torchlight before committing to the palette.

**Do crystals stack visibly?** Nothing on the player shows the build.
Not a demo problem, but when meta-progression lands, a HUD-free way to
see what you're carrying becomes a real question — and Pillar 1 says
it can't be an inventory screen.
