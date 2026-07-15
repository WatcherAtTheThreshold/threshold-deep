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
const SPEED_OUT := 8.0
const SPEED_BACK := 9.5
const MAX_RANGE := 9.0
const LIFETIME := 8.0
const FRAME_TIME := 0.08
const CATCH_RANGE := 0.9

var damage := 2
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
		_finish()
		return
	sprite.texture = FRAMES[int(time / FRAME_TIME) % FRAMES.size()]
	if returning:
		if thrower == null or not is_instance_valid(thrower):
			_finish()
			return
		var target := thrower.global_position + Vector3.UP * 0.4
		var to_target := target - global_position
		if to_target.length() < CATCH_RANGE:
			_finish()
			return
		direction = to_target.normalized()
		position += direction * SPEED_BACK * delta
	else:
		position += direction * SPEED_OUT * delta
		if global_position.distance_to(origin) >= MAX_RANGE:
			_turn_back()


func _turn_back() -> void:
	returning = true
	# Fresh leg: everyone is hittable again on the way home.
	hit_this_leg.clear()


func _finish() -> void:
	if thrower != null and is_instance_valid(thrower):
		thrower.boomerang_returned()
	queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body == thrower:
		if returning:
			_finish()
		return
	if body.is_in_group("enemies"):
		if not hit_this_leg.has(body.get_instance_id()):
			hit_this_leg[body.get_instance_id()] = true
			body.take_damage(damage, direction, thrower)
			RunState.record_damage_dealt(damage)
		# Pierces: keep flying.
	elif body is GridMap:
		var scene := get_tree().current_scene
		if scene != null and scene.has_method("damage_wall"):
			scene.damage_wall(global_position + direction * 0.3, -direction, damage)
		if not returning:
			_turn_back()
