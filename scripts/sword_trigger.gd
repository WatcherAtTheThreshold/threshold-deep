extends Area3D

## Step on the plate and the sword appears somewhere else on the
## floor. Find the plate but not the sword, and the hunt continues
## on the next level.

signal activated

## If set, the plate swaps to this art when stepped on instead of just
## dimming — a dedicated pressed state (the magic-heart trigger uses it;
## the boss plate leaves it null and keeps the spent-decor dim).
@export var pressed_texture: Texture2D

var used := false

@onready var sprite: Sprite3D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if used or not body is Player:
		return
	used = true
	$CollisionShape3D.set_deferred("disabled", true)
	if pressed_texture != null:
		# A dedicated pressed-state drawing shows the plate depressed —
		# let the art carry it, no dimming on top.
		sprite.texture = pressed_texture
	else:
		# The plate stays as spent decor, dimmed and dark.
		sprite.modulate = Color(0.55, 0.55, 0.55)
	var glow: OmniLight3D = get_node_or_null("Glow")
	if glow != null:
		glow.light_energy = 0.0
	activated.emit()
