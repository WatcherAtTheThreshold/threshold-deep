extends TextureRect

const SWAY_AMOUNT := 6.0

@onready var player: Player = get_tree().get_first_node_in_group("player")

var bob_time := 0.0
var base_offset: Vector2
var strike_offset := Vector2.ZERO


func _ready() -> void:
	base_offset = Vector2(offset_left, offset_top)
	# Pivot at the bottom-left corner so the attack tilt leans the
	# torch toward screen center without lifting the canvas edges.
	pivot_offset = Vector2(0.0, size.y)
	player.attacked.connect(_on_attacked)


func _process(delta: float) -> void:
	var ground_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if ground_speed > 0.1 and player.is_on_floor():
		bob_time += delta * ground_speed * 2.0
	# Mirrored sway of the right hand, pinned to the bottom-left corner.
	var corner_base := Vector2(0.0, get_viewport_rect().size.y) + base_offset \
			+ pivot_offset * (scale - Vector2.ONE)
	position = corner_base + strike_offset + Vector2(
		-sin(bob_time) * SWAY_AMOUNT,
		absf(cos(bob_time)) * SWAY_AMOUNT * 0.5
	)


func _on_attacked() -> void:
	# Body-lean: as the sword arm swings, the torch dips down-left
	# with a slight lean, like weight shifting into the strike.
	if not visible:
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "strike_offset", Vector2(-12.0, 10.0), 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", -0.09, 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "strike_offset", Vector2.ZERO, 0.26)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.26)
