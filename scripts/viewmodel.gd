extends TextureRect

const TORCH_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/hand-torch.png"),
	preload("res://assets/sprites/hand-torch2.png"),
	preload("res://assets/sprites/hand-torch3.png"),
]
const TORCH_SWING := preload("res://assets/sprites/hand-torch_swing.png")
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
var swinging := false
var flicker_clock := 0.0
var bob_time := 0.0
var base_offset: Vector2
var swing_offset := Vector2.ZERO


func _ready() -> void:
	# Remember how far from the window's bottom-right corner we start;
	# the corner itself is recomputed live so resizing keeps us in it.
	base_offset = Vector2(offset_left, offset_top)
	pivot_offset = size
	player.attacked.connect(_on_attacked)


func set_weapon(weapon: String) -> void:
	# The right hand holds the best weapon; the torch moves left.
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
	# The torch flame flickers while at rest in the hand.
	if not swinging and idle_frames.size() > 1:
		flicker_clock += delta
		texture = idle_frames[int(flicker_clock / FLICKER_TIME) % idle_frames.size()]
	# pivot_offset is the center for scaling too, so compensate for the
	# up-left shift the 3x scale gets from the corner pivot.
	var corner_base := get_viewport_rect().size + base_offset \
			+ pivot_offset * (scale - Vector2.ONE)
	position = corner_base + swing_offset + Vector2(
		sin(bob_time) * SWAY_AMOUNT,
		absf(cos(bob_time)) * SWAY_AMOUNT * 0.5
	)


func _on_attacked() -> void:
	# The jab, same for every weapon: yank the weapon down toward
	# off-screen, then piston it back up past rest with only a slight
	# arc, then settle. Stabby, not sweepy.
	swinging = true
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
