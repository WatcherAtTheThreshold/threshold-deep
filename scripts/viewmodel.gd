extends TextureRect

const TORCH_IDLE := preload("res://assets/sprites/hand-torch.png")
const TORCH_SWING := preload("res://assets/sprites/hand-torch_swing.png")
const SWORD_IDLE := preload("res://assets/sprites/hand-sword.png")
const SWORD_SWING := preload("res://assets/sprites/hand-sword-swing.png")
const SWAY_AMOUNT := 6.0

@onready var player: Player = get_tree().get_first_node_in_group("player")

var idle_texture: Texture2D = TORCH_IDLE
var swing_texture: Texture2D = TORCH_SWING
var swing_move := Vector2(-36.0, -4.0)
var swing_rot := -0.3
var bob_time := 0.0
var base_offset: Vector2
var swing_offset := Vector2.ZERO


func _ready() -> void:
	# Remember how far from the window's bottom-right corner we start;
	# the corner itself is recomputed live so resizing keeps us in it.
	base_offset = Vector2(offset_left, offset_top)
	pivot_offset = size
	player.attacked.connect(_on_attacked)


func set_sword(equipped: bool) -> void:
	# The right hand holds the best weapon; the torch moves left.
	idle_texture = SWORD_IDLE if equipped else TORCH_IDLE
	swing_texture = SWORD_SWING if equipped else TORCH_SWING
	texture = idle_texture
	# The sword's swing frame carries the arc itself, so its code
	# motion is a flat sideways push — big lift/rotation shoved the
	# canvas edge into view.
	if equipped:
		swing_move = Vector2(-24.0, 0.0)
		swing_rot = -0.12
	else:
		swing_move = Vector2(-36.0, -4.0)
		swing_rot = -0.3


func _process(delta: float) -> void:
	# Advance the bob only while walking on the ground, in rhythm with speed.
	var ground_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if ground_speed > 0.1 and player.is_on_floor():
		bob_time += delta * ground_speed * 2.0
	# pivot_offset is the center for scaling too, so compensate for the
	# up-left shift the 3x scale gets from the corner pivot.
	var corner_base := get_viewport_rect().size + base_offset \
			+ pivot_offset * (scale - Vector2.ONE)
	position = corner_base + swing_offset + Vector2(
		sin(bob_time) * SWAY_AMOUNT,
		absf(cos(bob_time)) * SWAY_AMOUNT * 0.5
	)


func _on_attacked() -> void:
	# Swap to the drawn swing frame and arc toward screen center.
	texture = swing_texture
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "swing_offset", swing_move, 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", swing_rot, 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "swing_offset", Vector2.ZERO, 0.22)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.22)
	tween.chain().tween_callback(func() -> void: texture = idle_texture)
