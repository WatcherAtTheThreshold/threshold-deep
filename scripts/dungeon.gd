extends Node3D

## Hand-authored test map: "#" = wall, "." = floor. One character = one
## 2x2m cell. The procedural generator's whole job later is to produce
## a grid like this instead of us typing it.
const MAP: Array[String] = [
	"################",
	"#......#.......#",
	"#......#.......#",
	"#......#.......#",
	"#......#.......#",
	"#..............#",
	"#......#.......#",
	"#......#.......#",
	"#......#.......#",
	"#......#.......#",
	"################",
]

@onready var grid_map: GridMap = $GridMap


func _ready() -> void:
	var floor_id := grid_map.mesh_library.find_item_by_name("floor")
	var wall_id := grid_map.mesh_library.find_item_by_name("wall")
	for z in MAP.size():
		for x in MAP[z].length():
			var id := wall_id if MAP[z][x] == "#" else floor_id
			grid_map.set_cell_item(Vector3i(x, 0, z), id)
