extends TextureRect

# Viewmodel art follows one contract: assets/sprites/<weapon>/<weapon>_idle1..N
# and <weapon>_attack1..N, 256x128. The folder is the only thing that differs —
# same rule as the creature turnarounds and the tile appearance folders, so a
# new weapon is a folder of PNGs and nothing to name. Frame COUNTS may differ.
const TORCH_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/torch/torch_idle1.png"),
	preload("res://assets/sprites/torch/torch_idle2.png"),
	preload("res://assets/sprites/torch/torch_idle3.png"),
]
const TORCH_SWING_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/torch/torch_attack1.png"),
	preload("res://assets/sprites/torch/torch_attack2.png"),
	preload("res://assets/sprites/torch/torch_attack3.png"),
]
# Windup / extended strike (embers fly here) / follow-through.
const TORCH_SWING_TIMES: Array[float] = [0.06, 0.11, 0.10]
const SWORD_IDLE_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/sword/sword_idle1.png"),
	preload("res://assets/sprites/sword/sword_idle2.png"),
]
const SWORD_SWING_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/sword/sword_attack1.png"),
	preload("res://assets/sprites/sword/sword_attack2.png"),
	preload("res://assets/sprites/sword/sword_attack3.png"),
]
# Windup / strike / follow-through.
const SWORD_SWING_TIMES: Array[float] = [0.06, 0.11, 0.10]
const STAFF_IDLE_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/magic_staff/magic_staff_idle1.png"),
	preload("res://assets/sprites/magic_staff/magic_staff_idle2.png"),
]
const STAFF_ATTACK_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/magic_staff/magic_staff_attack1.png"),
	preload("res://assets/sprites/magic_staff/magic_staff_attack2.png"),
	preload("res://assets/sprites/magic_staff/magic_staff_attack3.png"),
]
# Gather / cast / recover. Fits inside ATTACK_COOLDOWN's 0.5 s, which ranged
# weapons keep flat (no Hasty scaling), so the cast never clips itself.
const STAFF_SWING_TIMES: Array[float] = [0.06, 0.10, 0.09]
const BOOMERANG_IDLE_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/boomerang/boomerang_idle1.png"),
	preload("res://assets/sprites/boomerang/boomerang_idle2.png"),
	preload("res://assets/sprites/boomerang/boomerang_idle3.png"),
]
const BOOMERANG_ATTACK_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/boomerang/boomerang_attack1.png"),
	preload("res://assets/sprites/boomerang/boomerang_attack2.png"),
	preload("res://assets/sprites/boomerang/boomerang_attack3.png"),
]
# Deliberately the fastest arc in the game: the projectile leaves the player's
# hand the instant `attacked` fires, so every frame spent still drawing a
# boomerang in-hand is a frame it exists twice. 0.16 s total, then the throw
# tween drops the hand out and `visible` hides it until the catch.
const BOOMERANG_SWING_TIMES: Array[float] = [0.05, 0.06, 0.05]
const HALBERD_IDLE_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/halberd/halberd_idle1.png"),
	preload("res://assets/sprites/halberd/halberd_idle2.png"),
]
const HALBERD_ATTACK_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/halberd/halberd_attack1.png"),
	preload("res://assets/sprites/halberd/halberd_attack2.png"),
	preload("res://assets/sprites/halberd/halberd_attack3.png"),
]
# Windup / extended strike / follow-through — same three-beat shape
# as the torch, tuned a touch slower for a heavier weapon.
const HALBERD_SWING_TIMES: Array[float] = [0.08, 0.13, 0.11]
const SWAY_AMOUNT := 6.0
const FLICKER_TIME := 0.16

@onready var player: Player = get_tree().get_first_node_in_group("player")

var idle_frames: Array[Texture2D] = TORCH_FRAMES
var weapon := "torch"
var swinging := false
var was_out := false
var flicker_clock := 0.0
var bob_time := 0.0
var base_offset: Vector2
var anchor_off: Vector2
var swing_offset := Vector2.ZERO
var swing_tween: Tween = null

@onready var embers: CPUParticles2D = $Embers


func _ready() -> void:
	# Remember how far from the window's bottom-right corner we start;
	# the corner itself is recomputed live so resizing keeps us in it.
	# anchor_off pins the ART's bottom-right point. It derives from
	# the designed 128px slot, NEVER from runtime size — a wide
	# texture already loaded at _ready would inflate the control and
	# shove the whole slot off-screen.
	base_offset = Vector2(offset_left, offset_top)
	anchor_off = base_offset + Vector2(128, 128) * scale
	player.attacked.connect(_on_attacked)


func set_weapon(new_weapon: String) -> void:
	# The right hand holds the best weapon; the torch moves left.
	weapon = new_weapon
	match weapon:
		"boomerang":
			idle_frames = BOOMERANG_IDLE_FRAMES
		"staff":
			idle_frames = STAFF_IDLE_FRAMES
		"sword":
			idle_frames = SWORD_IDLE_FRAMES
		"halberd":
			idle_frames = HALBERD_IDLE_FRAMES
		_:
			idle_frames = TORCH_FRAMES
	texture = idle_frames[0]


func _process(delta: float) -> void:
	if player.health <= 0:
		# Dead hands hold nothing: the death report stands alone.
		visible = false
		return
	# Advance the bob only while walking on the ground, in rhythm with speed.
	var ground_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if ground_speed > 0.1 and player.is_on_floor():
		bob_time += delta * ground_speed * 2.0
	# The boomerang hand is empty from throw to catch — the weapon is
	# out there. The catch snaps it back with a little settle.
	if weapon == "boomerang":
		var out: bool = player.boomerang_out
		if not out and was_out:
			swing_offset = Vector2(0.0, 46.0)
			var catch_tween := create_tween()
			catch_tween.tween_property(self, "swing_offset", Vector2.ZERO, 0.18) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		visible = not out or swinging
		was_out = out
	# The torch flame always flickers; blades with idle pairs are
	# walk frames — they sway only while the feet move.
	if not swinging and idle_frames.size() > 1:
		var cadence := FLICKER_TIME if weapon == "torch" else 0.3
		if weapon == "torch" or (ground_speed > 0.1 and player.is_on_floor()):
			flicker_clock += delta
		texture = idle_frames[int(flicker_clock / cadence) % idle_frames.size()]
	# Pin the art's bottom-right to the corner whatever the canvas
	# size. Rect size is forced to the texture's own size — the layout
	# system lags texture swaps and would draw wide frames squashed
	# into the old rect — then pivot and position follow from it.
	var tsize := texture.get_size() if texture != null else size
	size = tsize
	pivot_offset = tsize
	position = get_viewport_rect().size + anchor_off - tsize \
			+ swing_offset + Vector2(
		sin(bob_time) * SWAY_AMOUNT,
		absf(cos(bob_time)) * SWAY_AMOUNT * 0.5
	)


func _on_attacked() -> void:
	# Every weapon now swings on a drawn three-beat arc — Jessop's frames carry
	# the strike, code only times them. The old code-driven "jab" that the staff
	# and boomerang used is gone: once art exists, moving the sprite around to
	# fake a motion just fights the drawing.
	swinging = true
	var arc_frames: Array[Texture2D]
	var arc_times: Array[float]
	match weapon:
		"sword":
			arc_frames = SWORD_SWING_FRAMES
			arc_times = SWORD_SWING_TIMES
		"halberd":
			arc_frames = HALBERD_ATTACK_FRAMES
			arc_times = HALBERD_SWING_TIMES
		"staff":
			arc_frames = STAFF_ATTACK_FRAMES
			arc_times = STAFF_SWING_TIMES
		"boomerang":
			arc_frames = BOOMERANG_ATTACK_FRAMES
			arc_times = BOOMERANG_SWING_TIMES
		_:
			arc_frames = TORCH_SWING_FRAMES
			arc_times = TORCH_SWING_TIMES
	if weapon == "boomerang":
		# The throw keeps its motion ON TOP of the arc: the hand drops out of
		# frame and `visible` holds it gone until the catch, because the weapon
		# is genuinely out there. Runs parallel so the drawn release still plays.
		var throw_tween := create_tween().set_parallel(true)
		throw_tween.tween_property(self, "swing_offset", Vector2(10.0, 110.0), 0.09) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		throw_tween.tween_property(self, "rotation", 0.05, 0.09)
		throw_tween.chain().tween_callback(func() -> void:
			swing_offset = Vector2.ZERO
			rotation = 0.0)
	if swing_tween != null and swing_tween.is_valid():
		swing_tween.kill()
	texture = arc_frames[0]
	swing_tween = create_tween()
	swing_tween.tween_interval(arc_times[0])
	swing_tween.tween_callback(func() -> void:
		texture = arc_frames[1]
		# Embers burst on the extended frame — the hit. Flames only.
		if weapon == "torch":
			embers.restart())
	swing_tween.tween_interval(arc_times[1])
	swing_tween.tween_callback(func() -> void:
		texture = arc_frames[2])
	swing_tween.tween_interval(arc_times[2])
	swing_tween.tween_callback(func() -> void:
		texture = idle_frames[0]
		swinging = false)
