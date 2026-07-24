extends Node3D

## The start-screen flythrough (Phase 1: "the shot"). A camera walks a
## hand-built corridor by torchlight, rounds a corner, and settles
## facing the end wall — the same stone, scale, and light as the game.
## No menu, no music, no sword yet; those come in later phases.
##
## Preview with the scene open and F6 (the global startup scene stays
## dungeon.tscn until the hub-wiring phase, so F5 still runs the game).

const EYE_HEIGHT := 2.05  # camera world y — matches player (1.5 origin + 0.55)
const WALK_TIME := 16.0    # tune to the title track in the music phase
const TORCH_BASE_ENERGY := 1.8
const CORNER_EASE := 2.0   # metres the turn starts before / ends after the corner
const SWORD_GLOW_BASE := 0.9    # the planted sword's blue glow, breathing
const SWORD_GLOW_PULSE := 0.25
const SWORD_GLOW_SPEED := 1.2

# An L of two NARROW corridors that only opens into the dark chamber
# partway down the east leg — so the room (and the sword) stay hidden
# behind stone until you've rounded the corner and walked into it, then
# the walls fall away. Approach corridor runs south→north at x=1; the
# east corridor runs the corner eastward at z=1; the chamber opens past
# its end, wide and deep so the torch has darkness to fade into.
const CORRIDOR_X := 1
const CORRIDOR_Z_MIN := 2
const CORRIDOR_Z_MAX := 6
const EAST_Z := 1
const EAST_X_MIN := 1
const EAST_X_MAX := 3
const CHAMBER_MIN := Vector2i(4, -2)
const CHAMBER_MAX := Vector2i(10, 4)
const BOX_MIN := Vector2i(0, -3)
const BOX_MAX := Vector2i(11, 7)

@onready var grid_map: GridMap = $GridMap
@onready var upper_map: GridMap = $UpperMap
@onready var follow: PathFollow3D = $CameraPath/Follow
@onready var torch_light: OmniLight3D = $CameraPath/Follow/Camera3D/TorchLight
@onready var sword_glow: OmniLight3D = $Sword/Glow
@onready var music: AudioStreamPlayer = $Music
@onready var crackle: AudioStreamPlayer = $Crackle
@onready var black: ColorRect = $UI/Black
@onready var prompt: Label = $UI/Prompt
@onready var menu: VBoxContainer = $UI/Menu
@onready var start_button: TextureButton = $UI/Menu/Start
@onready var quit_button: TextureButton = $UI/Menu/Quit

var flicker_time := 0.0
var intro_started := false


func _ready() -> void:
	_build_corridor()
	_lay_camera_path()
	crackle.finished.connect(crackle.play)  # hand-loop the torch ambient
	start_button.pressed.connect(_on_start)
	quit_button.pressed.connect(_on_quit)
	if OS.has_feature("web"):
		quit_button.hide()  # nothing to quit to in a browser tab
	# The scene sits black behind "click to descend" until the player
	# spends the one gesture the browser needs anyway; that click starts
	# the walk, the music, and the ambient together (see _begin_intro).


func _process(delta: float) -> void:
	# The torch never rests: a subtle energy flicker keeps the whole
	# frame alive. (The dungeon flickers the hand sprite; here there is
	# no hand, so the light itself breathes.)
	flicker_time += delta
	torch_light.light_energy = TORCH_BASE_ENERGY \
			+ 0.18 * sin(flicker_time * 11.0) \
			+ 0.12 * sin(flicker_time * 19.0) \
			+ randf_range(-0.06, 0.06)
	# The planted sword breathes: its blue glow swells and fades rather
	# than the blade bobbing — the art is stuck in stone, so it shouldn't
	# float.
	sword_glow.light_energy = SWORD_GLOW_BASE + SWORD_GLOW_PULSE * sin(flicker_time * SWORD_GLOW_SPEED)
	if not intro_started:
		# Slow breath on the prompt while we wait for the gesture.
		prompt.modulate.a = 0.65 + 0.35 * sin(flicker_time * 2.2)


func _unhandled_input(event: InputEvent) -> void:
	# The one gesture that starts everything — click, key, or touch.
	if intro_started:
		return
	var pressed: bool = (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		_begin_intro()


func _begin_intro() -> void:
	if intro_started:
		return
	intro_started = true
	music.play()      # the composed title track, one-shot
	crackle.play()    # torch ambient, hand-looped; carries the quiet after
	# Reveal the walk: the black gate fades, the prompt fades with it.
	var fade := create_tween()
	fade.tween_property(black, "color:a", 0.0, 0.5)
	fade.parallel().tween_property(prompt, "modulate:a", 0.0, 0.3)
	# The flythrough, timed to the track — the swell lands as the walls
	# open. When it settles, the menu plates fade up on that same beat.
	var walk := create_tween()
	walk.tween_property(follow, "progress_ratio", 1.0, WALK_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	walk.finished.connect(_show_menu)


func _show_menu() -> void:
	# The plates rise from the dark as carved, lit stone — fade in on the
	# settle, self-lit against the chamber's black.
	menu.visible = true
	menu.modulate.a = 0.0
	create_tween().tween_property(menu, "modulate:a", 1.0, 0.8)


func _on_start() -> void:
	# A run is born HERE, at the title — the dungeon only consumes it.
	RunState.reset()
	get_tree().change_scene_to_file("res://scenes/dungeon.tscn")


func _on_quit() -> void:
	get_tree().quit()


func _build_corridor() -> void:
	# A solid stone block with the L carved out — reuses the game's tile
	# library so the stone reads identical to a real floor.
	var floor_id := grid_map.mesh_library.find_item_by_name("floor")
	var wall_id := grid_map.mesh_library.find_item_by_name("wall")
	var ceiling_id := grid_map.mesh_library.find_item_by_name("ceiling")
	var upper_id := grid_map.mesh_library.find_item_by_name("wall_upper1")
	for x in range(BOX_MIN.x, BOX_MAX.x + 1):
		for z in range(BOX_MIN.y, BOX_MAX.y + 1):
			if _is_floor(x, z):
				grid_map.set_cell_item(Vector3i(x, 0, z), floor_id)
				grid_map.set_cell_item(Vector3i(x, 1, z), ceiling_id)
			else:
				# Lower wall in the main map; the 2 m decorative band goes
				# in a SEPARATE UpperMap, also at y=0 — its mesh_transform
				# (+1) lifts it to world 2–4, bridging wall-top (2.0) to
				# ceiling (4.0). It can't share cell y=0 with the wall in
				# one map, which is exactly why the dungeon has an UpperMap.
				grid_map.set_cell_item(Vector3i(x, 0, z), wall_id)
				upper_map.set_cell_item(Vector3i(x, 0, z), upper_id)


func _is_floor(x: int, z: int) -> bool:
	# The two narrow corridor legs, plus the chamber past the east leg.
	# Anything else in the bounding box becomes solid stone.
	if x == CORRIDOR_X and z >= CORRIDOR_Z_MIN and z <= CORRIDOR_Z_MAX:
		return true
	if z == EAST_Z and x >= EAST_X_MIN and x <= EAST_X_MAX:
		return true
	return x >= CHAMBER_MIN.x and x <= CHAMBER_MAX.x \
			and z >= CHAMBER_MIN.y and z <= CHAMBER_MAX.y


func _lay_camera_path() -> void:
	# Straight down the corridor, then a real quarter-arc that BEGINS
	# CORNER_EASE metres before the corner (you see it coming and ease
	# in) and finishes the same distance past it, then straight into the
	# settle. The turn-start and turn-end points carry collinear handles
	# of that same length, which drops both inner controls onto the
	# corner — an even, continuous round with no tangent kink for the
	# camera's yaw to snap through.
	var curve := Curve3D.new()
	var corner := _eye(Vector2i(1, 1))
	var e := CORNER_EASE
	curve.add_point(_eye(Vector2i(1, 6)))                        # south start
	curve.add_point(corner + Vector3(0, 0, e),                  # turn-start
			Vector3(0, 0, e), Vector3(0, 0, -e))
	curve.add_point(corner + Vector3(e, 0, 0),                  # turn-end
			Vector3(-e, 0, 0), Vector3(e, 0, 0))
	curve.add_point(_eye(Vector2i(6, 1)))                       # settle (deeper in the chamber)
	$CameraPath.curve = curve
	follow.progress_ratio = 0.0


func _eye(cell: Vector2i) -> Vector3:
	# Cell (x, z) → world centre at camera eye height.
	return Vector3(cell.x * 2 + 1, EYE_HEIGHT, cell.y * 2 + 1)
