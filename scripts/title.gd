extends Node3D

## The start screen — the game's front door (the startup scene). A camera
## walks a hand-built corridor by torchlight, rounds a corner into a dark
## chamber, reveals the sword planted in stone, and settles as the START
## / QUIT plates rise. A run is born here (START -> RunState.reset() ->
## dungeon); death returns here. On a return, MetaState.intro_seen skips
## the flythrough straight to the settled menu.
##
## The `Corpse` node earns its place twice. As story it explains the sword —
## someone came down here before you, it went badly for one of them, and the
## other left their weapon in the stone. As engineering it is a SHADER WARM:
## every creature in the game shares one material config (billboard 2, shaded,
## alpha_cut 1, nearest), and shader variants compile on that config rather
## than the texture, so this one sprite compiles the whole bestiary's shader
## before the dungeon ever loads. That is what the web build's first-entry
## hitch was. It sits straight down the approach corridor so it renders on
## frame one of the walk — while the screen is still fading up from black,
## which is exactly where you want a compile stall to land.
## A dead one, deliberately: start-screen.md rejected a LIVE wizard here
## because a creature that notices you and does nothing is "a promise the
## screen doesn't keep." A corpse promises nothing.
##
## `ShaderWarm` is the engineering half, split out so the corpse can be judged
## purely as a picture. It sits at world (5.5, 1.6, 9) — INSIDE the solid stone
## of cell (2, 4), one cell east of the approach corridor. Occlusion culling is
## off, so objects buried in a wall are still submitted as draw calls and still
## compile their pipelines; only the depth test throws the pixels away. In the
## camera frustum from frame one, invisible forever.
##
## It holds one node per MATERIAL CONFIG the dungeon uses and the title
## otherwise wouldn't touch — variants compile per config, not per texture, so
## one node covers every user of that config:
##   Mist      the mist.gdshader ShaderMaterial (gates, doors)
##   Orb       unshaded, billboard 1 — every projectile
##   Dot       unshaded, billboard 2 — Rot/Ember/Cinder overlays
##   Creature  shaded, billboard 2 — the entire bestiary
## Tiles are already warm: the title runs the same dungeon_tiles.tres.
## ADD A NODE HERE whenever a new material config ships, or the first thing
## that uses it will stutter on a web build.

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
@onready var prompt: TextureButton = $UI/Prompt
@onready var menu: VBoxContainer = $UI/Menu
@onready var start_button: TextureButton = $UI/Menu/Start
@onready var options_button: TextureButton = $UI/Menu/Options
@onready var quit_button: TextureButton = $UI/Menu/Quit
@onready var camera: Camera3D = $CameraPath/Follow/Camera3D

var flicker_time := 0.0
const OPTIONS_SCENE := preload("res://scenes/options_panel.tscn")

## The three scenes the DUNGEON loads at RUNTIME instead of preloading — the
## creatures that spawn copies of themselves. Their scripts use `load()` rather
## than `preload()` because a script preloading its own scene risks the parse
## cycle this project has hit before ("Parse Error: Busy"), so the call can't
## simply be changed there. On a single-threaded web export (`thread_support=
## false`) that load BLOCKS the frame — confirmed 2026-08-08 as the jag you
## feel the first time a slime splits.
## Touching them here puts them in ResourceLoader's cache, so the in-fight
## `load()` becomes a cache hit. Process-lifetime, so it survives to the run.
## ONE PER FRAME, and while the screen is still black — never all at once, or
## we'd have moved the stall rather than removed it.
const WARM_SCENES: Array[String] = [
	"res://scenes/slime.tscn",
	"res://scenes/mush.tscn",
	"res://scenes/frogman.tscn",
]

var intro_started := false
var settled := false
var warm_index := 0
var options_panel: CanvasLayer = null
var walk_tween: Tween
var fade_tween: Tween


func _ready() -> void:
	# Free the cursor for the menu. Crucial on a death RETURN: the dungeon
	# left the mouse captured, and without this the plates are unclickable
	# and the settled title swallows Esc — a soft-lock that needs a force
	# quit. A cold boot is already visible, so this is just belt-and-braces
	# there.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_corridor()
	_lay_camera_path()
	crackle.finished.connect(crackle.play)  # hand-loop the torch ambient
	start_button.pressed.connect(_on_start)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit)
	# The descend plate is a real button so it can wear its hover glow, but
	# _unhandled_input still accepts a click ANYWHERE — the browser gesture
	# gate should never be something you can miss.
	prompt.pressed.connect(_begin_intro)
	# Every plate in this scene gets the click, including any added later.
	Sfx.wire_buttons(self)
	if OS.has_feature("web"):
		quit_button.hide()  # nothing to quit to in a browser tab
	if MetaState.intro_seen:
		# Returning from a run: skip the flythrough, land on the menu.
		_reveal_settled()
	# Otherwise the scene sits black behind "click to descend" until the
	# player spends the one gesture the browser needs anyway; that click
	# starts the walk, the music, and the ambient together (_begin_intro).


func _process(delta: float) -> void:
	# The torch never rests: a subtle energy flicker keeps the whole
	# frame alive. (The dungeon flickers the hand sprite; here there is
	# no hand, so the light itself breathes.)
	if warm_index < WARM_SCENES.size():
		# Runs from the very first frame, behind the black gate — the player
		# hasn't even clicked yet, so a blocked frame here costs nothing.
		load(WARM_SCENES[warm_index])
		warm_index += 1
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
	elif settled:
		# A whisper of idle drift keeps the settled shot from freezing.
		camera.rotation.y = deg_to_rad(0.6) * sin(flicker_time * 0.35)
		camera.rotation.x = deg_to_rad(0.4) * sin(flicker_time * 0.27)


func _unhandled_input(event: InputEvent) -> void:
	# First gesture starts everything; a second, mid-flythrough, skips to
	# the settled menu. Once settled, the buttons take over.
	if settled:
		return
	var pressed: bool = (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed)
	if not pressed:
		return
	if not intro_started:
		_begin_intro()
	else:
		_skip_to_settled()


func _begin_intro() -> void:
	if intro_started:
		return
	intro_started = true
	MetaState.intro_seen = true  # future title visits skip to the menu
	# It fades over the next 0.3s but a Control at alpha 0 still EATS clicks —
	# leave it hittable and a tap at screen centre during the walk would
	# re-enter this guarded function instead of skipping to the menu.
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	music.play()      # the composed title track, one-shot
	crackle.play()    # torch ambient, hand-looped; carries the quiet after
	# Reveal the walk: the black gate fades, the prompt fades with it.
	fade_tween = create_tween()
	fade_tween.tween_property(black, "color:a", 0.0, 0.5)
	fade_tween.parallel().tween_property(prompt, "modulate:a", 0.0, 0.3)
	# The flythrough, timed to the track — the swell lands as the walls
	# open. When it settles, the menu plates fade up on that same beat.
	walk_tween = create_tween()
	walk_tween.tween_property(follow, "progress_ratio", 1.0, WALK_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	walk_tween.finished.connect(_reach_settle)


func _skip_to_settled() -> void:
	# Impatient tap during the walk — snap to the end of the flythrough.
	if walk_tween and walk_tween.is_valid():
		walk_tween.kill()
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	black.color.a = 0.0
	prompt.modulate.a = 0.0
	_reach_settle()


func _reveal_settled() -> void:
	# Returning from a run: no click, no flythrough — straight to the
	# settled camera and menu, with the title's music and ambient.
	intro_started = true
	black.color.a = 0.0
	prompt.hide()
	music.play()
	crackle.play()
	_reach_settle()


func _reach_settle() -> void:
	# The camera rests and the plates rise from the dark as carved, lit
	# stone. Reached by the walk finishing, a skip, or a return from
	# death — guarded, and snaps the camera to the settle either way.
	if settled:
		return
	settled = true
	follow.progress_ratio = 1.0
	menu.visible = true
	menu.modulate.a = 0.0
	create_tween().tween_property(menu, "modulate:a", 1.0, 0.8)


func _on_start() -> void:
	# A run is born HERE, at the title — the dungeon only consumes it.
	RunState.reset()
	get_tree().change_scene_to_file("res://scenes/dungeon.tscn")


func _on_options() -> void:
	if options_panel != null:
		return
	options_panel = OPTIONS_SCENE.instantiate()
	options_panel.closed.connect(func() -> void: options_panel = null)
	add_child(options_panel)


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
