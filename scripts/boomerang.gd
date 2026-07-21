extends Area3D

## The thrown boomerang: out in a straight line until a wall or max
## range, then homing back to the thrower's hand. Pierces — each
## enemy can be hit once per leg, so a lined-up row gets sliced
## twice. Wall hits splinter wood like orbs do.

const FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/boomerang_shot1.png"),
	preload("res://assets/sprites/boomerang_shot2.png"),
	preload("res://assets/sprites/boomerang_shot3.png"),
]
const HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/boomerang_hit1.wav"),
	preload("res://assets/audio/sfx/player/boomerang_hit2.wav"),
	preload("res://assets/audio/sfx/player/boomerang_hit3.wav"),
]
const CATCH_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/boomerang_catch_slap1.wav"),
	preload("res://assets/audio/sfx/player/boomerang_catch_slap2.wav"),
	preload("res://assets/audio/sfx/player/boomerang_catch_slap3.wav"),
]
const SPEED_OUT := 8.0
const SPEED_BACK := 9.5
const MAX_RANGE := 9.0
const LIFETIME := 8.0
const FRAME_TIME := 0.08
const CATCH_RANGE := 0.9

var damage := 4
var speed_scale := 1.0  # the Hasty Little Stone quickens the throw
var direction := Vector3.FORWARD
# CharacterBody3D, not Player: a class-level Player type here forms a
# preload cycle with player.gd (which preloads this scene) and kills
# the scene load with "Parse Error: Busy".
var thrower: CharacterBody3D = null
var returning := false
var origin := Vector3.ZERO
var time := 0.0
var hit_this_leg := {}

@onready var sprite: Sprite3D = $Sprite


func _ready() -> void:
	origin = global_position
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	time += delta
	if time > LIFETIME:
		_finish(false)
		return
	sprite.texture = FRAMES[int(time / FRAME_TIME) % FRAMES.size()]
	# The whirr rides the spin for the whole flight.
	if not $Whirr.playing:
		$Whirr.play()
	if returning:
		if thrower == null or not is_instance_valid(thrower):
			_finish(false)
			return
		var target := thrower.global_position + Vector3.UP * 0.4
		var to_target := target - global_position
		if to_target.length() < CATCH_RANGE:
			_finish(true)
			return
		direction = to_target.normalized()
		position += direction * SPEED_BACK * speed_scale * delta
	else:
		position += direction * SPEED_OUT * speed_scale * delta
		if global_position.distance_to(origin) >= MAX_RANGE:
			_turn_back()


func _turn_back() -> void:
	returning = true
	# Fresh leg: everyone is hittable again on the way home.
	hit_this_leg.clear()


func _finish(caught := false) -> void:
	if caught:
		Sfx.play_ui(CATCH_SOUNDS[randi_range(0, CATCH_SOUNDS.size() - 1)], -4.0)
	if thrower != null and is_instance_valid(thrower):
		thrower.boomerang_returned()
	queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body == thrower:
		if returning:
			_finish(true)
		return
	if body.is_in_group("enemies"):
		if not hit_this_leg.has(body.get_instance_id()):
			hit_this_leg[body.get_instance_id()] = true
			body.take_damage(damage, direction, thrower)
			RunState.record_damage_dealt(damage)
			if thrower is Player:
				thrower.apply_dots(body)
			Sfx.play_at(HIT_SOUNDS[randi_range(0, HIT_SOUNDS.size() - 1)],
					global_position, -4.0)
		# Pierces: keep flying.
	elif body is GridMap:
		Sfx.play_at(HIT_SOUNDS[randi_range(0, HIT_SOUNDS.size() - 1)],
				global_position, -4.0)
		var scene := get_tree().current_scene
		if scene != null and scene.has_method("damage_wall"):
			scene.damage_wall(global_position + direction * 0.3, -direction, damage)
		if not returning:
			_turn_back()
