extends Node3D

const SKELETON_SCENE := preload("res://scenes/skeleton.tscn")
const WIZARD_SCENE := preload("res://scenes/wizard.tscn")
const SLIME_SCENE := preload("res://scenes/slime.tscn")
const MUSH_SCENE := preload("res://scenes/mush.tscn")
const FROGMAN_SCENE := preload("res://scenes/frogman.tscn")
const POTION_SCENE := preload("res://scenes/potion.tscn")
const HATCH_SCENE := preload("res://scenes/hatch.tscn")
const SWORD_SCENE := preload("res://scenes/sword_pickup.tscn")
const MAGIC_PICKUP_SCENE := preload("res://scenes/magic_hearts_pickup.tscn")
const CONTAINER_PICKUP_SCENE := preload("res://scenes/heart_container_pickup.tscn")
const FLEETFOOT_SCENE := preload("res://scenes/fleetfoot_pickup.tscn")
const FLEETFOOT2_SCENE := preload("res://scenes/fleetfoot2_pickup.tscn")
const RAGE_SCENE := preload("res://scenes/rage_pickup.tscn")
const RAGE2_SCENE := preload("res://scenes/rage2_pickup.tscn")
const HASTY_SCENE := preload("res://scenes/hasty_pickup.tscn")
const HASTY2_SCENE := preload("res://scenes/hasty2_pickup.tscn")
const LUCKYLUCK_SCENE := preload("res://scenes/luckyluck_pickup.tscn")
const QUICKSTEP_SCENE := preload("res://scenes/quickstep_pickup.tscn")
const TWICECUT_SCENE := preload("res://scenes/twicecut_pickup.tscn")
const GAPLEAPER_SCENE := preload("res://scenes/gapleaper_pickup.tscn")
const WIDESWING_SCENE := preload("res://scenes/wideswing_pickup.tscn")
const ROTSTONE_SCENE := preload("res://scenes/rotstone_pickup.tscn")
const EMBERSTONE_SCENE := preload("res://scenes/emberstone_pickup.tscn")
const ARMOR_PICKUP_SCENE := preload("res://scenes/armor_pickup.tscn")
const ARMOR2_PICKUP_SCENE := preload("res://scenes/armor2_pickup.tscn")
const STAFF_PICKUP_SCENE := preload("res://scenes/staff_pickup.tscn")
const BOOMERANG_PICKUP_SCENE := preload("res://scenes/boomerang_pickup.tscn")
const HALBERD_PICKUP_SCENE := preload("res://scenes/halberd_pickup.tscn")
const MIST_SCENE := preload("res://scenes/mist_door.tscn")
const MIST_GATE_SCENE := preload("res://scenes/mist_gate.tscn")
const ARRIVAL_DOOR_SCENE := preload("res://scenes/arrival_door.tscn")
const BOSS_PLATE_SCENE := preload("res://scenes/sword_trigger.tscn")
const SECRET_PLATE_SCENE := preload("res://scenes/magic_heart_trigger.tscn")
const SKELETAL_WIZARD_SCENE := preload("res://scenes/skeletal_wizard.tscn")
const SOUND_FLOOR_NORMAL := preload("res://assets/audio/sfx/environment/normal_floor_start.wav")
const SOUND_FLOOR_BOSS := preload("res://assets/audio/sfx/environment/boss_floor_start.wav")
const SOUND_FLOOR_ITEM := preload("res://assets/audio/sfx/environment/item_floor_start.wav")
const SOUND_DOOR_LOCK := preload("res://assets/audio/sfx/environment/boss_room_door_lock.wav")
const SOUND_WALL_BREAK := preload("res://assets/audio/sfx/environment/broken_wall1.wav")
const SOUND_SECRET_GRIND := preload("res://assets/audio/sfx/environment/secretroom_wallslidegrind1.wav")
const SOUND_FLOOR_BREAK := preload("res://assets/audio/sfx/environment/broken_floor1.wav")
const SOUND_ITEM_MIST := preload("res://assets/audio/sfx/environment/item_room_mist_door.wav")
const HATCH_TEXTURE := preload("res://assets/tiles/hatch_open.png")

const GRID_WIDTH := 40
const GRID_HEIGHT := 28
const ROOM_ATTEMPTS := 14
const CELL_SIZE := 2.0

const ROOM_POTION_CHANCE := 0.3
const EXTRA_SKELETON_CHANCE_PER_DEPTH := 0.15
const WIZARD_CHANCE_PER_DEPTH := 0.15
const WIZARD_CHANCE_MAX := 0.45
const SLIME_CHANCE := 0.18
const MUSH_CHANCE_PER_DEPTH := 0.04
const MUSH_CHANCE_MAX := 0.25
const FROGMAN_CHANCE_PER_DEPTH := 0.06
const FROGMAN_CHANCE_MAX := 0.18
const FROGMAN_MIN_DEPTH := 3

const WOOD_WALL_HITS := 4  # half-heart damage units: torch 2 swings, sword 1
const FLOOR_COLLAPSE_CHANCE := 0.35
const FIGHT_GRACE_TIME := 2.5
const WOOD_FLOOR_HITS := 2  # planks splinter easier than walls

var floor_id := -1
var wall_id := -1
var floor_wood_id := -1
var wall_wood_id := -1
var hole_id := -1
var void_id := -1
var ceiling_id := -1
var wall_upper_id := -1
var wall_upper_variants: Array[int] = []
var buried_stone_id := -1
var floor_wood_pale_id := -1

var wall_damage := {}
var last_player_cell := Vector3i(-9999, 0, -9999)
var enemy_cells := {}  # instance id -> last grid cell, for enemy-worn planks
var floor_rooms: Array[Rect2i] = []
var kind: int = RunState.FloorKind.REGULAR

# Boss floor state
var arena_room_idx := -1
var arena_mists: Array[Node3D] = []
var boss_index := 0
var fight_active := false
var fight_grace := 0.0
var amalgam_stage := 0  # 0 = wave, 1 = assembling, 2 = amalgam active
var mush_stage := 0  # world 2: 0 = slime fake-out, 1 = the real boss
var boss_hatch: Node3D = null
var boss_hatch_cell := Vector2i(-1, -1)

# The commoner secret (regular floors): a sealed chamber, a buried
# trigger under one plank, and the wall that slides.
var secret_room_cells: Array[Vector2i] = []
var secret_door := Vector2i(-1, -1)
var secret_plank := Vector2i(-1, -1)
var secret_revealed := false
var secret_opened := false

# Item floor state
var item_room_idx := -1
var item_mists: Array[Node3D] = []
var item_pedestals: Array[Node3D] = []
var item_sealed := false
var item_resolved := false

@onready var grid_map: GridMap = $GridMap
@onready var hole_map: GridMap = $HoleMap
@onready var upper_map: GridMap = $UpperMap
@onready var player: Player = $Player


func _ready() -> void:
	floor_id = grid_map.mesh_library.find_item_by_name("floor")
	wall_id = grid_map.mesh_library.find_item_by_name("wall")
	floor_wood_id = grid_map.mesh_library.find_item_by_name("floor_wood")
	wall_wood_id = grid_map.mesh_library.find_item_by_name("wall_wood")
	hole_id = grid_map.mesh_library.find_item_by_name("hole")
	void_id = grid_map.mesh_library.find_item_by_name("void")
	wall_upper_id = grid_map.mesh_library.find_item_by_name("wall_upper")
	wall_upper_variants = [
		grid_map.mesh_library.find_item_by_name("wall_upper1"),
		grid_map.mesh_library.find_item_by_name("wall_upper2"),
	]
	buried_stone_id = grid_map.mesh_library.find_item_by_name("buried_stone")
	floor_wood_pale_id = grid_map.mesh_library.find_item_by_name("floor_wood_pale")
	ceiling_id = grid_map.mesh_library.find_item_by_name("ceiling")

	kind = RunState.floor_kind(RunState.depth)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var dungeon := DungeonGenerator.generate(GRID_WIDTH, GRID_HEIGHT,
			ROOM_ATTEMPTS, rng, kind == RunState.FloorKind.REGULAR)
	var map: Array[String] = dungeon.map
	var rooms: Array[Rect2i] = dungeon.rooms
	floor_rooms = rooms
	secret_room_cells = dungeon.secret_room
	secret_door = dungeon.secret_door
	secret_plank = dungeon.secret_plank

	# Print the blueprint to the Output panel — same grid, new every run.
	for row in map:
		print(row)
	var demoted: Array[Vector2i] = dungeon.demoted
	if demoted.size() > 0:
		print("gen-fix: demoted %d wooden floor cell(s) to stone for solvability: %s" \
				% [demoted.size(), str(demoted)])
	print("floor %d: %s" % [RunState.depth,
			RunState.FloorKind.keys()[kind]])

	_build(map)
	_dress_upper_walls()
	if kind == RunState.FloorKind.BOSS:
		arena_room_idx = _largest_room(rooms)
		_populate(rooms, arena_room_idx, false)
		_setup_boss_room()
	elif kind == RunState.FloorKind.ITEM:
		# Largest, not farthest: the guaranteed arena-sized room means
		# center pedestals always sit well clear of the mist doors.
		item_room_idx = _largest_room(rooms)
		_populate(rooms, item_room_idx, true, item_room_idx)
		_setup_item_room()
	else:
		_populate(rooms)
	if RunState.stage(RunState.depth) != 1:
		# The sealed doorway you arrived through — bare frame, stone
		# showing through, no way back.
		_place_against_wall(ARRIVAL_DOOR_SCENE, rooms[0])
	else:
		# You fell onto this floor: the hatch you dropped through is
		# still overhead, dark and out of reach. Continuity.
		var above := Sprite3D.new()
		above.texture = HATCH_TEXTURE
		above.pixel_size = 0.03125
		above.shaded = true
		above.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		above.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		above.rotation_degrees = Vector3(90, 0, 0)
		above.modulate = Color(0.6, 0.6, 0.65)
		above.position = _cell_to_world(rooms[0].get_center(), 3.96)
		add_child(above)
	last_player_cell = _player_cell()

	# Every floor announces itself.
	if kind == RunState.FloorKind.BOSS:
		_play_stinger(SOUND_FLOOR_BOSS)
	elif kind == RunState.FloorKind.ITEM:
		_play_stinger(SOUND_FLOOR_ITEM)
	else:
		_play_stinger(SOUND_FLOOR_NORMAL)


func _physics_process(_delta: float) -> void:
	# Wooden floors give way behind any walker — the player, or any
	# enemy heavy enough to be in the enemies group.
	var cell := _player_cell()
	if cell != last_player_cell:
		_try_collapse(last_player_cell)
		last_player_cell = cell
	for e: Node3D in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var ecell := grid_map.local_to_map(grid_map.to_local(e.global_position))
		ecell.y = 0
		var eid := e.get_instance_id()
		var prev: Variant = enemy_cells.get(eid)
		if prev != null and prev != ecell:
			_try_collapse(prev)
		enemy_cells[eid] = ecell

	if fight_active:
		fight_grace = maxf(fight_grace - _delta, 0.0)
		if fight_grace == 0.0 and not _arena_has_living_enemies():
			if boss_index >= 2 and amalgam_stage == 0:
				# Phase two: the bodies got up.
				amalgam_stage = 1
				_begin_assembly()
			elif boss_index == 1 and mush_stage == 0:
				# The fake-out lands: same opening as last world —
				# then the real boss arrives, and its minis are
				# hungry for the corpses phase one just made.
				mush_stage = 1
				_spawn_mush_boss()
			elif amalgam_stage != 1:
				_finish_boss_fight()

	if item_room_idx >= 0 and not item_resolved:
		if not item_sealed:
			# The bargain announces itself but never locks the door:
			# walking out empty-handed is a choice the room respects.
			if _player_inside_room(floor_rooms[item_room_idx]):
				item_sealed = true
				_play_stinger(SOUND_ITEM_MIST)
		else:
			var taken := false
			for p in item_pedestals:
				if not is_instance_valid(p):
					taken = true
			if taken:
				item_resolved = true
				for p in item_pedestals:
					if is_instance_valid(p):
						p.queue_free()
				for m in item_mists:
					if is_instance_valid(m):
						m.dissolve()


func damage_wall(hit_pos: Vector3, hit_normal: Vector3, amount := 1) -> void:
	# Called by the player's swing and by orbs landing on the GridMap.
	# Nudge inward past the surface so we sample the struck cell.
	var cell := grid_map.local_to_map(grid_map.to_local(hit_pos - hit_normal * 0.05))
	var id := grid_map.get_cell_item(cell)
	if id == floor_wood_id or id == floor_wood_pale_id:
		# Planks splinter under fire — anyone's fire — and deliberate
		# damage has the final say: no guards here. You can drop the
		# plank under an enemy, or under yourself if you mean to. The
		# plank-that-holds rule protects only against accidents
		# (passive walk-collapse in _try_collapse).
		wall_damage[cell] = wall_damage.get(cell, 0) + amount
		if wall_damage[cell] < WOOD_FLOOR_HITS:
			return
		if Vector2i(cell.x, cell.z) == secret_plank and not secret_revealed:
			# This plank hides something better than a hole.
			_reveal_secret_trigger(cell)
			return
		grid_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
		hole_map.set_cell_item(cell, hole_id)
		Sfx.play_at(SOUND_FLOOR_BREAK,
				_cell_to_world(Vector2i(cell.x, cell.z), 0.5), -6.0)
		_drop_the_unsupported(cell)
		return
	if id != wall_wood_id:
		return
	wall_damage[cell] = wall_damage.get(cell, 0) + amount
	if wall_damage[cell] >= WOOD_WALL_HITS:
		grid_map.set_cell_item(cell, floor_id)
		# The opened cell needs a lid too, or you'd see the void.
		grid_map.set_cell_item(cell + Vector3i(0, 1, 0), ceiling_id)
		Sfx.play_at(SOUND_WALL_BREAK,
				_cell_to_world(Vector2i(cell.x, cell.z), 1.0), -5.0)


func _unhandled_input(event: InputEvent) -> void:
	# R rerolls the whole dungeon (debug key) — never mid-boss-fight.
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		if fight_active:
			return
		get_tree().reload_current_scene()


func _try_collapse(cell: Vector3i) -> void:
	# A wooden cell just lost its walker. Whoever stepped, the same
	# protections hold: never the player's own square, never a plank
	# whose loss severs the player's path to stone.
	var walked_id := grid_map.get_cell_item(cell)
	if walked_id != floor_wood_id and walked_id != floor_wood_pale_id:
		return
	if randf() >= FLOOR_COLLAPSE_CHANCE:
		return
	if Vector2i(cell.x, cell.z) == secret_plank and not secret_revealed:
		# This plank hides something better than a hole.
		_reveal_secret_trigger(cell)
		return
	var standing := _player_cell()
	if cell == standing or not _player_keeps_path_to_stone(cell, standing):
		return
	grid_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
	hole_map.set_cell_item(cell, hole_id)
	Sfx.play_at(SOUND_FLOOR_BREAK,
			_cell_to_world(Vector2i(cell.x, cell.z), 0.5), -8.0)
	_drop_the_unsupported(cell)


func _reveal_secret_trigger(cell: Vector3i) -> void:
	# The plank splinters onto stone, not void: something was buried
	# here. The trigger plate glows where the glimmer used to.
	secret_revealed = true
	grid_map.set_cell_item(cell, floor_id)
	hole_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
	Sfx.play_at(SOUND_FLOOR_BREAK,
			_cell_to_world(Vector2i(cell.x, cell.z), 0.5), -6.0)
	var plate := SECRET_PLATE_SCENE.instantiate()
	plate.position = _cell_to_world(Vector2i(cell.x, cell.z), 0.5)
	plate.activated.connect(_open_secret_room)
	add_child(plate)


func _open_secret_room() -> void:
	# One wall cell slides aside: the chamber was always there.
	if secret_opened or secret_door == Vector2i(-1, -1):
		return
	secret_opened = true
	var door := Vector3i(secret_door.x, 0, secret_door.y)
	grid_map.set_cell_item(door, floor_id)
	grid_map.set_cell_item(door + Vector3i(0, 1, 0), ceiling_id)
	upper_map.set_cell_item(door, GridMap.INVALID_CELL_ITEM)
	Sfx.play_at(SOUND_SECRET_GRIND, _cell_to_world(secret_door, 1.0), -3.0)
	# The commoner pays in gold: three hearts at the chamber's heart.
	var center := Vector3.ZERO
	for c in secret_room_cells:
		center += _cell_to_world(c, 0.5)
	center /= secret_room_cells.size()
	var hearts := MAGIC_PICKUP_SCENE.instantiate()
	hearts.position = center
	add_child(hearts)


func _drop_the_unsupported(cell: Vector3i) -> void:
	# The collapsing plank takes its cargo: corpses, drops, and splats
	# on that cell sink into the dark and are gone — a kill made on
	# wood may cost its loot. Living bodies keep their own footing
	# (gravity + rim probes), and projectiles in flight are exempt.
	for node: Node in get_children():
		var n3 := node as Node3D
		if n3 == null or n3 == player:
			continue
		if n3.get("shooter") != null or n3.get("thrower") != null:
			continue
		var p := n3.global_position
		if p.y > 2.0 or Vector2i(floori(p.x / 2.0), floori(p.z / 2.0)) \
				!= Vector2i(cell.x, cell.z):
			continue
		var is_corpse: bool = n3.get("dead") == true
		if not (is_corpse or n3 is Sprite3D or n3 is Area3D):
			continue
		if n3 is CharacterBody3D and not is_corpse:
			continue
		# Freeze its own behavior (bobbing, respawn timers, pickup
		# contact) so the sink owns it all the way down.
		n3.set_process(false)
		n3.set_physics_process(false)
		if n3 is Area3D:
			n3.set_deferred("monitoring", false)
		var tween := create_tween()
		tween.tween_property(n3, "global_position:y", p.y - 5.0, 0.6) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(n3.queue_free)


func _player_keeps_path_to_stone(collapse_cell: Vector3i, player_cell: Vector3i) -> bool:
	# The plank that holds: a collapse is suppressed if it would cut
	# the player off from all stone. The gen-time proof covers the
	# stone graph; this covers a player who wanders onto the wooden
	# region and burns it behind themselves.
	var start := Vector2i(player_cell.x, player_cell.z)
	var banned := Vector2i(collapse_cell.x, collapse_cell.z)
	var visited := {start: true}
	var queue: Array[Vector2i] = [start]
	while queue.size() > 0:
		var c: Vector2i = queue.pop_back()
		var id := grid_map.get_cell_item(Vector3i(c.x, 0, c.y))
		if id == floor_id:
			return true
		if id != floor_wood_id and id != floor_wood_pale_id and c != start:
			continue
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n := c + d
			if n == banned or visited.has(n):
				continue
			var nid := grid_map.get_cell_item(Vector3i(n.x, 0, n.y))
			if nid == floor_id or nid == floor_wood_id \
					or nid == floor_wood_pale_id:
				visited[n] = true
				queue.append(n)
	return false


func _play_stinger(stream: AudioStream, db := -8.0) -> void:
	# Non-positional one-shot for floor announcements and seals —
	# parented to the Sfx autoload so reloads never cut it off.
	Sfx.play_ui(stream, db)


func _player_cell() -> Vector3i:
	var cell := grid_map.local_to_map(grid_map.to_local(player.global_position))
	cell.y = 0
	return cell


func _player_inside_room(room: Rect2i) -> bool:
	var cell := _player_cell()
	return room.has_point(Vector2i(cell.x, cell.z))


func _dress_upper_walls() -> void:
	# Every stone wall wears a variant band, and the bands come in
	# neighborhoods: each room rolls a variant, its walls agree, and
	# corridor walls side with the nearest room — halls carry a
	# room's masonry outward, so the dungeon reads in zones.
	var room_variant: Array[int] = []
	for i in floor_rooms.size():
		room_variant.append(wall_upper_variants[
				randi_range(0, wall_upper_variants.size() - 1)])
	if room_variant.is_empty():
		return
	for cell: Vector3i in grid_map.get_used_cells():
		if grid_map.get_cell_item(cell) != wall_id:
			continue
		var p := Vector2(cell.x, cell.z)
		var best := 0
		var best_d := INF
		for i in floor_rooms.size():
			var d := p.distance_squared_to(Vector2(floor_rooms[i].get_center()))
			if d < best_d:
				best_d = d
				best = i
		upper_map.set_cell_item(cell, room_variant[best])


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
			if id == floor_wood_id and Vector2i(x, z) == secret_plank:
				# The tell is the tile itself: same boards, drained
				# of color. Pattern recognition, not a spotlight —
				# and the tint can fade toward normal deeper down.
				id = floor_wood_pale_id
				grid_map.set_cell_item(Vector3i(x, 0, z), id)
			if id == floor_wood_id or id == floor_wood_pale_id:
				# The under-place was always there; the planks only
				# hide it. Collisionless black under every plank so
				# holes never leak the sky-blue backdrop sideways —
				# collapse swaps this for the blocking hole tile.
				# The secret plank is the exception: stone under it
				# from birth, the second tell, visible from any
				# neighboring hole.
				var under := void_id
				if id == floor_wood_pale_id:
					under = buried_stone_id
				hole_map.set_cell_item(Vector3i(x, 0, z), under)
			# Every walkable cell gets a ceiling slab in the cell
			# above, resting on top of the 4m walls.
			if id != wall_id and id != wall_wood_id:
				grid_map.set_cell_item(Vector3i(x, 1, z), ceiling_id)


func _populate(rooms: Array[Rect2i], skip_idx := -1, with_hatch := true,
		hatch_exclude := -1) -> void:
	# Player starts in the first room; every other room gets enemies.
	player.position = _cell_to_world(rooms[0].get_center())
	var extra_chance := minf(
		EXTRA_SKELETON_CHANCE_PER_DEPTH * (RunState.depth - 1), 0.6)
	var wizard_chance := minf(
		WIZARD_CHANCE_PER_DEPTH * (RunState.depth - 1), WIZARD_CHANCE_MAX)
	var mush_chance := minf(
		MUSH_CHANCE_PER_DEPTH * RunState.depth, MUSH_CHANCE_MAX)
	var frogman_chance := minf(
		FROGMAN_CHANCE_PER_DEPTH * maxf(RunState.depth - FROGMAN_MIN_DEPTH + 1, 0.0),
		FROGMAN_CHANCE_MAX)
	for i in range(1, rooms.size()):
		if i == skip_idx:
			continue
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
			elif roll < wizard_chance + SLIME_CHANCE + mush_chance:
				enemy = MUSH_SCENE.instantiate()
			elif roll < wizard_chance + SLIME_CHANCE + mush_chance + frogman_chance:
				enemy = FROGMAN_SCENE.instantiate()
			else:
				enemy = SKELETON_SCENE.instantiate()
			enemy.setup(RunState.depth)
			enemy.position = _cell_to_world(cell)
			add_child(enemy)
		if randf() < ROOM_POTION_CHANCE:
			var stone := _stone_cells(rooms[i])
			if stone.size() > 0:
				var potion := POTION_SCENE.instantiate()
				potion.position = _cell_to_world(
					stone[randi_range(0, stone.size() - 1)], 0.5)
				add_child(potion)
	if with_hatch:
		_place_hatch(rooms, hatch_exclude)


# ------------------------------------------------------------------
# Boss floors (docs/structure.md)

func _setup_boss_room() -> void:
	var arena := floor_rooms[arena_room_idx]
	arena_mists = _spawn_mists(arena, false)
	boss_index = mini(RunState.bosses_defeated, 2)
	var cells := _stone_cells(arena)
	if cells.is_empty():
		var center := arena.get_center()
		grid_map.set_cell_item(Vector3i(center.x, 0, center.y), floor_id)
		cells.append(center)
	# The sealed hatch sits at the arena's heart from the start —
	# visible, dark, waiting for the boss to die.
	boss_hatch_cell = _nearest_cell_to_center(arena, cells)
	boss_hatch = HATCH_SCENE.instantiate()
	boss_hatch.closed = true
	boss_hatch.position = _cell_to_world(boss_hatch_cell, 0.5)
	add_child(boss_hatch)
	# The consent plate: an empty, quiet arena, and a plate. Stepping
	# it starts the fight.
	cells.shuffle()
	var plate_cell := boss_hatch_cell + Vector2i(1, 0)
	for c in cells:
		if c != boss_hatch_cell:
			plate_cell = c
			break
	if grid_map.get_cell_item(Vector3i(plate_cell.x, 0, plate_cell.y)) != floor_id:
		grid_map.set_cell_item(Vector3i(plate_cell.x, 0, plate_cell.y), floor_id)
	var plate := BOSS_PLATE_SCENE.instantiate()
	plate.position = _cell_to_world(plate_cell, 0.5)
	plate.activated.connect(_start_boss_fight)
	add_child(plate)


func _nearest_cell_to_center(room: Rect2i, cells: Array[Vector2i]) -> Vector2i:
	var center := room.get_center()
	var best := cells[0]
	var best_d := INF
	for c in cells:
		var d := Vector2(c - center).length_squared()
		if d < best_d:
			best_d = d
			best = c
	return best


func _start_boss_fight() -> void:
	fight_active = true
	fight_grace = FIGHT_GRACE_TIME
	_play_stinger(SOUND_DOOR_LOCK)
	for m in arena_mists:
		if is_instance_valid(m):
			m.seal()
	var arena := floor_rooms[arena_room_idx]
	var center := arena.get_center()
	match boss_index:
		0:
			# Boss 1 — the Slime Boss: splits into two larges, each
			# into two smalls. Positioning, not DPS.
			var slime := SLIME_SCENE.instantiate()
			slime.position = _cell_to_world(center)
			add_child(slime)
			slime.emerge_state = slime.State.BOSS
			slime.health = slime.BOSS_MAX_HEALTH
			slime.spawn_timer = 1.2
		1:
			# Boss 2 opens with a lie: the Slime Boss again, same as
			# last world. The Mush Boss arrives when it dies.
			var slime := SLIME_SCENE.instantiate()
			slime.position = _cell_to_world(center)
			add_child(slime)
			slime.emerge_state = slime.State.BOSS
			slime.health = slime.BOSS_MAX_HEALTH
			slime.spawn_timer = 1.2
		_:
			# Boss 3 placeholder: a wave of skeletons and wizards.
			# TODO(structure.md): the Skeletal Wizard amalgam —
			# phase two assembles from the corpses this wave leaves.
			var spots := _stone_cells(arena)
			spots.shuffle()
			for n in 6:
				var enemy: Node3D
				if n < 2:
					enemy = WIZARD_SCENE.instantiate()
				else:
					enemy = SKELETON_SCENE.instantiate()
				enemy.setup(RunState.depth)
				var cell := center if spots.is_empty() \
						else spots[n % spots.size()]
				enemy.position = _cell_to_world(cell)
				add_child(enemy)


func _spawn_mush_boss() -> void:
	# World 2 phase two: the Mush Boss lands on a battlefield
	# littered with slime corpses, and its cascade knows how to eat
	# them — minis dart for the pools and come back green.
	var arena := floor_rooms[arena_room_idx]
	var mush := MUSH_SCENE.instantiate()
	mush.configure(mush.State.BOSS, mush.BOSS_MAX_HEALTH)
	mush.hunger = true
	mush.position = _cell_to_world(arena.get_center())
	add_child(mush)
	fight_grace = 1.5


func _begin_assembly() -> void:
	# Everything stops. Every corpse in the arena — every body the
	# player made — drags itself slowly toward the centre.
	var arena := floor_rooms[arena_room_idx]
	# Half-meter slop only: 3m used to reach through the arena wall,
	# and a corridor skeleton wandering past outside could hold the
	# fight open forever.
	var min_x := arena.position.x * CELL_SIZE - 0.5
	var max_x := arena.end.x * CELL_SIZE + 0.5
	var min_z := arena.position.y * CELL_SIZE - 0.5
	var max_z := arena.end.y * CELL_SIZE + 0.5
	var corpses: Array[Node3D] = []
	for child in get_children():
		if not child is CharacterBody3D or child == player:
			continue
		if child.get("dead") != true:
			continue
		var p: Vector3 = child.global_position
		if p.x >= min_x and p.x <= max_x and p.z >= min_z and p.z <= max_z:
			corpses.append(child)
	# Assemble on stone nearest the centre (never over a hole, and
	# not on the sealed hatch).
	var center_cell := arena.get_center()
	var cells := _stone_cells(arena)
	var best_d := INF
	for c in cells:
		if c == boss_hatch_cell:
			continue
		var d := Vector2(c - center_cell).length_squared()
		if d < best_d:
			best_d = d
			center_cell = c
	var center := _cell_to_world(center_cell, 1.1)
	var i := 0
	for c in corpses:
		c.set_physics_process(false)
		var offset := Vector3(
			randf_range(-0.5, 0.5), randf_range(-0.1, 0.5), randf_range(-0.5, 0.5))
		var tw := create_tween()
		tw.tween_interval(0.5 + i * 0.15)
		tw.tween_property(c, "global_position", center + offset, 2.6) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		i += 1
	var timer := Timer.new()
	timer.wait_time = 0.5 + corpses.size() * 0.15 + 2.6 + 0.6
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_spawn_amalgam.bind(corpses, center, corpses.size()))
	timer.start()


func _spawn_amalgam(corpses: Array, center: Vector3, body_count: int) -> void:
	for c: Node3D in corpses:
		if is_instance_valid(c):
			c.queue_free()
	var boss := SKELETAL_WIZARD_SCENE.instantiate()
	boss.position = center + Vector3(0, 0.7, 0)
	add_child(boss)
	# The player built this boss: HP scales with the bodies, capped —
	# panic must cost, but never spiral. (Half-heart units.)
	boss.health = clampi(20 + body_count * 4, 28, 68)
	amalgam_stage = 2
	fight_grace = 1.5


func _arena_has_living_enemies() -> bool:
	var arena := floor_rooms[arena_room_idx]
	# Half-meter slop only: 3m used to reach through the arena wall,
	# and a corridor skeleton wandering past outside could hold the
	# fight open forever.
	var min_x := arena.position.x * CELL_SIZE - 0.5
	var max_x := arena.end.x * CELL_SIZE + 0.5
	var min_z := arena.position.y * CELL_SIZE - 0.5
	var max_z := arena.end.y * CELL_SIZE + 0.5
	for group in ["enemies", "slimes"]:
		for e: Node3D in get_tree().get_nodes_in_group(group):
			if not is_instance_valid(e) or e.get("dead"):
				continue
			var p := e.global_position
			if p.x >= min_x and p.x <= max_x and p.z >= min_z and p.z <= max_z:
				return true
	return false


func _finish_boss_fight() -> void:
	fight_active = false
	for m in arena_mists:
		if is_instance_valid(m):
			m.dissolve()
	# The sealed hatch at the arena's heart opens — but never under
	# anyone's feet.
	if is_instance_valid(boss_hatch):
		boss_hatch.open()
	# The reward is earned by the fight — and the deep decides what
	# it is: one random draw from the same pool the pedestals use.
	# Never empty (golden hearts are always in the draw).
	var pool := _relic_pool()
	var reward: Node3D = pool[randi_range(0, pool.size() - 1)].instantiate()
	if reward != null:
		var arena := floor_rooms[arena_room_idx]
		var cells := _stone_cells(arena)
		cells.shuffle()
		var reward_cell := boss_hatch_cell + Vector2i(1, 0)
		for c in cells:
			if c != boss_hatch_cell:
				reward_cell = c
				break
		reward.position = _cell_to_world(reward_cell, 0.5)
		add_child(reward)
	RunState.bosses_defeated += 1
	if RunState.bosses_defeated >= 3 and not RunState.victory_shown:
		RunState.victory_shown = true
		player.get_node("HUD").show_victory()


# ------------------------------------------------------------------
# Item floors (docs/structure.md)

func _relic_pool() -> Array[PackedScene]:
	# Everything the run hasn't granted yet. Item rooms offer two of
	# these; bosses drop one at random — even the sword is in the
	# draw, so a swordless run is a torch run, and that's a run.
	var pool: Array[PackedScene] = [MAGIC_PICKUP_SCENE]
	if player.max_health < player.MAX_HEALTH_CAP:
		pool.append(CONTAINER_PICKUP_SCENE)
	if not RunState.has_sword:
		pool.append(SWORD_SCENE)
	# Crystals gate their next tier on the previous, armor-style.
	if RunState.fleet_tier == 0:
		pool.append(FLEETFOOT_SCENE)
	elif RunState.fleet_tier == 1:
		pool.append(FLEETFOOT2_SCENE)
	if RunState.rage_tier == 0:
		pool.append(RAGE_SCENE)
	elif RunState.rage_tier == 1:
		pool.append(RAGE2_SCENE)
	if RunState.hasty_tier == 0:
		pool.append(HASTY_SCENE)
	elif RunState.hasty_tier == 1:
		pool.append(HASTY2_SCENE)
	if not RunState.lucky:
		pool.append(LUCKYLUCK_SCENE)
	if not RunState.quickstep:
		pool.append(QUICKSTEP_SCENE)
	if not RunState.twicecut:
		pool.append(TWICECUT_SCENE)
	if not RunState.gapleaper:
		pool.append(GAPLEAPER_SCENE)
	if not RunState.wideswing:
		pool.append(WIDESWING_SCENE)
	if not RunState.rotstone:
		pool.append(ROTSTONE_SCENE)
	if not RunState.emberstone:
		pool.append(EMBERSTONE_SCENE)
	if RunState.armor_tier == 0:
		pool.append(ARMOR_PICKUP_SCENE)
	elif RunState.armor_tier == 1:
		pool.append(ARMOR2_PICKUP_SCENE)
	if not RunState.has_staff:
		pool.append(STAFF_PICKUP_SCENE)
	if not RunState.has_boomerang:
		pool.append(BOOMERANG_PICKUP_SCENE)
	if not RunState.has_halberd:
		pool.append(HALBERD_PICKUP_SCENE)
	return pool


func _setup_item_room() -> void:
	var room := floor_rooms[item_room_idx]
	item_mists = _spawn_mists(room, true)
	var cells := _stone_cells(room)
	# Pedestals gather at the room's heart — spawned at the doorway,
	# an item could be walked into blind through the mist. The bargain
	# should be seen before it's struck.
	var center := room.get_center()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a - center).length_squared() < (b - center).length_squared())
	if cells.is_empty():
		grid_map.set_cell_item(Vector3i(center.x, 0, center.y), floor_id)
		cells.append(center)
	var pool := _relic_pool()
	pool.shuffle()
	var count := mini(2, mini(pool.size(), cells.size()))
	# At most one weapon per bargain: a second weapon draw is passed
	# over, so a pedestal pair never demands the player rearm.
	var weapons: Array[PackedScene] = \
			[SWORD_SCENE, STAFF_PICKUP_SCENE, BOOMERANG_PICKUP_SCENE, HALBERD_PICKUP_SCENE]
	var picks: Array[PackedScene] = []
	var weapon_taken := false
	for scene: PackedScene in pool:
		if picks.size() >= count:
			break
		if weapons.has(scene) and weapon_taken:
			continue
		picks.append(scene)
		weapon_taken = weapon_taken or weapons.has(scene)
	for scene: PackedScene in pool:
		# Desperate fallback: a pool of nothing but weapons fills in.
		if picks.size() >= count:
			break
		if not picks.has(scene):
			picks.append(scene)
	for i in picks.size():
		var pedestal := picks[i].instantiate()
		pedestal.always_consume = true
		pedestal.position = _cell_to_world(cells[i], 0.5)
		add_child(pedestal)
		item_pedestals.append(pedestal)


# ------------------------------------------------------------------
# Shared special-room helpers

func _largest_room(rooms: Array[Rect2i]) -> int:
	# Boss arenas want space: area first, distance from spawn as the
	# tiebreaker. Never the spawn room.
	if rooms.size() == 1:
		return 0
	var spawn := rooms[0].get_center()
	var best := 1
	var best_score := -1.0
	for i in range(1, rooms.size()):
		var area := float(rooms[i].size.x * rooms[i].size.y)
		var dist := Vector2(rooms[i].get_center() - spawn).length()
		var score := area * 100.0 + dist
		if score > best_score:
			best_score = score
			best = i
	return best


func _farthest_room(rooms: Array[Rect2i]) -> int:
	var spawn := rooms[0].get_center()
	var far_index := 0
	var far_dist := -1.0
	for i in range(1, rooms.size()):
		var dist := Vector2(rooms[i].get_center() - spawn).length()
		if dist > far_dist:
			far_dist = dist
			far_index = i
	return far_index


func _spawn_mists(room: Rect2i, gold: bool) -> Array[Node3D]:
	# One continuous curtain per contiguous opening on the room's
	# ring — a corridor running alongside can open a whole side, and
	# that gets a single spanning curtain, not a bank of panels.
	var mists: Array[Node3D] = []
	for side_y in [room.position.y - 1, room.end.y]:
		# The curtain hangs in the wall plane between ring and room,
		# not at the ring cell's center.
		var boundary := float(side_y + 1 if side_y < room.position.y else side_y) \
				* CELL_SIZE
		var run_start := -1
		for cx in range(room.position.x, room.end.x + 1):
			var open := cx < room.end.x and _is_open_cell(Vector2i(cx, side_y))
			if open and run_start < 0:
				run_start = cx
			elif not open and run_start >= 0:
				mists.append(_spawn_curtain(
					Vector2(run_start, cx - 1), boundary, false, gold))
				run_start = -1
	for side_x in [room.position.x - 1, room.end.x]:
		var boundary := float(side_x + 1 if side_x < room.position.x else side_x) \
				* CELL_SIZE
		var run_start := -1
		for cy in range(room.position.y, room.end.y + 1):
			var open := cy < room.end.y and _is_open_cell(Vector2i(side_x, cy))
			if open and run_start < 0:
				run_start = cy
			elif not open and run_start >= 0:
				mists.append(_spawn_curtain(
					Vector2(run_start, cy - 1), boundary, true, gold))
				run_start = -1
	# Wooden walls on the ring get a hidden curtain just inside the
	# room: smash the wall mid-fight and the seal is already there.
	# (Never convert ring wood to stone — that broke the solvability
	# proof and stranded players.)
	for side_y in [room.position.y - 1, room.end.y]:
		var b := float(side_y + 1 if side_y < room.position.y else side_y) * CELL_SIZE
		b += 0.06 if side_y < room.position.y else -0.06
		for cx in range(room.position.x, room.end.x):
			if _cell_id(Vector2i(cx, side_y)) == wall_wood_id:
				mists.append(_spawn_curtain(Vector2(cx, cx), b, false, gold))
	for side_x in [room.position.x - 1, room.end.x]:
		var b := float(side_x + 1 if side_x < room.position.x else side_x) * CELL_SIZE
		b += 0.06 if side_x < room.position.x else -0.06
		for cy in range(room.position.y, room.end.y):
			if _cell_id(Vector2i(side_x, cy)) == wall_wood_id:
				mists.append(_spawn_curtain(Vector2(cy, cy), b, true, gold))
	return mists


func _cell_id(cell: Vector2i) -> int:
	return grid_map.get_cell_item(Vector3i(cell.x, 0, cell.y))


func _is_open_cell(cell: Vector2i) -> bool:
	var id := _cell_id(cell)
	return id == floor_id or id == floor_wood_id or id == floor_wood_pale_id


func _spawn_curtain(run: Vector2, boundary: float, horizontal: bool, gold: bool) -> Node3D:
	# run = first/last cell index along the open edge; boundary = the
	# world coordinate of the wall plane the mist stands in for.
	var length := (run.y - run.x + 1.0) * CELL_SIZE
	var mid := (run.x + run.y) * 0.5 * CELL_SIZE + 1.0
	var mist := MIST_SCENE.instantiate()
	mist.gold = gold
	mist.span = length
	if horizontal:
		mist.position = Vector3(boundary, 0.5, mid)
		mist.rotation_degrees = Vector3(0, 90, 0)
	else:
		mist.position = Vector3(mid, 0.5, boundary)
	add_child(mist)
	return mist


func _place_hatch(rooms: Array[Rect2i], exclude_idx := -1) -> void:
	# Stages within a world connect by pale mist gates — worlds are
	# places, and only the boss floor has a true downward hatch. The
	# gate lives in the room farthest from where you start, on proven
	# stone; fall back through rooms by distance if a room is wooden
	# wall-to-wall.
	var spawn := rooms[0].get_center()
	var order: Array[int] = []
	for i in range(1, rooms.size()):
		if i != exclude_idx:
			order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		return Vector2(rooms[a].get_center() - spawn).length() \
				> Vector2(rooms[b].get_center() - spawn).length())
	order.append(0)
	# Prefer a stone cell against a wall: the gate presses into the
	# wall face like a misty doorway, not a free-standing curtain.
	for i in order:
		if _place_against_wall(MIST_GATE_SCENE, rooms[i]):
			return
	# Fallback: no wall-adjacent stone anywhere — free-standing.
	for i in order:
		var cells := _stone_cells(rooms[i])
		if cells.size() > 0:
			var gate := MIST_GATE_SCENE.instantiate()
			gate.position = _cell_to_world(
				cells[randi_range(0, cells.size() - 1)], 0.5)
			add_child(gate)
			return


func _place_against_wall(scene: PackedScene, room: Rect2i) -> bool:
	# Stand something flat against a wall face, front toward the
	# room. Used by mist gates and arrival doors.
	var cells := _stone_cells(room)
	cells.shuffle()
	for c in cells:
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if _cell_id(c + d) != wall_id:
				continue
			var node := scene.instantiate()
			var center := _cell_to_world(c, 0.5)
			if d.x != 0:
				var face_x := (c.x + (1 if d.x > 0 else 0)) * CELL_SIZE
				node.position = Vector3(face_x - d.x * 0.03, 0.5, center.z)
			else:
				var face_z := (c.y + (1 if d.y > 0 else 0)) * CELL_SIZE
				node.position = Vector3(center.x, 0.5, face_z - d.y * 0.03)
			node.rotation_degrees = Vector3(0,
					rad_to_deg(atan2(float(-d.x), float(-d.y))), 0)
			add_child(node)
			return true
	return false


func _stone_cells(room: Rect2i) -> Array[Vector2i]:
	# Cells the worst-case flood fill has proven reachable: stone
	# floor only. Key objects and pickups never sit on wood — a thing
	# hovering over a future hole is a stranded thing.
	var cells: Array[Vector2i] = []
	for cy in range(room.position.y, room.end.y):
		for cx in range(room.position.x, room.end.x):
			if grid_map.get_cell_item(Vector3i(cx, 0, cy)) == floor_id:
				cells.append(Vector2i(cx, cy))
	return cells


func _cell_to_world(cell: Vector2i, y: float = 1.5) -> Vector3:
	# Cell center; default y = 1.5 stands a 2m-tall body on the 0.5m
	# floor slab. Pass y = 0.5 to sit something on the floor itself.
	return Vector3(cell.x * CELL_SIZE + 1.0, y, cell.y * CELL_SIZE + 1.0)
