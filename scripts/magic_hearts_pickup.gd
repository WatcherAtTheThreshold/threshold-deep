extends Area3D

const PICKUP_SOUND := preload("res://assets/audio/sfx/items/pickup_potion.wav")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player and body.add_magic_hearts(3):
		_play_pickup_sound()
		queue_free()


func _play_pickup_sound() -> void:
	var one_shot := AudioStreamPlayer3D.new()
	one_shot.stream = PICKUP_SOUND
	one_shot.position = global_position
	one_shot.autoplay = true
	one_shot.finished.connect(one_shot.queue_free)
	get_parent().add_child.call_deferred(one_shot)
