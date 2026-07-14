extends Area3D

const HEAL_AMOUNT := 1
const PICKUP_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/items/pickup_potion1.wav"),
	preload("res://assets/audio/sfx/items/pickup_potion2.wav"),
	preload("res://assets/audio/sfx/items/pickup_potion3.wav"),
]


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	# Only consumed if it actually healed — at full health it stays
	# on the floor for later, which rewards remembering where it was.
	if body is Player and body.heal(HEAL_AMOUNT):
		_play_pickup_sound()
		queue_free()
	elif body.is_in_group("slimes"):
		# Slimes dissolve what they slither over.
		queue_free()


func _play_pickup_sound() -> void:
	# One-shot that outlives this node: parented to the world,
	# autoplays on entering the tree, frees itself when done.
	var one_shot := AudioStreamPlayer3D.new()
	one_shot.stream = PICKUP_SOUNDS[randi_range(0, PICKUP_SOUNDS.size() - 1)]
	one_shot.position = global_position
	one_shot.autoplay = true
	one_shot.finished.connect(one_shot.queue_free)
	get_parent().add_child.call_deferred(one_shot)
