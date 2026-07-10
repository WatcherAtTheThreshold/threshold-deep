extends TextureRect

const SWAY_AMOUNT := 6.0

@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player")

var bob_time := 0.0
var base_position: Vector2
var swing_offset := Vector2.ZERO


func _ready() -> void:
	base_position = position
	pivot_offset = Vector2(size.x * 0.5, size.y)
	player.attacked.connect(_on_attacked)


func _process(delta: float) -> void:
	# Advance the bob only while walking on the ground, in rhythm with speed.
	var ground_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if ground_speed > 0.1 and player.is_on_floor():
		bob_time += delta * ground_speed * 2.0
	position = base_position + swing_offset + Vector2(
		sin(bob_time) * SWAY_AMOUNT,
		absf(cos(bob_time)) * SWAY_AMOUNT * 0.5
	)


func _on_attacked() -> void:
	# Quick arc toward screen center, then settle back.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "swing_offset", Vector2(-60.0, -20.0), 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", -0.55, 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "swing_offset", Vector2.ZERO, 0.22)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.22)
