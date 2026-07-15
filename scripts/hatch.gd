extends Area3D

## The way down. Boss arenas spawn it sealed at the room's heart —
## visible, dark, waiting — and open() releases it on victory. It
## never swallows a player already standing on it when it opens:
## step off, then step in by choice.

const CLOSED_TINT := Color(0.32, 0.32, 0.4)

var closed := false  # set before add_child for boss hatches
var armed := true

@onready var sprite: Sprite3D = $Sprite
@onready var glow: OmniLight3D = $Glow


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if closed:
		armed = false
		sprite.modulate = CLOSED_TINT
		glow.light_energy = 0.0


func open() -> void:
	closed = false
	sprite.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(glow, "light_energy", 0.8, 0.8)
	# Arm only if nobody is standing on it right now.
	armed = true
	for body in get_overlapping_bodies():
		if body is Player:
			armed = false


func _on_body_exited(body: Node3D) -> void:
	if body is Player and not closed:
		armed = true


func _on_body_entered(body: Node3D) -> void:
	if closed or not armed:
		return
	if body is Player:
		body.start_descent(global_position)
