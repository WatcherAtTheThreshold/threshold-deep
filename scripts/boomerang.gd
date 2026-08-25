extends Area3D

## The thrown boomerang: out in a straight line until a wall or max
## range, then homing back to the thrower's hand. Pierces, and hits each
## enemy once per LEG — but `damage` is the throw's TOTAL and `_leg_damage`
## splits it, so two pecks add up to one weapon's worth rather than two.
## The return hit drags what it touches toward you. Wall hits splinter
## wood like orbs do.

const FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/boomerang/boomerang_shot1.png"),
	preload("res://assets/sprites/boomerang/boomerang_shot2.png"),
	preload("res://assets/sprites/boomerang/boomerang_shot3.png"),
]
const HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/boomerang_hit1.ogg"),
	preload("res://assets/audio/sfx/player/boomerang_hit2.ogg"),
	preload("res://assets/audio/sfx/player/boomerang_hit3.ogg"),
]
const CATCH_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/boomerang_catch_slap1.ogg"),
	preload("res://assets/audio/sfx/player/boomerang_catch_slap2.ogg"),
	preload("res://assets/audio/sfx/player/boomerang_catch_slap3.ogg"),
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
	# Fresh leg: everyone is hittable again on the way home. The return hit is
	# kept deliberately — its knockback runs along `direction`, which on the
	# way back points AT the thrower, so it DRAGS enemies toward you. That is
	# the only pull in a game made of shoves, and it plays against the shafts.
	hit_this_leg.clear()


func _leg_damage() -> int:
	# `damage` is the THROW'S TOTAL, not a per-hit number — the split lives
	# here so Rage scales the boomerang exactly like every other weapon.
	#
	# Paying the full amount on BOTH legs (the behaviour until 2026-08-11) was
	# two bugs wearing one coat: it doubled the weapon — 8 to a lined-up body,
	# at range, through a row, at no risk — AND it doubled the crystal, since
	# `attack_damage` is `4 + rage_tier`, so Rage's flat +2 became +4 here
	# alone. It also hid a whole system: a necromancer has 4 HP and died before
	# the outbound leg finished, so Rot/Ember/Cinder never ticked where anyone
	# could see them, and the torch was the only weapon showing the game its
	# own Pillar-4 art.
	#
	# Ceil out, floor back, so an odd total is never lost: 4 pays 2+2, 5 pays
	# 3+2, 6 pays 3+3 — the total always equals `attack_damage`. The outbound
	# leg taking the larger half is deliberate; the throw is the aimed part,
	# and an enemy that steps out of the return line still keeps most of it.
	# ceili/floori over `/ 2`, which Godot rightly warns about: integer division
	# silently discarding a remainder is usually a bug, and a reader can't tell
	# a deliberate truncation from a careless one. These name the intent, and
	# the comment above and the code now say the same thing.
	if returning:
		return floori(damage / 2.0)
	return ceili(damage / 2.0)


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
			var leg := _leg_damage()
			body.take_damage(leg, direction, thrower)
			RunState.record_damage_dealt(leg)
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
