# Threshold Deep

*Working title.*

A first-person 3D roguelike dungeon crawler built in Godot 4. Inspired by
The Binding of Isaac and Barony: procedurally generated dungeons, billboarded
sprite creatures and items in a real 3D space, run-based structure.

## Status

Playable roguelike loop: procedurally generated, torch-lit dungeons
under stone ceilings, descended floor by floor through a hatch, with
depth scaling and health and gear carried between floors. Five
hand-drawn creature families — skeletons (melee), wizards (dodgeable
ranged orbs), slimes (split at half health, re-merge, dissolve
potions), mushrooms (split into minis; mushes actively seek each
other to fuse into a mega), and frogmen (two frogs in a trenchcoat:
coat-off reveal, then a hopping frog and a toad) — with Doom-style
monster infighting. Every death and split leaves persistent bright
remains: corpses, goo splats, a crumpled coat. Breakable wooden
walls open shortcuts; wooden floors collapse into holes behind you.
Torch and sword jab attacks, dash instead of jump, positional
creature footsteps, hearts HUD, potions, and a death report naming
(and picturing) your killer with full run stats, in a pixel UI font.
Press R in-game to reroll the floor.

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
