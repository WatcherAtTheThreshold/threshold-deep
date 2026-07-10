extends Node3D

const SKELETON_SCENE := preload("res://scenes/skeleton.tscn")
const WIZARD_SCENE := preload("res://scenes/wizard.tscn")
const POTION_SCENE := preload("res://scenes/potion.tscn")
const HATCH_SCENE := preload("res://scenes/hatch.tscn")
const ROOM_POTION_CHANCE := 0.3
const EXTRA_SKELETON_CHANCE_PER_DEPTH := 0.15
const WIZARD_CHANCE_PER_DEPTH := 0.15
const WIZARD_CHANCE_MAX := 0.45
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
	var extra_chance := minf(
		EXTRA_SKELETON_CHANCE_PER_DEPTH * (RunState.depth - 1), 0.6)
	for i in range(1, rooms.size()):
		var spawn_cells: Array[Vector2i] = [rooms[i].get_center()]
		if randf() < extra_chance:
			spawn_cells.append(rooms[i].get_center() + Vector2i(-1, 0))
		var wizard_chance := minf(
			WIZARD_CHANCE_PER_DEPTH * (RunState.depth - 1), WIZARD_CHANCE_MAX)
		for cell in spawn_cells:
			var enemy: Node3D
			if randf() < wizard_chance:
				enemy = WIZARD_SCENE.instantiate()
			else:
				enemy = SKELETON_SCENE.instantiate()
			enemy.setup(RunState.depth)
			enemy.position = _cell_to_world(cell)
			add_child(enemy)
		if randf() < ROOM_POTION_CHANCE:
			var room := rooms[i]
			var potion_cell := room.position + Vector2i(
				randi_range(0, room.size.x - 1),
				randi_range(0, room.size.y - 1))
			var potion := POTION_SCENE.instantiate()
			potion.position = _cell_to_world(potion_cell, 0.5)
			add_child(potion)
	_place_hatch(rooms)


func _place_hatch(rooms: Array[Rect2i]) -> void:
	# The way down lives in the room farthest from where you start.
	var spawn := rooms[0].get_center()
	var far_index := 0
	var far_dist := -1.0
	for i in range(1, rooms.size()):
		var dist := Vector2(rooms[i].get_center() - spawn).length()
		if dist > far_dist:
			far_dist = dist
			far_index = i
	if far_index == 0:
		return
	var hatch := HATCH_SCENE.instantiate()
	hatch.position = _cell_to_world(
		rooms[far_index].get_center() + Vector2i(1, 0), 0.5)
	add_child(hatch)


func _cell_to_world(cell: Vector2i, y: float = 1.5) -> Vector3:
	# Cell center; default y = 1.5 stands a 2m-tall body on the 0.5m
	# floor slab. Pass y = 0.5 to sit something on the floor itself.
	return Vector3(cell.x * CELL_SIZE + 1.0, y, cell.y * CELL_SIZE + 1.0)
