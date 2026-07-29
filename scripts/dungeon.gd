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
const HEART_CACHE_DROP_SCENE := preload("res://scenes/magic_heart_drop.tscn")
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
const BARRELSTONE_SCENE := preload("res://scenes/barrelstone_pickup.tscn")
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
const SOUND_WALL_PARTIAL := preload("res://assets/audio/sfx/environment/broken_partial_wall.ogg")
const SOUND_SECRET_GRIND := preload("res://assets/audio/sfx/environment/secretroom_wallslidegrind1.wav")
const SOUND_FLOOR_BREAK := preload("res://assets/audio/sfx/environment/broken_floor1.wav")
const SOUND_ITEM_MIST := preload("res://assets/audio/sfx/environment/item_room_mist_door.wav")
const HATCH_TEXTURE := preload("res://assets/tiles/hatch_open.png")
const HOLE_EDGE_TEXTURE := preload("res://assets/tiles/floor_hole_edge.png")
const HOLE_RIM_INSET := 0.03  # nudge the lip off the stone face (no z-fight)
const HOLE_RIM_HEIGHT := 1.0  # metres of wood band below the floor top; the
							  # deep stone tile face shows below it (0.5 ≈ the
							  # true plank thickness, higher = a chunkier lip)
const FLOOR_BREAK_FRAMES: Array[Texture2D] = [
	preload("res://assets/tiles/floor_wooden_break1.png"),
	preload("res://assets/tiles/floor_wooden_break2.png"),
	preload("res://assets/tiles/floor_wooden_break3.png"),
]
const WALL_BREAK_FRAMES: Array[Texture2D] = [
	preload("res://assets/tiles/wall_wooden_break1.png"),
	preload("res://assets/tiles/wall_wooden_break2.png"),
	preload("res://assets/tiles/wall_wooden_break3.png"),
]
# Persistent splinter piles left where a wooden wall gave way — one
# picked at random, laid flat like the mush/slime splats. Aftermath.
const WALL_RUBBLE_FRAMES: Array[Texture2D] = [
	preload("res://assets/tiles/wall_wooden_broken1.png"),
	preload("res://assets/tiles/wall_wooden_broken2.png"),
	preload("res://assets/tiles/wall_wooden_broken3.png"),
]
const BREAK_FRAME_TIME := 0.07
const WALL_BREAK_Y := 1.5  # eye/torch height on the 4m opening
const SECRET_SLIDE_TIME := 3.0  # matches the stone-grind sound length
const CEILING_TALL_CHANCE := 0.35   # a regular room's odds of a raised ceiling
const CEILING_CATHEDRAL_CHANCE := 0.2  # of raised rooms, odds of +2 vs +1 layer
const CEILING_GRAND_LAYERS := 2     # boss arenas + item rooms go this tall
const BOSS_DROP_LAYERS := 3         # the amalgam chamber sits this many cell-
                                    # layers (4m each) below the boss arena

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
# Scattered magic-heart planks: pale-tinted like the commoner secret,
# but they break onto stone and give up a single magic heart, not a room.
const HEART_CACHE_MIN := 0  # per floor; 0-2 keeps them a treat, not a supply run
const HEART_CACHE_MAX := 2

var floor_id := -1
var wall_id := -1
var floor_wood_id := -1
var wall_wood_id := -1
var wall_wood_partial_id := -1
var hole_id := -1
var void_id := -1
var ceiling_id := -1
var wall_fill_id := -1
var wall_upper_id := -1
var wall_upper_variants: Array[int] = []
var buried_stone_id := -1
var floor_wood_pale_id := -1

var wall_damage := {}
var hole_rims_root: Node3D  # container for the torn-lip sprites around holes
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
var boss_floor_dropped := false  # the arena floor has caved into the chamber
var boss_plate: Node3D = null    # the consent plate, so the drop can clear it
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
var heart_caches: Array[Vector2i] = []  # cells holding a magic-heart plank

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


# --- Per-world tile appearances (docs/tile-appearances.md) ---
# One look per WORLD (the first label number); all three stages share it.
# A world points at a folder under assets/tiles/; the shared tile materials
# have their albedo_texture reskinned to that folder at floor load. The
# geometry contract (dungeon_tiles.tres meshes/shapes, the ASCII grid) is
# untouched — this is paint only. Index by world; [0] and out-of-range worlds
# (endless descent past the demo) fall back to the nearest built look.
const WORLD_APPEARANCE := ["dry", "dry", "damp", "deep"]
# Which contract texture each reskinnable tile material pulls from the folder.
# Names are fixed and identical across every appearance folder (the contract).
# Shared materials ride along: wall_fill uses "wall"; floor_wood_pale reuses
# the wood texture and keeps its own cool tint.
const APPEARANCE_TEXTURES := {
	"floor": "floor_stone.png",
	"wall": "wall_stone.png",
	"ceiling": "ceiling_stone.png",
	"floor_wood": "floor_wooden.png",
	"floor_wood_pale": "floor_wooden.png",
	"wall_wood": "wall_wooden.png",
	"wall_wood_partial": "wall_wooden_partially_broken.png",
	"wall_upper1": "wall_stone_upper1.png",
	"wall_upper2": "wall_stone_upper2.png",
}


func _apply_appearance(world: int) -> void:
	var idx := clampi(world, 1, WORLD_APPEARANCE.size() - 1)
	var folder: String = WORLD_APPEARANCE[idx]
	var lib := grid_map.mesh_library
	for item_name: String in APPEARANCE_TEXTURES:
		var id := lib.find_item_by_name(item_name)
		if id < 0:
			continue
		var mesh := lib.get_item_mesh(id)
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		var mat := mesh.surface_get_material(0) as StandardMaterial3D
		if mat == null:
			continue
		var path := "res://assets/tiles/%s/%s" % [folder, APPEARANCE_TEXTURES[item_name]]
		if ResourceLoader.exists(path):
			mat.albedo_texture = load(path) as Texture2D


func _ready() -> void:
	MusicDrift.begin()  # the dungeon owns the drifting ambient; the title stays quiet
	floor_id = grid_map.mesh_library.find_item_by_name("floor")
	wall_id = grid_map.mesh_library.find_item_by_name("wall")
	floor_wood_id = grid_map.mesh_library.find_item_by_name("floor_wood")
	wall_wood_id = grid_map.mesh_library.find_item_by_name("wall_wood")
	wall_wood_partial_id = grid_map.mesh_library.find_item_by_name("wall_wood_partial")
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
	wall_fill_id = grid_map.mesh_library.find_item_by_name("wall_fill")
	# Re-skin the shared tile materials for THIS world's look (texture only —
	# the meshes, shapes, and the ASCII the generator emits never change).
	_apply_appearance(RunState.world(RunState.depth))

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
	_vary_ceilings()
	if RunState.stage(RunState.depth) != 1:
		# The sealed doorway you arrived through — bare frame, stone
		# showing through, no way back.
		_place_against_wall(ARRIVAL_DOOR_SCENE, rooms[0])
	else:
		# You fell onto this floor: land hard as the mist clears, and the
		# hatch you dropped through hangs overhead, dark and out of reach.
		player.land_hard()
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
	_place_heart_caches()

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
				# Phase two: the floor gives way — the fight, the player,
				# and every corpse plunge into the chamber, where the
				# bodies drag together and rise as one.
				amalgam_stage = 1
				_drop_into_assembly()
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
		if heart_caches.has(Vector2i(cell.x, cell.z)):
			# A cache plank: cracks onto stone and gives up its heart.
			_reveal_heart_cache(cell)
			return
		grid_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
		hole_map.set_cell_item(cell, hole_id)
		Sfx.play_at(SOUND_FLOOR_BREAK,
				_cell_to_world(Vector2i(cell.x, cell.z), 0.5), -6.0)
		_spawn_floor_break_effect(cell)
		_drop_the_unsupported(cell)
		_rebuild_hole_rims()
		return
	if id != wall_wood_id and id != wall_wood_partial_id:
		return
	wall_damage[cell] = wall_damage.get(cell, 0) + amount
	if wall_damage[cell] >= WOOD_WALL_HITS:
		grid_map.set_cell_item(cell, floor_id)
		# The opened cell needs a lid, or you'd see the void — UNLESS a tall
		# room already filled the column above with wall_fill, which caps the
		# opening at 4m AND closes the transom up to the raised ceiling. Keep
		# that; a plain lid would re-open the gap above the doorway.
		if grid_map.get_cell_item(cell + Vector3i(0, 1, 0)) != wall_fill_id:
			grid_map.set_cell_item(cell + Vector3i(0, 1, 0), ceiling_id)
		Sfx.play_at(SOUND_WALL_BREAK,
				_cell_to_world(Vector2i(cell.x, cell.z), 1.0), -5.0)
		_spawn_wall_break_effect(cell)
		_spawn_wall_rubble(cell)
	else:
		# Not broken yet: swap the whole tile to its splintered variant
		# (cracks on all four faces) plus a crack of sound — feedback that
		# the wall is giving. The break above overwrites it with floor.
		if id == wall_wood_id:
			grid_map.set_cell_item(cell, wall_wood_partial_id)
		Sfx.play_at(SOUND_WALL_PARTIAL,
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
	if heart_caches.has(Vector2i(cell.x, cell.z)):
		# A cache plank underfoot: it gives up its heart onto stone.
		_reveal_heart_cache(cell)
		return
	var standing := _player_cell()
	if cell == standing or not _player_keeps_path_to_stone(cell, standing):
		return
	grid_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
	hole_map.set_cell_item(cell, hole_id)
	Sfx.play_at(SOUND_FLOOR_BREAK,
			_cell_to_world(Vector2i(cell.x, cell.z), 0.5), -8.0)
	_spawn_floor_break_effect(cell)
	_drop_the_unsupported(cell)
	_rebuild_hole_rims()


func _spawn_floor_break_effect(cell: Vector3i) -> void:
	# The plank splinters as it falls away: three top-down frames of
	# cracking, laid flat over the cell just above the floor, then gone
	# to the dark. Purely cosmetic — the hole and its physics already
	# applied, so this shatter plays over the newly-open shaft.
	var s := Sprite3D.new()
	s.texture = FLOOR_BREAK_FRAMES[0]
	s.pixel_size = 0.03125
	s.shaded = true
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	s.rotation_degrees = Vector3(-90, 0, 0)
	add_child(s)
	s.position = _cell_to_world(Vector2i(cell.x, cell.z), 0.53)
	_play_break_frames(s, FLOOR_BREAK_FRAMES)


func _spawn_wall_break_effect(cell: Vector3i) -> void:
	# The plank wall gives in a burst of splinters: three frames on an
	# upright billboard standing in the just-opened doorway, then gone.
	# Purely cosmetic — the cell is already floor + lidded overhead.
	var s := Sprite3D.new()
	s.texture = WALL_BREAK_FRAMES[0]
	s.pixel_size = 0.03125
	s.shaded = true
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	add_child(s)
	s.position = _cell_to_world(Vector2i(cell.x, cell.z), WALL_BREAK_Y)
	_play_break_frames(s, WALL_BREAK_FRAMES)


func _spawn_wall_rubble(cell: Vector3i) -> void:
	# What the wall leaves behind: a flat pile of splinters on the newly
	# opened floor, one of three at a random spin. Persistent — no tween,
	# it stays for the floor like the mush/slime splats. Aftermath.
	var s := Sprite3D.new()
	s.texture = WALL_RUBBLE_FRAMES[randi_range(0, WALL_RUBBLE_FRAMES.size() - 1)]
	s.pixel_size = 0.03125
	s.shaded = true
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	s.rotation_degrees = Vector3(-90, randf() * 360.0, 0)
	add_child(s)
	s.position = _cell_to_world(Vector2i(cell.x, cell.z), 0.53)


func _play_break_frames(s: Sprite3D, frames: Array[Texture2D]) -> void:
	# Step a splinter sprite through its frames, then free it.
	var tw := s.create_tween()
	for i in range(1, frames.size()):
		tw.tween_interval(BREAK_FRAME_TIME)
		tw.tween_callback(s.set_texture.bind(frames[i]))
	tw.tween_interval(BREAK_FRAME_TIME)
	tw.tween_callback(s.queue_free)


func _rebuild_hole_rims() -> void:
	# Line every open shaft edge that still borders solid floor with an
	# upright torn lip — the cross-section of what the plank was keyed into.
	# Rebuilt wholesale from the HoleMap on each hole event, so growing and
	# connected holes always show rims on their true OUTER edge only, and
	# never a seam left floating over open space. Kept in a container so the
	# collapse-sink pass (which scans the dungeon's direct children) can't
	# mistake a rim for loose cargo.
	if hole_rims_root == null:
		hole_rims_root = Node3D.new()
		hole_rims_root.name = "HoleRims"
		add_child(hole_rims_root)
	for old in hole_rims_root.get_children():
		old.queue_free()
	for cell in hole_map.get_used_cells_by_item(hole_id):
		var c := Vector2i(cell.x, cell.z)
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if _is_open_cell(c + d):
				_place_hole_rim(c, d)


func _place_hole_rim(c: Vector2i, d: Vector2i) -> void:
	# One upright lip on the boundary between hole cell c and its solid
	# neighbour c+d, facing into the hole (normal = -d). The 2m art hangs
	# from the floor top (0.5) down the shaft, so its centre sits at -0.5;
	# nudged a hair off the stone face it clings to.
	var rim := Sprite3D.new()
	rim.texture = HOLE_EDGE_TEXTURE
	rim.pixel_size = 0.03125
	rim.shaded = true
	rim.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	rim.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	rim.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	rim.rotation.y = atan2(-float(d.x), -float(d.y))
	# A wood band capping the shaft: top flush with the floor surface (0.5),
	# hanging down HOLE_RIM_HEIGHT so the deep stone tile face shows below —
	# the plank was only ever a thin layer over stone. The art is a 64x32
	# strip (2m wide x 1m tall here), so height maps straight to the knob —
	# native and undistorted at 1.0.
	rim.scale.y = HOLE_RIM_HEIGHT
	var mid_y := 0.5 - HOLE_RIM_HEIGHT * 0.5
	var base := _cell_to_world(c, mid_y)
	rim.position = Vector3(
		base.x + float(d.x) * (1.0 - HOLE_RIM_INSET),
		base.y,
		base.z + float(d.y) * (1.0 - HOLE_RIM_INSET))
	hole_rims_root.add_child(rim)


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


func _place_heart_caches() -> void:
	# A few marked planks tucked INTO the wooden patches — the same pale
	# tell and buried-stone pillar as the commoner secret, but they hide
	# a magic heart, not a room. Placed on EXISTING WOOD beside other
	# wood (not a lone stone tile), so a cache reads as one of a breakable
	# group rather than an odd tile out. Still safe after the solvability
	# proof: a cache always breaks back to walkable stone, never a hole —
	# strictly safer than a plank that could collapse. Spawn and ceremony
	# rooms stay clean.
	var count := randi_range(HEART_CACHE_MIN, HEART_CACHE_MAX)
	if count <= 0:
		return
	var skip: Array[Rect2i] = []
	if floor_rooms.size() > 0:
		skip.append(floor_rooms[0])
	if kind == RunState.FloorKind.BOSS and arena_room_idx >= 0:
		skip.append(floor_rooms[arena_room_idx])
	elif kind == RunState.FloorKind.ITEM and item_room_idx >= 0:
		skip.append(floor_rooms[item_room_idx])
	# Prefer wooden cells that touch other wood (a real group); fall back
	# to any wooden cell only if no grouped one exists. The secret plank
	# is already pale, so scanning for plain wood naturally skips it.
	var grouped: Array[Vector2i] = []
	var lone: Array[Vector2i] = []
	for x in GRID_WIDTH:
		for z in GRID_HEIGHT:
			if grid_map.get_cell_item(Vector3i(x, 0, z)) != floor_wood_id:
				continue
			var c := Vector2i(x, z)
			var blocked := false
			for r: Rect2i in skip:
				if r.has_point(c):
					blocked = true
					break
			if blocked:
				continue
			if _has_wood_neighbor(c):
				grouped.append(c)
			else:
				lone.append(c)
	var pool: Array[Vector2i] = grouped if not grouped.is_empty() else lone
	pool.shuffle()
	for i in mini(count, pool.size()):
		var c: Vector2i = pool[i]
		grid_map.set_cell_item(Vector3i(c.x, 0, c.y), floor_wood_pale_id)
		# The buried stone pillar underneath — the second tell glimpsed
		# from a neighboring hole, and what makes the cache break to stone
		# rather than open a shaft.
		hole_map.set_cell_item(Vector3i(c.x, 0, c.y), buried_stone_id)
		heart_caches.append(c)


func _has_wood_neighbor(c: Vector2i) -> bool:
	# True if an orthogonal neighbour is any wooden floor (plain or pale).
	for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var nid := grid_map.get_cell_item(Vector3i(c.x + d.x, 0, c.y + d.y))
		if nid == floor_wood_id or nid == floor_wood_pale_id:
			return true
	return false


func _reveal_heart_cache(cell: Vector3i) -> void:
	# The plank splinters onto stone and gives up what it hid: a single
	# magic heart, resting where the boards were.
	heart_caches.erase(Vector2i(cell.x, cell.z))
	grid_map.set_cell_item(cell, floor_id)
	hole_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
	Sfx.play_at(SOUND_FLOOR_BREAK,
			_cell_to_world(Vector2i(cell.x, cell.z), 0.5), -6.0)
	_spawn_floor_break_effect(cell)
	var heart: Node3D = HEART_CACHE_DROP_SCENE.instantiate()
	# Raised a full heart-height (16px = 0.5m) so it rests ON the stone
	# instead of sunk into it — roughly level with enemy-dropped hearts.
	heart.position = _cell_to_world(Vector2i(cell.x, cell.z), 0.6)
	add_child(heart)


func _open_secret_room() -> void:
	# One wall cell slides aside: the chamber was always there.
	if secret_opened or secret_door == Vector2i(-1, -1):
		return
	secret_opened = true
	var door := Vector3i(secret_door.x, 0, secret_door.y)
	# Grab the upper-band id before we clear the maps — the slide needs a
	# copy of the exact stone that was standing here.
	var upper_prev := upper_map.get_cell_item(door)
	# Open the passage in the STATIC maps at once (floor + ceiling in, wall
	# + band out); the slide below is a purely visual prop laid on top.
	grid_map.set_cell_item(door, floor_id)
	grid_map.set_cell_item(door + Vector3i(0, 1, 0), ceiling_id)
	upper_map.set_cell_item(door, GridMap.INVALID_CELL_ITEM)
	Sfx.play_at(SOUND_SECRET_GRIND, _cell_to_world(secret_door, 1.0), -3.0)
	_slide_secret_wall(door, upper_prev)
	# The commoner pays in gold: three hearts at the chamber's heart.
	var center := Vector3.ZERO
	for c in secret_room_cells:
		center += _cell_to_world(c, 0.5)
	center /= secret_room_cells.size()
	var hearts := MAGIC_PICKUP_SCENE.instantiate()
	hearts.position = center
	add_child(hearts)


func _slide_secret_wall(door: Vector3i, upper_prev: int) -> void:
	# A movable copy of the door wall (lower block + decorative band) slides
	# one cell along the wall run and tucks into the neighbouring stone, so
	# the opening reads as a slab grinding aside rather than blinking away.
	# GridMap cells can't move, hence the copy; the static maps are already
	# open underneath it. Freed when the grind finishes.
	var through := Vector2i.ZERO  # cell step from door INTO the hidden room
	for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if secret_room_cells.has(secret_door + d):
			through = d
			break
	# Slide perpendicular to the passage; prefer the side backed by stone so
	# the slab disappears into a wall, not across the open doorway.
	var slide := Vector2i(through.y, through.x)
	if slide == Vector2i.ZERO:
		slide = Vector2i(1, 0)
	var into := Vector3i(secret_door.x + slide.x, 0, secret_door.y + slide.y)
	if grid_map.get_cell_item(into) != wall_id:
		slide = -slide

	var mover := Node3D.new()
	add_child(mover)
	var lib := grid_map.mesh_library
	var lower := MeshInstance3D.new()
	lower.mesh = lib.get_item_mesh(wall_id)
	lower.transform = Transform3D(Basis(), grid_map.map_to_local(door)) \
			* lib.get_item_mesh_transform(wall_id)
	mover.add_child(lower)
	if upper_prev != GridMap.INVALID_CELL_ITEM:
		var band := MeshInstance3D.new()
		band.mesh = upper_map.mesh_library.get_item_mesh(upper_prev)
		band.transform = Transform3D(Basis(), upper_map.map_to_local(door)) \
				* upper_map.mesh_library.get_item_mesh_transform(upper_prev)
		mover.add_child(band)

	var target := Vector3(slide.x * 2.0, 0.0, slide.y * 2.0)
	var tw := create_tween()
	tw.tween_property(mover, "position", target, SECRET_SLIDE_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(mover.queue_free)


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


func _vary_ceilings() -> void:
	# Roll a ceiling height per room for variety (visual only). The spawn
	# room stays standard — its hatch/arrival door sits at the standard
	# height; boss arenas and item rooms go grand; the rest mostly stay
	# standard, with the occasional tall chamber and a rare cathedral.
	for i in floor_rooms.size():
		if i == 0:
			continue  # spawn stays standard, always
		var extra := 0
		if i == arena_room_idx or i == item_room_idx:
			extra = CEILING_GRAND_LAYERS
		elif randf() < CEILING_TALL_CHANCE:
			extra = 2 if randf() < CEILING_CATHEDRAL_CHANCE else 1
		if extra > 0:
			_raise_room(floor_rooms[i], extra)


func _raise_room(room: Rect2i, extra: int) -> void:
	# Lift a room's ceiling by `extra` cell-layers (4m each) and fill its
	# perimeter walls up to meet it. Purely visual — the play space is the
	# floor plane. The torch can't reach up there, so the top dissolves
	# into shadow: walls rising into the dark (the Barony effect).
	if extra <= 0 or wall_fill_id < 0:
		return
	# The room's own floor cells get their ceiling raised to the new layer.
	for x in range(room.position.x, room.end.x):
		for z in range(room.position.y, room.end.y):
			if not _is_open_cell(Vector2i(x, z)):
				continue
			grid_map.set_cell_item(Vector3i(x, 1, z), GridMap.INVALID_CELL_ITEM)
			grid_map.set_cell_item(Vector3i(x, 1 + extra, z), ceiling_id)
	# Fill the 1-cell border frame from the band-top (4m) up to the ceiling.
	# Wall cells raise the wall; a DOORWAY (a floor opening in the frame)
	# gets its transom filled too — otherwise a gap yawns above the door
	# into the dark ("a fake doorway above the doorway"). The fill's bottom
	# face caps the corridor at 4m, so the door stays a normal opening. The
	# interior is left as open air — that's the whole point.
	for x in range(room.position.x - 1, room.end.x + 1):
		for z in range(room.position.y - 1, room.end.y + 1):
			if x >= room.position.x and x < room.end.x \
					and z >= room.position.y and z < room.end.y:
				continue  # interior floor — leave the tall space open
			var base := grid_map.get_cell_item(Vector3i(x, 0, z))
			if base != wall_id and base != wall_wood_id \
					and not _is_open_cell(Vector2i(x, z)):
				continue  # not a wall (stone OR breakable wood) nor a doorway
			for layer in range(1, 1 + extra):
				grid_map.set_cell_item(Vector3i(x, layer, z), wall_fill_id)


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
	_face_spawn_doorway(rooms[0])
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


func _face_spawn_doorway(room: Rect2i) -> void:
	# Spawn looking down a corridor mouth instead of at a blank wall: find
	# the nearest walkable cell just OUTSIDE the room (a doorway a corridor
	# punched through) and yaw the player toward it. Sealed arrival doors
	# aren't floor, so they're never chosen; an x-1 hatch room with no
	# ground exit would simply keep the default facing.
	var center := room.get_center()
	var best := Vector2i.ZERO
	var best_dist := INF
	for x in range(room.position.x - 1, room.end.x + 1):
		for z in range(room.position.y - 1, room.end.y + 1):
			var c := Vector2i(x, z)
			if room.has_point(c) or not _is_open_cell(c):
				continue
			var d := Vector2(c - center).length_squared()
			if d < best_dist:
				best_dist = d
				best = c - center
	if best == Vector2i.ZERO:
		return
	# Player forward is -Z; yaw so it points along the doorway offset
	# (Vector2i.y holds the cell's world-z).
	player.rotation.y = atan2(-float(best.x), -float(best.y))


# ------------------------------------------------------------------
# Boss floors (docs/structure.md)

func _setup_boss_room() -> void:
	var arena := floor_rooms[arena_room_idx]
	arena_mists = _spawn_mists(arena, false)
	boss_index = mini(RunState.bosses_defeated, 2)
	# PHASE 1 (all boss floors for now; will gate to the amalgam later): the
	# chamber this arena can drop into.
	_build_boss_chamber(arena)
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
	boss_plate = plate


func _build_boss_chamber(arena: Rect2i) -> void:
	# PHASE 1: a chamber the boss arena drops into, built BENEATH the arena
	# BOSS_DROP_LAYERS cell-layers down. The arena floor is its lid (it caves
	# in on the drop). Mirrors a normal room's stack, just lowered: floor +
	# collision wall + a decorative band at the base, then collisionless fill
	# encloses the shaft up to the arena so the whole fall reads solid.
	var floor_y := -BOSS_DROP_LAYERS
	for x in range(arena.position.x - 1, arena.end.x + 1):
		for z in range(arena.position.y - 1, arena.end.y + 1):
			var interior := x >= arena.position.x and x < arena.end.x \
					and z >= arena.position.y and z < arena.end.y
			if interior:
				grid_map.set_cell_item(Vector3i(x, floor_y, z), floor_id)
			else:
				grid_map.set_cell_item(Vector3i(x, floor_y, z), wall_id)
				upper_map.set_cell_item(Vector3i(x, floor_y, z), wall_upper_id)
				# Fill the shaft up toward the arena — but STOP one layer short
				# under a solid arena wall: its 6.2m mesh already hangs down to
				# y=-4.2, so a fill tile there double-stacks and z-fights (the
				# seam that flickers as you move). Under a doorway (floor, no
				# wall) the top layer IS needed, or the shaft yawns open there.
				var above := grid_map.get_cell_item(Vector3i(x, 0, z))
				var top_layer := -2
				if above != wall_id and above != wall_wood_id:
					top_layer = -1
				for layer in range(floor_y + 1, top_layer + 1):
					grid_map.set_cell_item(Vector3i(x, layer, z), wall_fill_id)


func _drop_boss_floor() -> void:
	# The arena floor caves in: every arena floor cell (and its ceiling lid)
	# vanishes, so the fight plunges into the chamber below. controls off
	# BOTH locks input and skips the "Dark Below" death, so the fall is
	# survived; the chamber floor catches the player, then control returns.
	if boss_floor_dropped:
		return
	boss_floor_dropped = true
	# Drop the death plane below the chamber floor: standing in the chamber
	# (y ~ -11.5) is now safe, but a fall THROUGH it still ends the run.
	player.fall_death_y = 0.5 - float(BOSS_DROP_LAYERS) * 4.0 - 2.5
	# The consent plate AND the sealed hatch ride down with the floor — the
	# dropped flow spawns a fresh hatch in the chamber on clear, so the
	# arena's is redundant; either way, no prop hangs in the air.
	if is_instance_valid(boss_plate):
		boss_plate.queue_free()
		boss_plate = null
	if is_instance_valid(boss_hatch):
		boss_hatch.queue_free()
		boss_hatch = null
	var arena := floor_rooms[arena_room_idx]
	# Interior: the WHOLE floor plane caves — stone, planks, and cells that
	# already collapsed to open holes (those keep a hole slab + rim in the
	# HoleMap that would otherwise float). Border ring: only doorway floor
	# stubs, never the walls that hold up the chamber shaft.
	for x in range(arena.position.x - 1, arena.end.x + 1):
		for z in range(arena.position.y - 1, arena.end.y + 1):
			var interior := x >= arena.position.x and x < arena.end.x \
					and z >= arena.position.y and z < arena.end.y
			var id := grid_map.get_cell_item(Vector3i(x, 0, z))
			var is_floor := id == floor_id or id == floor_wood_id \
					or id == floor_wood_pale_id
			if not interior and not is_floor:
				continue
			if is_floor:
				_spawn_falling_floor_chunk(Vector3i(x, 0, z), id)
			grid_map.set_cell_item(Vector3i(x, 0, z), GridMap.INVALID_CELL_ITEM)
			grid_map.set_cell_item(Vector3i(x, 1, z), GridMap.INVALID_CELL_ITEM)
			hole_map.set_cell_item(Vector3i(x, 0, z), GridMap.INVALID_CELL_ITEM)
	_rebuild_hole_rims()  # the arena's rims go now that its hole cells cleared
	_clear_arena_props(arena)  # splats, creep, any flat aftermath over the pit
	# The cave-in beat: the break crack, a deep boom under it (the same stone
	# pitched right down), a curtain of dust down the shaft, a hard camera kick.
	Sfx.play_at(SOUND_FLOOR_BREAK, player.global_position, -2.0)
	Sfx.play_at(SOUND_FLOOR_BREAK, player.global_position, 1.0, 0.42)
	_spawn_shaft_dust(arena)
	player.shake(0.2, 0.8)
	player.controls_enabled = false
	_watch_boss_landing()


func _spawn_shaft_dust(arena: Rect2i) -> void:
	# A curtain of grit pours down the open shaft as the floor lets go —
	# emitted across the whole arena footprint at the old floor line, falling
	# into the dark. CPUParticles for the web renderer; frees itself after.
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 90
	p.lifetime = 2.6
	p.explosiveness = 0.25  # a heavy first gout, then a trailing shower
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(
			arena.size.x * CELL_SIZE * 0.5, 0.3, arena.size.y * CELL_SIZE * 0.5)
	p.direction = Vector3(0.0, -1.0, 0.0)
	p.spread = 12.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0.0, -9.0, 0.0)
	p.damping_min = 0.2
	p.damping_max = 0.8
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.6
	var grad := Gradient.new()
	grad.set_color(0, Color(0.55, 0.5, 0.44, 0.9))
	grad.set_color(1, Color(0.4, 0.36, 0.32, 0.0))
	p.color_ramp = grad
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	p.mesh = quad
	add_child(p)
	p.global_position = _cell_to_world(arena.get_center(), 0.5)
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.5).timeout.connect(p.queue_free)


func _clear_arena_props(arena: Rect2i) -> void:
	# Anything resting on the vanished floor goes with it, or it hangs in the
	# air over the shaft: flat splats and creep stains laid on the stone. The
	# fingerprint is a flat ground Sprite3D (or a creep patch) low in the
	# arena's world-XZ box; live bodies and pickups are left alone. (The
	# sealed hatch and consent plate are freed by name in the caller.)
	var min_x := arena.position.x * CELL_SIZE - 0.5
	var max_x := arena.end.x * CELL_SIZE + 0.5
	var min_z := arena.position.y * CELL_SIZE - 0.5
	var max_z := arena.end.y * CELL_SIZE + 0.5
	var doomed: Array[Node] = []
	for child in get_children():
		if not child is Node3D or child == player:
			continue
		if child.is_in_group("enemies"):
			continue
		if not (child is Sprite3D or child.is_in_group("creep")):
			continue
		var p: Vector3 = (child as Node3D).global_position
		if p.y < 1.6 and p.x >= min_x and p.x <= max_x \
				and p.z >= min_z and p.z <= max_z:
			doomed.append(child)
	for d in doomed:
		d.queue_free()


func _watch_boss_landing() -> void:
	# Wait out the plunge, then hand control back once the chamber floor has
	# caught the player (capped so a bug can't lock control away forever).
	await get_tree().create_timer(0.25).timeout
	# ~3m into the chamber: floor top (0.5) minus the drop (4m PER Y-layer,
	# not CELL_SIZE, which is the 2m XZ pitch).
	var landed_below := 0.5 - float(BOSS_DROP_LAYERS) * 4.0 + 3.0
	var frames := 0
	while frames < 300 \
			and (player.global_position.y > landed_below or not player.is_on_floor()):
		await get_tree().physics_frame
		frames += 1
	player.controls_enabled = true


func _spawn_falling_floor_chunk(cell: Vector3i, tile_id: int) -> void:
	# The caved-in slab as a real body: the actual floor mesh (stone or the
	# wooden plank it was) cut loose so it tumbles down the shaft and fades,
	# instead of a flat splinter puff. It collides with the world (layer 1)
	# but sits on no layer itself (0) — so it never shoves the falling player
	# nor grinds against its siblings; it just drops and dissolves.
	var mesh := grid_map.mesh_library.get_item_mesh(tile_id)
	if mesh == null:
		return
	var body := RigidBody3D.new()
	body.collision_layer = 0
	body.collision_mask = 1
	body.gravity_scale = 1.2
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 0.5, 2.0)
	col.shape = box
	body.add_child(col)
	add_child(body)
	body.global_position = _cell_to_world(Vector2i(cell.x, cell.z), 0.5)
	# a shove of chaos so the slabs tumble rather than sink flat
	body.linear_velocity = Vector3(
			randf_range(-1.5, 1.5), randf_range(-1.0, 0.5), randf_range(-1.5, 1.5))
	body.angular_velocity = Vector3(
			randf_range(-5.0, 5.0), randf_range(-3.0, 3.0), randf_range(-5.0, 5.0))
	# tumble a while, fade to nothing, gone
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_property(mi, "transparency", 1.0, 0.6)
	t.tween_callback(body.queue_free)


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


func _drop_into_assembly() -> void:
	# The 3-3 climax: the arena floor caves in. The player falls by real
	# physics; every corpse they made — captured first, before the tiles
	# vanish — rides down on tweens timed to land with them, then drags to
	# the chamber centre and rises as the amalgam.
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
	# Cave the floor: player plunges, tiles tumble, the way back seals.
	_drop_boss_floor()
	# Assemble at the arena centre XZ, just above the chamber floor (the
	# chamber is solid — no holes, no hatch yet — so the centre is safe).
	var center_cell := arena.get_center()
	var chamber_top := 0.5 - float(BOSS_DROP_LAYERS) * 4.0
	var center := _cell_to_world(center_cell, chamber_top + 0.6)
	var i := 0
	for c in corpses:
		c.set_physics_process(false)
		var offset := Vector3(
			randf_range(-0.5, 0.5), randf_range(0.0, 0.6), randf_range(-0.5, 0.5))
		var tw := create_tween()
		tw.tween_interval(0.4 + i * 0.12)
		tw.tween_property(c, "global_position", center + offset, 2.4) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		i += 1
	var timer := Timer.new()
	timer.wait_time = 0.4 + corpses.size() * 0.12 + 2.4 + 0.6
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
	# When it assembles in the chamber it stands far below the normal fall
	# plane — drop its self-despawn net below the chamber floor, or it
	# deletes itself the frame after the roar.
	if boss_floor_dropped:
		boss.fall_y = 0.5 - float(BOSS_DROP_LAYERS) * 4.0 - 5.0
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
	# The reward is earned by the fight — and the deep decides what
	# it is: one random draw from the same pool the pedestals use.
	# Never empty (golden hearts are always in the draw).
	var pool := _relic_pool()
	var reward: Node3D = pool[randi_range(0, pool.size() - 1)].instantiate()
	if boss_floor_dropped:
		# The arena is gone overhead — the way down and the reward wait
		# here in the chamber, at the amalgam's fallen centre.
		var arena := floor_rooms[arena_room_idx]
		var center_cell := arena.get_center()
		var chamber_top := 0.5 - float(BOSS_DROP_LAYERS) * 4.0
		var hatch := HATCH_SCENE.instantiate()
		hatch.position = _cell_to_world(center_cell, chamber_top)
		add_child(hatch)
		if reward != null:
			reward.position = _cell_to_world(
					center_cell + Vector2i(1, 0), chamber_top)
			add_child(reward)
	else:
		# The sealed hatch at the arena's heart opens — but never under
		# anyone's feet.
		if is_instance_valid(boss_hatch):
			boss_hatch.open()
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
	if not RunState.barrelstone:
		pool.append(BARRELSTONE_SCENE)
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
