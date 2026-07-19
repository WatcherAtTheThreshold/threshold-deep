extends Area3D

const PICKUP_SOUND := preload("res://assets/audio/sfx/items/pickup_item.wav")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.pickup_sword()
		body.toast("THE SWORD", "cuts deeper")
		Sfx.play_at(PICKUP_SOUND, global_position)
		queue_free()
