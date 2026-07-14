extends Area3D

## A single magic heart, shed by the slain. Stays on the floor if
## your magic is already full — come back for it.

const PICKUP_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/items/pickup_magic_heart_single1.wav"),
	preload("res://assets/audio/sfx/items/pickup_magic_heart_single2.wav"),
	preload("res://assets/audio/sfx/items/pickup_magic_heart_single3.wav"),
]


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player and body.add_magic_hearts(1):
		_play_pickup_sound()
		queue_free()


func _play_pickup_sound() -> void:
	var one_shot := AudioStreamPlayer3D.new()
	one_shot.stream = PICKUP_SOUNDS[randi_range(0, PICKUP_SOUNDS.size() - 1)]
	one_shot.position = global_position
	one_shot.autoplay = true
	one_shot.finished.connect(one_shot.queue_free)
	get_parent().add_child.call_deferred(one_shot)
