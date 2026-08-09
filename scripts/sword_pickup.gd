extends Area3D

const PICKUP_SOUND := preload("res://assets/audio/sfx/items/pickup_item.ogg")

# Pedestals set this; the sword always grants, so it always consumes.
var always_consume := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.pickup_sword()
		# The sword has its own scene and script rather than relic_pickup.gd
		# (pickup_sword returns void, not the bool that script branches on),
		# so it needs its own call — the one relic that can't ride the funnel.
		RunState.record_item(&"pickup_sword")
		body.toast("THE SWORD", "cuts deeper")
		Sfx.play_at(PICKUP_SOUND, global_position)
		queue_free()
