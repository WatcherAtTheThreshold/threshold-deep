extends Area3D

## A single magic heart, shed by the slain. Stays on the floor if
## your magic is already full — come back for it.

# In half-heart units: 2 = a full magic heart, 1 = the half drop.
@export var amount := 2

const PICKUP_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/items/pickup_magic_heart_single1.wav"),
	preload("res://assets/audio/sfx/items/pickup_magic_heart_single2.wav"),
	preload("res://assets/audio/sfx/items/pickup_magic_heart_single3.wav"),
]


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player and body.add_magic_hearts(amount):
		_play_pickup_sound()
		queue_free()


func _play_pickup_sound() -> void:
	Sfx.play_at(PICKUP_SOUNDS[randi_range(0, PICKUP_SOUNDS.size() - 1)],
			global_position, -5.0)
