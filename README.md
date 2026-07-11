# Threshold Deep

*Working title.*

A first-person 3D roguelike dungeon crawler built in Godot 4. Inspired by
The Binding of Isaac and Barony: procedurally generated dungeons, billboarded
sprite creatures and items in a real 3D space, run-based structure.

## Status

Playable roguelike loop: procedurally generated dungeons you descend
through a hatch, with depth scaling and health carried between
floors. Three hand-drawn creatures — skeletons (melee), wizards
(dodgeable ranged orbs), slimes (split at half health, re-merge on
contact, dissolve potions) — with Doom-style monster infighting.
Breakable wooden walls open shortcuts; wooden floors collapse into
holes behind you. Torch-swing melee (left click), hearts HUD, health
potions, death screen with run summary. Press R in-game to reroll
the floor.

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
