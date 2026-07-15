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
const BOOTS_PICKUP_SCENE := preload("res://scenes/boots_pickup.tscn")
const ARMOR_PICKUP_SCENE := preload("res://scenes/armor_pickup.tscn")
const ARMOR2_PICKUP_SCENE := preload("res://scenes/armor2_pickup.tscn")
const STAFF_PICKUP_SCENE := preload("res://scenes/staff_pickup.tscn")
const BOOMERANG_PICKUP_SCENE := preload("res://scenes/boomerang_pickup.tscn")
const MIST_SCENE := preload("res://scenes/mist_door.tscn")
const BOSS_PLATE_SCENE := preload("res://scenes/sword_trigger.tscn")
const SKELETAL_WIZARD_SCENE := preload("res://scenes/skeletal_wizard.tscn")
const SOUND_FLOOR_NORMAL := preload("res://assets/audio/sfx/environment/normal_floor_start.wav")
const SOUND_FLOOR_BOSS := preload("res://assets/audio/sfx/environment/boss_floor_start.wav")
const SOUND_FLOOR_ITEM := preload("res://assets/audio/sfx/environment/item_floor_start.wav")
const SOUND_DOOR_LOCK := preload("res://assets/audio/sfx/environment/boss_room_door_lock.wav")
const SOUND_ITEM_MIST := preload("res://assets/audio/sfx/environment/item_room_mist_door.wav")

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

var floor_id := -1
var wall_id := -1
var floor_wood_id := -1
var wall_wood_id := -1
var hole_id := -1
var ceiling_id := -1

var wall_damage := {}
var last_player_cell := Vector3i(-9999, 0, -9999)
var floor_rooms: Array[Rect2i] = []
var kind: int = RunState.FloorKind.REGULAR

# Boss floor state
var arena_room_idx := -1
var arena_mists: Array[Node3D] = []
var boss_index := 0
var fight_active := false
var fight_grace := 0.0
var amalgam_stage := 0  # 0 = wave, 1 = assembling, 2 = amalgam active
var boss_hatch: Node3D = null
var boss_hatch_cell := Vector2i(-1, -1)

# Item floor state
var item_room_idx := -1
var item_mists: Array[Node3D] = []
var item_pedestals: Array[Node3D] = []
var item_sealed := false
var item_resolved := false

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
	floor_rooms = rooms
	kind = RunState.floor_kind(RunState.depth)

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
	if kind == RunState.FloorKind.BOSS:
		arena_room_idx = _largest_room(rooms)
		_populate(rooms, arena_room_idx, false)
		_setup_boss_room()
	elif kind == RunState.FloorKind.ITEM:
		item_room_idx = _farthest_room(rooms)
		_populate(rooms, item_room_idx, true, item_room_idx)
		_setup_item_room()
	else:
		_populate(rooms)
	last_player_cell = _player_cell()

	# Every floor announces itself.
	if kind == RunState.FloorKind.BOSS:
		_play_stinger(SOUND_FLOOR_BOSS)
	elif kind == RunState.FloorKind.ITEM:
		_play_stinger(SOUND_FLOOR_ITEM)
	else:
		_play_stinger(SOUND_FLOOR_NORMAL)


func _physics_process(_delta: float) -> void:
	# Wooden floors give way behind you: when the player leaves a
	# plank cell, it may collapse into a hole.
	var cell := _player_cell()
	if cell != last_player_cell:
		if grid_map.get_cell_item(last_player_cell) == floor_wood_id \
				and randf() < FLOOR_COLLAPSE_CHANCE \
				and _player_keeps_path_to_stone(last_player_cell, cell):
			grid_map.set_cell_item(last_player_cell, GridMap.INVALID_CELL_ITEM)
			hole_map.set_cell_item(last_player_cell, hole_id)
		last_player_cell = cell

	if fight_active:
		fight_grace = maxf(fight_grace - _delta, 0.0)
		if fight_grace == 0.0 and not _arena_has_living_enemies():
			if boss_index >= 2 and amalgam_stage == 0:
				# Phase two: the bodies got up.
				amalgam_stage = 1
				_begin_assembly()
			elif amalgam_stage != 1:
				_finish_boss_fight()

	if item_room_idx >= 0 and not item_resolved:
		if not item_sealed:
			if _player_inside_room(floor_rooms[item_room_idx]):
				item_sealed = true
				_play_stinger(SOUND_ITEM_MIST)
				for m in item_mists:
					if is_instance_valid(m):
						m.seal()
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
	if grid_map.get_cell_item(cell) != wall_wood_id:
		return
	wall_damage[cell] = wall_damage.get(cell, 0) + amount
	if wall_damage[cell] >= WOOD_WALL_HITS:
		grid_map.set_cell_item(cell, floor_id)
		# The opened cell needs a lid too, or you'd see the void.
		grid_map.set_cell_item(cell + Vector3i(0, 1, 0), ceiling_id)


func _unhandled_input(event: InputEvent) -> void:
	# R rerolls the whole dungeon (debug key) — never mid-boss-fight.
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		if fight_active:
			return
		get_tree().reload_current_scene()


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
		if id != floor_wood_id and c != start:
			continue
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n := c + d
			if n == banned or visited.has(n):
				continue
			var nid := grid_map.get_cell_item(Vector3i(n.x, 0, n.y))
			if nid == floor_id or nid == floor_wood_id:
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
			# Boss 2 — the Mush Boss: two megas, four mushes, eight
			# minis. Four seconds to kill each half before re-fusion.
			var mush := MUSH_SCENE.instantiate()
			mush.configure(mush.State.BOSS, mush.BOSS_MAX_HEALTH)
			mush.position = _cell_to_world(center)
			add_child(mush)
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


func _begin_assembly() -> void:
	# Everything stops. Every corpse in the arena — every body the
	# player made — drags itself slowly toward the centre.
	var arena := floor_rooms[arena_room_idx]
	var min_x := arena.position.x * CELL_SIZE - 3.0
	var max_x := arena.end.x * CELL_SIZE + 3.0
	var min_z := arena.position.y * CELL_SIZE - 3.0
	var max_z := arena.end.y * CELL_SIZE + 3.0
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
	var min_x := arena.position.x * CELL_SIZE - 3.0
	var max_x := arena.end.x * CELL_SIZE + 3.0
	var min_z := arena.position.y * CELL_SIZE - 3.0
	var max_z := arena.end.y * CELL_SIZE + 3.0
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
	# The reward is earned by the fight.
	var reward: Node3D = null
	match boss_index:
		0:
			if not RunState.has_sword:
				reward = SWORD_SCENE.instantiate()
		1:
			reward = CONTAINER_PICKUP_SCENE.instantiate()
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

func _setup_item_room() -> void:
	var room := floor_rooms[item_room_idx]
	item_mists = _spawn_mists(room, true)
	var cells := _stone_cells(room)
	cells.shuffle()
	if cells.is_empty():
		var center := room.get_center()
		grid_map.set_cell_item(Vector3i(center.x, 0, center.y), floor_id)
		cells.append(center)
	# The pedestal pool: what the run hasn't granted yet. Two are
	# offered; taking one seals away the other.
	var pool: Array[PackedScene] = [MAGIC_PICKUP_SCENE]
	if player.max_health < player.MAX_HEALTH_CAP:
		pool.append(CONTAINER_PICKUP_SCENE)
	if not RunState.has_boots:
		pool.append(BOOTS_PICKUP_SCENE)
	if RunState.armor_tier == 0:
		pool.append(ARMOR_PICKUP_SCENE)
	elif RunState.armor_tier == 1:
		pool.append(ARMOR2_PICKUP_SCENE)
	if RunState.has_sword and not RunState.has_staff \
			and not RunState.has_boomerang:
		# Rival weapons: taking either removes both from future pools.
		pool.append(STAFF_PICKUP_SCENE)
		pool.append(BOOMERANG_PICKUP_SCENE)
	pool.shuffle()
	var count := mini(2, mini(pool.size(), cells.size()))
	for i in count:
		var pedestal := pool[i].instantiate()
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
	return id == floor_id or id == floor_wood_id


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
	# The way down lives in the room farthest from where you start —
	# but only ever on proven stone; fall back through rooms by
	# distance if a room is wooden wall-to-wall.
	var spawn := rooms[0].get_center()
	var order: Array[int] = []
	for i in range(1, rooms.size()):
		if i != exclude_idx:
			order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		return Vector2(rooms[a].get_center() - spawn).length() \
				> Vector2(rooms[b].get_center() - spawn).length())
	order.append(0)
	for i in order:
		var cells := _stone_cells(rooms[i])
		if cells.size() > 0:
			var hatch := HATCH_SCENE.instantiate()
			hatch.position = _cell_to_world(
				cells[randi_range(0, cells.size() - 1)], 0.5)
			add_child(hatch)
			return


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
