extends TextureRect

const TORCH_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/torch/hand-torch1.png"),
	preload("res://assets/sprites/torch/hand-torch2.png"),
	preload("res://assets/sprites/torch/hand-torch3.png"),
]
const TORCH_SWING := preload("res://assets/sprites/torch/hand-torch_swing.png")
const TORCH_SWING_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/torch/hand-torch_swing1.png"),
	preload("res://assets/sprites/torch/hand-torch_swing2.png"),
	preload("res://assets/sprites/torch/hand-torch_swing3.png"),
]
# Windup / extended strike (embers fly here) / follow-through.
const TORCH_SWING_TIMES: Array[float] = [0.06, 0.11, 0.10]
const SWORD_IDLE := preload("res://assets/sprites/hand-sword.png")
const SWORD_SWING := preload("res://assets/sprites/hand-sword-swing.png")
const STAFF_IDLE := preload("res://assets/sprites/magic_staff.png")
const STAFF_SWING := preload("res://assets/sprites/magic_staff_swing.png")
const BOOMERANG_IDLE := preload("res://assets/sprites/hand-boomerang.png")
const BOOMERANG_SWING := preload("res://assets/sprites/hand-boomerang-swing.png")
const SWAY_AMOUNT := 6.0
const FLICKER_TIME := 0.16

@onready var player: Player = get_tree().get_first_node_in_group("player")

var idle_frames: Array[Texture2D] = TORCH_FRAMES
var swing_texture: Texture2D = TORCH_SWING
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
			idle_frames = [BOOMERANG_IDLE]
			swing_texture = BOOMERANG_SWING
		"staff":
			idle_frames = [STAFF_IDLE]
			swing_texture = STAFF_SWING
		"sword":
			idle_frames = [SWORD_IDLE]
			swing_texture = SWORD_SWING
		_:
			idle_frames = TORCH_FRAMES
			swing_texture = TORCH_SWING
	texture = idle_frames[0]


func _process(delta: float) -> void:
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
	# The torch flame flickers while at rest in the hand.
	if not swinging and idle_frames.size() > 1:
		flicker_clock += delta
		texture = idle_frames[int(flicker_clock / FLICKER_TIME) % idle_frames.size()]
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
	swinging = true
	if weapon == "boomerang":
		# The throw: yank down and release. The hand exits the bottom
		# of the frame and stays gone — the boomerang is out there
		# now. The catch brings it back.
		var throw_tween := create_tween().set_parallel(true)
		throw_tween.tween_property(self, "swing_offset", Vector2(10.0, 110.0), 0.09) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		throw_tween.tween_property(self, "rotation", 0.05, 0.09)
		throw_tween.chain().tween_callback(func() -> void:
			swinging = false
			swing_offset = Vector2.ZERO
			rotation = 0.0
			texture = idle_frames[0])
		return
	if weapon == "torch":
		# The drawn arc: Jessop's frames carry the strike, code only
		# times them. Embers burst on the extended frame — the hit.
		if swing_tween != null and swing_tween.is_valid():
			swing_tween.kill()
		texture = TORCH_SWING_FRAMES[0]
		swing_tween = create_tween()
		swing_tween.tween_interval(TORCH_SWING_TIMES[0])
		swing_tween.tween_callback(func() -> void:
			texture = TORCH_SWING_FRAMES[1]
			embers.restart())
		swing_tween.tween_interval(TORCH_SWING_TIMES[1])
		swing_tween.tween_callback(func() -> void:
			texture = TORCH_SWING_FRAMES[2])
		swing_tween.tween_interval(TORCH_SWING_TIMES[2])
		swing_tween.tween_callback(func() -> void:
			texture = idle_frames[0]
			swinging = false)
		return
	# The jab, same for sword: yank the weapon down toward
	# off-screen, then piston it back up past rest with only a slight
	# arc, then settle. Stabby, not sweepy.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "swing_offset", Vector2(10.0, 110.0), 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 0.05, 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func() -> void: texture = swing_texture)
	tween.chain().tween_property(self, "swing_offset", Vector2(-14.0, -10.0), 0.07) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", -0.1, 0.07) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "swing_offset", Vector2.ZERO, 0.18)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.18)
	tween.chain().tween_callback(func() -> void:
		texture = idle_frames[0]
		swinging = false)
