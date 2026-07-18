# Threshold Deep

*Working title.*

A first-person 3D roguelike dungeon crawler built in Godot 4. Inspired by
The Binding of Isaac and Barony: procedurally generated dungeons, billboarded
sprite creatures and items in a real 3D space, run-based structure.

## The Bestiary

Every sprite and sound in the game, alive on one page — click a
creature to see it move and hear it. Wired to the same asset files
the game loads.

**[watcheratthethreshold.github.io/threshold-deep](https://watcheratthethreshold.github.io/threshold-deep/)**

<img src="docs/bestiary-qr.png" width="180" alt="QR code to the bestiary">


## Status

A completable roguelike: three worlds of explore → item room → boss,
each floor announced by a misted title card, victory at 3-3 and
endless descent below. Five hand-drawn creature families with
distinct verbs and distinct afterlives (bones rise from their piles,
slime corpses respawn, mushrooms eat dead slimes and turn green,
flesh stays down), Doom-style infighting, and boss tiers that
cascade — the Slime Boss bursts into larges into smalls; the
Skeletal Wizard assembles itself from the corpses you made in its
arena. Weapon fork: torch → sword → magic staff or boomerang.
Relics, a two-currency heart economy, sealed mist doors, breakable
wooden walls, collapsing plank floors over wall-deep shafts (provably
never trapping you), an original three-song score that drifts in and
out, positional creature footsteps, and a death report naming and
picturing your killer. Press R in-game to reroll the floor (debug).

## Tech

- **Engine:** Godot 4.7 (GDScript), web export validated
- **World:** GridMap tiles from a hand-written MeshLibrary
- **Creatures & items:** Sprite3D with billboard mode (Doom/Delver style)
- **Dungeon generation:** grid-based rooms + corridors, generated as 2D data
  and instantiated into the GridMap

Forward plan and design pillars: [docs/roadmap.md](docs/roadmap.md)

## Roadmap

1. ~~First-person character controller walking around a CSG blockout room~~
2. ~~A billboarded sprite creature standing in the world~~
3. ~~GridMap tile library replacing CSG~~
4. ~~Procedural dungeon generation feeding the GridMap~~
5. ~~The actual roguelike: combat and run structure~~
6. Items, more creatures, audio — see [docs/roadmap.md](docs/roadmap.md)
