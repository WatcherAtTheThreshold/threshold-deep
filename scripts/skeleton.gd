extends CharacterBody3D

const DEATH_SOUND := preload("res://assets/audio/sfx/enemies/skeleton_death.wav")
const REVIVE_SOUND := preload("res://assets/audio/sfx/enemies/skeleton_revive.wav")
const TAKE_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/skeleton_take_hit1.wav"),
	preload("res://assets/audio/sfx/enemies/skeleton_take_hit2.wav"),
	preload("res://assets/audio/sfx/enemies/skeleton_take_hit3.wav"),
]
const POTION_SCENE := preload("res://scenes/potion.tscn")
const HALF_POTION_SCENE := preload("res://scenes/half_potion.tscn")
const HEART_DROP_SCENE := preload("res://scenes/magic_heart_drop.tscn")
const HALF_HEART_DROP_SCENE := preload("res://scenes/half_magic_heart_drop.tscn")

const FRAME_A := preload("res://assets/sprites/skeleton.png")
const FRAME_B := preload("res://assets/sprites/skeleton2.png")
const DEAD_TEXTURE := preload("res://assets/sprites/skeleton_dead.png")
const RISE_TEXTURE := preload("res://assets/sprites/skeleton_mid_rise.png")
const WALK_FRAME_TIME := 0.3

const RISE_CHANCE := 0.15
const RISE_RANGE := 3.5
const RISE_TIME := 1.0
const RISE_GRACE := 4.0
const RISEN_HEALTH := 4

const BASE_SPEED := 2.0
const MAX_SPEED := 3.2
const SIGHT_RANGE := 10.0
const INFIGHT_SIGHT_RANGE := 20.0
const ATTACK_RANGE := 1.4
const ATTACK_COOLDOWN := 1.2
const MAX_HEALTH := 6
const KNOCK_TIME := 0.35
const KNOCK_FRICTION := 30.0

var speed := BASE_SPEED
var health := MAX_HEALTH
var attack_timer := 0.0
var walk_time := 0.0
var dead := false
var restless := false
var rising := false
var rise_timer := 0.0
var rise_delay := 0.0
var target: PhysicsBody3D = null
var knock_timer := 0.0

@onready var sprite: Sprite3D = $Sprite
@onready var step_sound: AudioStreamPlayer3D = $StepSound
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if dead:
		# Some piles are restless: stir when the player comes close,
		# take a slow second to stand — smash them mid-rise to
		# scatter the bones for good.
		if restless:
			rise_delay = maxf(rise_delay - delta, 0.0)
			if rising:
				rise_timer -= delta
				if rise_timer <= 0.0:
					_rise()
			elif rise_delay == 0.0 and is_instance_valid(player):
				var to_p := player.global_position - global_position
				to_p.y = 0.0
				if to_p.length() < RISE_RANGE:
					rising = true
					rise_timer = RISE_TIME
					sprite.texture = RISE_TEXTURE
					# The rattle: bones stirring, heard before seen.
					Sfx.play_at(REVIVE_SOUND, global_position, -2.0)
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	if not is_on_floor():
		velocity += get_gravity() * delta

	if knock_timer > 0.0:
		# Staggered: the shove owns the body for a beat. Skid under
		# friction — steering would erase the knockback next tick.
		knock_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, KNOCK_FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, KNOCK_FRICTION * delta)
		move_and_slide()
		return

	var t := _get_target()
	var to_target := t.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	var sight := SIGHT_RANGE if t == player else INFIGHT_SIGHT_RANGE

	if dist < sight and _can_see(t):
		if dist > ATTACK_RANGE:
			var dir := to_target.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if attack_timer == 0.0:
				attack_timer = ATTACK_COOLDOWN
				t.take_damage(2, to_target.normalized(), self)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

	# Two-frame shamble while moving; rest on the base frame when still.
	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if moving:
		walk_time += delta
		sprite.texture = FRAME_A if int(walk_time / WALK_FRAME_TIME) % 2 == 0 else FRAME_B
	else:
		sprite.texture = FRAME_A
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


func setup(depth: int) -> void:
	# Deeper floors: faster bones, and a bit tougher every third floor.
	speed = minf(BASE_SPEED + 0.1 * (depth - 1), MAX_SPEED)
	@warning_ignore("integer_division")
	health += 2 * ((depth - 1) / 3)


func kill_label() -> String:
	return "Skeleton"


func _get_target() -> PhysicsBody3D:
	# A grudge holds only while its object stands; otherwise, the player.
	if target != null and is_instance_valid(target) and not target.get("dead"):
		return target
	target = null
	return player


func _can_see(t: PhysicsBody3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.5,
		t.global_position + Vector3.UP * 0.3,
		1, [get_rid(), t.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _rise() -> void:
	# It remembers you.
	dead = false
	restless = false
	rising = false
	health = RISEN_HEALTH
	target = player
	add_to_group("enemies")
	$CollisionShape3D.set_deferred("disabled", false)
	sprite.texture = FRAME_A


func take_damage(amount: int, push_dir: Vector3, attacker: PhysicsBody3D = null) -> void:
	if dead:
		if rising:
			# Caught it mid-rise: the bones scatter for good.
			restless = false
			rising = false
			sprite.texture = DEAD_TEXTURE
		return
	health -= amount
	Sfx.play_at(TAKE_HIT_SOUNDS[randi_range(0, TAKE_HIT_SOUNDS.size() - 1)],
			global_position, -4.0)
	velocity += push_dir * 6.0
	knock_timer = KNOCK_TIME
	if attacker != null and attacker != self:
		# Pain redirects attention to whoever caused it.
		target = attacker
	sprite.modulate = Color(1.0, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)
	if health <= 0:
		_die(attacker == null or attacker is Player)


func _die(by_player: bool) -> void:
	# The corpse stays: swap to the bone pile and stop being a threat.
	dead = true
	step_sound.stop()
	Sfx.play_at(DEATH_SOUND, global_position, -3.0)
	if by_player:
		RunState.record_kill(kill_label())
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	sprite.texture = DEAD_TEXTURE
	velocity = Vector3.ZERO
	restless = randf() < RISE_CHANCE
	rise_delay = RISE_GRACE
	# Roll drops off the corpse so the sprites never share a depth
	# (coplanar billboards z-fight). Halves are the common change,
	# full drops the treat.
	var roll := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU) * 0.45
	var r := randf()
	var drop: Node3D = null
	if r < 0.12:
		drop = POTION_SCENE.instantiate()
	elif r < 0.28:
		drop = HALF_POTION_SCENE.instantiate()
	elif r < 0.34:
		drop = HEART_DROP_SCENE.instantiate()
	elif r < 0.44:
		drop = HALF_HEART_DROP_SCENE.instantiate()
	if drop != null:
		drop.position = global_position + Vector3(0, -0.9, 0) + roll
		get_parent().add_child.call_deferred(drop)
