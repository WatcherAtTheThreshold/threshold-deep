extends Area3D

## One script for the one-time relics (boots, armor, staff): set
## `grant` to the Player method that claims it.

const PICKUP_SOUND := preload("res://assets/audio/sfx/items/pickup_item.wav")

@export var grant := "pickup_fleetfoot"
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
	Sfx.play_at(PICKUP_SOUND, global_position)
