extends Area3D

# In half-heart units: 2 = a full heart, 1 = the half potion.
@export var heal_amount := 2
const PICKUP_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/items/pickup_potion1.ogg"),
	preload("res://assets/audio/sfx/items/pickup_potion2.ogg"),
	preload("res://assets/audio/sfx/items/pickup_potion3.ogg"),
]


func _ready() -> void:
	# "drops" = combat spoils lying on the floor. Grouped so the boss-floor
	# collapse can bring them down with everything else instead of leaving
	# them hanging over the shaft. Covers potion.tscn AND half_potion.tscn.
	add_to_group("drops")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	# Only consumed if it actually healed — at full health it stays
	# on the floor for later, which rewards remembering where it was.
	if body is Player and body.heal(heal_amount):
		_play_pickup_sound()
		queue_free()
	elif body.is_in_group("slimes"):
		# Slimes dissolve what they slither over.
		queue_free()


func _play_pickup_sound() -> void:
	Sfx.play_at(PICKUP_SOUNDS[randi_range(0, PICKUP_SOUNDS.size() - 1)],
			global_position)
