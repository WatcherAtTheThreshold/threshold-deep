# Threshold Deep

*Working title.*

A first-person 3D roguelike dungeon crawler built in Godot 4. Inspired by
The Binding of Isaac and Barony: procedurally generated dungeons, billboarded
sprite creatures and items in a real 3D space, run-based structure.

## Status

Early prototype — not yet playable.

## Tech

- **Engine:** Godot 4.x (GDScript)
- **World:** GridMap tiles (CSG blockout for early prototyping)
- **Creatures & items:** Sprite3D with billboard mode (Doom/Delver style)
- **Dungeon generation:** grid-based rooms + corridors, generated as 2D data
  and instantiated into the GridMap

## Roadmap

1. First-person character controller walking around a CSG blockout room
2. A billboarded sprite creature standing in the world
3. GridMap tile library (floor, wall, corner, doorway) replacing CSG
4. Procedural dungeon generation feeding the GridMap
5. The actual roguelike: combat, items, runs
