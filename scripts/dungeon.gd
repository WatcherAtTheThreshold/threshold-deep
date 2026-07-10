extends Node3D

const SKELETON_SCENE := preload("res://scenes/skeleton.tscn")
const GRID_WIDTH := 40
const GRID_HEIGHT := 28
const ROOM_ATTEMPTS := 14
const CELL_SIZE := 2.0

@onready var grid_map: GridMap = $GridMap
@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var dungeon := DungeonGenerator.generate(GRID_WIDTH, GRID_HEIGHT, ROOM_ATTEMPTS, rng)
	var map: Array[String] = dungeon.map
	var rooms: Array[Rect2i] = dungeon.rooms

	# Print the blueprint to the Output panel — same grid, new every run.
	for row in map:
		print(row)

	_build(map)
	_populate(rooms)


func _unhandled_input(event: InputEvent) -> void:
	# R rerolls the whole dungeon.
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()


func _build(map: Array[String]) -> void:
	var floor_id := grid_map.mesh_library.find_item_by_name("floor")
	var wall_id := grid_map.mesh_library.find_item_by_name("wall")
	for z in map.size():
		for x in map[z].length():
			var id := wall_id if map[z][x] == "#" else floor_id
			grid_map.set_cell_item(Vector3i(x, 0, z), id)


func _populate(rooms: Array[Rect2i]) -> void:
	# Player starts in the first room; every other room gets a skeleton.
	player.position = _cell_to_world(rooms[0].get_center())
	for i in range(1, rooms.size()):
		var skeleton := SKELETON_SCENE.instantiate()
		skeleton.position = _cell_to_world(rooms[i].get_center())
		add_child(skeleton)


func _cell_to_world(cell: Vector2i) -> Vector3:
	# Cell center; y = 1.5 stands a 2m-tall thing on the 0.5m floor slab.
	return Vector3(cell.x * CELL_SIZE + 1.0, 1.5, cell.y * CELL_SIZE + 1.0)
