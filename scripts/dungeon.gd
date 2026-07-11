extends Node3D

const SKELETON_SCENE := preload("res://scenes/skeleton.tscn")
const WIZARD_SCENE := preload("res://scenes/wizard.tscn")
const SLIME_SCENE := preload("res://scenes/slime.tscn")
const POTION_SCENE := preload("res://scenes/potion.tscn")
const HATCH_SCENE := preload("res://scenes/hatch.tscn")

const GRID_WIDTH := 40
const GRID_HEIGHT := 28
const ROOM_ATTEMPTS := 14
const CELL_SIZE := 2.0

const ROOM_POTION_CHANCE := 0.3
const EXTRA_SKELETON_CHANCE_PER_DEPTH := 0.15
const WIZARD_CHANCE_PER_DEPTH := 0.15
const WIZARD_CHANCE_MAX := 0.45
const SLIME_CHANCE := 0.18

const WOOD_WALL_HITS := 2
const FLOOR_COLLAPSE_CHANCE := 0.35

var floor_id := -1
var wall_id := -1
var floor_wood_id := -1
var wall_wood_id := -1
var hole_id := -1
var ceiling_id := -1

var wall_damage := {}
var last_player_cell := Vector3i(-9999, 0, -9999)

@onready var grid_map: GridMap = $GridMap
@onready var hole_map: GridMap = $HoleMap
@onready var player: Player = $Player


func _ready() -> void:
	floor_id = grid_map.mesh_library.find_item_by_name("floor")
	wall_id = grid_map.mesh_library.find_item_by_name("wall")
	floor_wood_id = grid_map.mesh_library.find_item_by_name("floor_wood")
	wall_wood_id = grid_map.mesh_library.find_item_by_name("wall_wood")
	hole_id = grid_map.mesh_library.find_item_by_name("hole")
	ceiling_id = grid_map.mesh_library.find_item_by_name("ceiling")

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
	last_player_cell = _player_cell()


func _physics_process(_delta: float) -> void:
	# Wooden floors give way behind you: when the player leaves a
	# plank cell, it may collapse into a hole.
	var cell := _player_cell()
	if cell != last_player_cell:
		if grid_map.get_cell_item(last_player_cell) == floor_wood_id \
				and randf() < FLOOR_COLLAPSE_CHANCE:
			grid_map.set_cell_item(last_player_cell, GridMap.INVALID_CELL_ITEM)
			hole_map.set_cell_item(last_player_cell, hole_id)
		last_player_cell = cell


func damage_wall(hit_pos: Vector3, hit_normal: Vector3) -> void:
	# Called by the player's swing when it lands on the GridMap.
	# Nudge inward past the surface so we sample the struck cell.
	var cell := grid_map.local_to_map(grid_map.to_local(hit_pos - hit_normal * 0.05))
	if grid_map.get_cell_item(cell) != wall_wood_id:
		return
	wall_damage[cell] = wall_damage.get(cell, 0) + 1
	if wall_damage[cell] >= WOOD_WALL_HITS:
		grid_map.set_cell_item(cell, floor_id)
		# The opened cell needs a lid too, or you'd see the void.
		grid_map.set_cell_item(cell + Vector3i(0, 1, 0), ceiling_id)


func _unhandled_input(event: InputEvent) -> void:
	# R rerolls the whole dungeon.
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()


func _player_cell() -> Vector3i:
	var cell := grid_map.local_to_map(grid_map.to_local(player.global_position))
	cell.y = 0
	return cell


func _build(map: Array[String]) -> void:
	for z in map.size():
		for x in map[z].length():
			var id := floor_id
			match map[z][x]:
				"#":
					id = wall_id
				"W":
					id = wall_wood_id
				",":
					id = floor_wood_id
			grid_map.set_cell_item(Vector3i(x, 0, z), id)
			# Every walkable cell gets a ceiling slab in the cell
			# above, resting on top of the 4m walls.
			if id != wall_id and id != wall_wood_id:
				grid_map.set_cell_item(Vector3i(x, 1, z), ceiling_id)


func _populate(rooms: Array[Rect2i]) -> void:
	# Player starts in the first room; every other room gets enemies.
	player.position = _cell_to_world(rooms[0].get_center())
	var extra_chance := minf(
		EXTRA_SKELETON_CHANCE_PER_DEPTH * (RunState.depth - 1), 0.6)
	var wizard_chance := minf(
		WIZARD_CHANCE_PER_DEPTH * (RunState.depth - 1), WIZARD_CHANCE_MAX)
	for i in range(1, rooms.size()):
		var spawn_cells: Array[Vector2i] = [rooms[i].get_center()]
		if randf() < extra_chance:
			spawn_cells.append(rooms[i].get_center() + Vector2i(-1, 0))
		for cell in spawn_cells:
			var enemy: Node3D
			var roll := randf()
			if roll < wizard_chance:
				enemy = WIZARD_SCENE.instantiate()
			elif roll < wizard_chance + SLIME_CHANCE:
				enemy = SLIME_SCENE.instantiate()
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
