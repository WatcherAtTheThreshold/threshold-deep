extends Area3D

## Step on the plate and the sword appears somewhere else on the
## floor. Find the plate but not the sword, and the hunt continues
## on the next level.

signal activated

var used := false

@onready var sprite: Sprite3D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if used or not body is Player:
		return
	used = true
	$CollisionShape3D.set_deferred("disabled", true)
	# The plate stays as spent decor, dimmed and dark.
	sprite.modulate = Color(0.55, 0.55, 0.55)
	var glow: OmniLight3D = get_node_or_null("Glow")
	if glow != null:
		glow.light_energy = 0.0
	activated.emit()
