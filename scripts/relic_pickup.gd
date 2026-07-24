extends Area3D

## One script for the one-time relics (boots, armor, staff): set
## `grant` to the Player method that claims it.

const PICKUP_SOUND := preload("res://assets/audio/sfx/items/pickup_item.wav")
# The crystal voices: the A-minor scale, two octaves of A. Each
# crystal owns a note; tier 2 is one step up from tier 1, so an
# upgrade literally ascends. All in the key the whole score lives in.
const CRYSTAL_NOTES: Array[AudioStream] = [
	preload("res://assets/audio/sfx/items/pickup_crystal1.wav"),
	preload("res://assets/audio/sfx/items/pickup_crystal2.wav"),
	preload("res://assets/audio/sfx/items/pickup_crystal3.wav"),
	preload("res://assets/audio/sfx/items/pickup_crystal4.wav"),
	preload("res://assets/audio/sfx/items/pickup_crystal5.wav"),
	preload("res://assets/audio/sfx/items/pickup_crystal6.wav"),
	preload("res://assets/audio/sfx/items/pickup_crystal7.wav"),
	preload("res://assets/audio/sfx/items/pickup_crystal8.wav"),
]

@export var grant := "pickup_fleetfoot"
@export var note := 0  # 1-8 = this crystal's scale voice; 0 = generic
@export var toast_title := ""
@export var toast_desc := ""

# Pedestals in item rooms are a commitment: consumed even if owned.
var always_consume := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	if body.call(grant):
		if toast_title != "":
			body.toast(toast_title, toast_desc)
		_play_pickup_sound()
		queue_free()
	elif always_consume:
		queue_free()


func _play_pickup_sound() -> void:
	if note >= 1 and note <= CRYSTAL_NOTES.size():
		Sfx.play_at(CRYSTAL_NOTES[note - 1], global_position, -5.0)
	else:
		Sfx.play_at(PICKUP_SOUND, global_position)
