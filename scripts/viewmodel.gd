extends TextureRect

const SWAY_AMOUNT := 6.0

@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player")

var bob_time := 0.0
var base_position: Vector2


func _ready() -> void:
	base_position = position


func _process(delta: float) -> void:
	# Advance the bob only while walking on the ground, in rhythm with speed.
	var ground_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if ground_speed > 0.1 and player.is_on_floor():
		bob_time += delta * ground_speed * 2.0
	position = base_position + Vector2(
		sin(bob_time) * SWAY_AMOUNT,
		absf(cos(bob_time)) * SWAY_AMOUNT * 0.5
	)
