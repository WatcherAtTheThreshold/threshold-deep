extends Area3D

const PICKUP_SOUND := preload("res://assets/audio/sfx/items/pickup_potion.wav")

# Pedestals in item rooms are a commitment: consumed even at cap.
var always_consume := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	if body.add_heart_container():
		_play_pickup_sound()
		queue_free()
	elif always_consume:
		queue_free()


func _play_pickup_sound() -> void:
	var one_shot := AudioStreamPlayer3D.new()
	one_shot.stream = PICKUP_SOUND
	one_shot.position = global_position
	one_shot.autoplay = true
	one_shot.finished.connect(one_shot.queue_free)
	get_parent().add_child.call_deferred(one_shot)
