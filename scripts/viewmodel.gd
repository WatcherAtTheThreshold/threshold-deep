extends TextureRect

const IDLE_TEXTURE := preload("res://assets/sprites/hand-torch.png")
const SWING_TEXTURE := preload("res://assets/sprites/hand-torch_swing.png")
const SWAY_AMOUNT := 6.0

@onready var player: Player = get_tree().get_first_node_in_group("player")

var bob_time := 0.0
var base_offset: Vector2
var swing_offset := Vector2.ZERO


func _ready() -> void:
	# Remember how far from the window's bottom-right corner we start;
	# the corner itself is recomputed live so resizing keeps us in it.
	base_offset = Vector2(offset_left, offset_top)
	pivot_offset = Vector2(size.x * 0.5, size.y)
	player.attacked.connect(_on_attacked)


func _process(delta: float) -> void:
	# Advance the bob only while walking on the ground, in rhythm with speed.
	var ground_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if ground_speed > 0.1 and player.is_on_floor():
		bob_time += delta * ground_speed * 2.0
	# pivot_offset is the center for scaling too, so compensate for the
	# up-left shift the 3x scale gets from a bottom-center pivot.
	var corner_base := get_viewport_rect().size + base_offset \
			+ pivot_offset * (scale - Vector2.ONE)
	position = corner_base + swing_offset + Vector2(
		sin(bob_time) * SWAY_AMOUNT,
		absf(cos(bob_time)) * SWAY_AMOUNT * 0.5
	)


func _on_attacked() -> void:
	# Swap to the drawn swing frame and arc toward screen center.
	# The frame already carries most of the tilt, so the code
	# rotation stays subtle.
	texture = SWING_TEXTURE
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "swing_offset", Vector2(-60.0, -20.0), 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", -0.3, 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "swing_offset", Vector2.ZERO, 0.22)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.22)
	tween.chain().tween_callback(func() -> void: texture = IDLE_TEXTURE)
