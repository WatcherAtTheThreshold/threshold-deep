extends CharacterBody3D

const FRONT_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_front1.png"),
	preload("res://assets/sprites/wizard/wizard_front2.png"),
]
const SIDE_FRAMES: Array[Texture2D] = [  # drawn facing left; flipped for right
	preload("res://assets/sprites/wizard/wizard_side1.png"),
	preload("res://assets/sprites/wizard/wizard_side2.png"),
]
const BACK_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_back1.png"),
	preload("res://assets/sprites/wizard/wizard_back2.png"),
]
const DEAD_TEXTURE := preload("res://assets/sprites/wizard/wizard_dead.png")
const TEX_SHOOT_1 := preload("res://assets/sprites/wizard/wizard_shoot1.png")
const TEX_SHOOT_2 := preload("res://assets/sprites/wizard/wizard_shoot2.png")
const TEX_SHOOT_3 := preload("res://assets/sprites/wizard/wizard_shoot3.png")
const ORB_SCENE := preload("res://scenes/orb.tscn")
const TAKE_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/wizard_take_hit1.wav"),
	preload("res://assets/audio/sfx/enemies/wizard_take_hit2.wav"),
	preload("res://assets/audio/sfx/enemies/wizard_take_hit3.wav"),
]
const POTION_SCENE := preload("res://scenes/potion.tscn")
const HALF_POTION_SCENE := preload("res://scenes/half_potion.tscn")
const HEART_DROP_SCENE := preload("res://scenes/magic_heart_drop.tscn")
const HALF_HEART_DROP_SCENE := preload("res://scenes/half_magic_heart_drop.tscn")
const WALK_FRAME_TIME := 0.3

const SPEED := 1.6
const RETREAT_RANGE := 4.0
const CAST_RANGE := 11.0
const SIGHT_RANGE := 14.0  # forward vision reach, cone-gated
const INFIGHT_SIGHT_RANGE := 20.0
const HEAR_RANGE := 3.5  # sensed this close regardless of facing
const SIGHT_CONE_DEG := 110.0  # forward vision arc, full width
const BASE_CAST_COOLDOWN := 2.2
const CHARGE_TIME := 0.45
const RECOVERY_TIME := 0.4
const MAX_HEALTH := 4
const KNOCK_TIME := 0.35
const KNOCK_FRICTION := 30.0
const FALL_Y := -1.5
# Wizards drift when unwatched: slower, shorter wanders than bones.
const WANDER_SPEED := 0.8
const WANDER_LEG_MIN := 0.8
const WANDER_LEG_MAX := 2.0
const WANDER_PAUSE_MIN := 2.0
const WANDER_PAUSE_MAX := 6.0

var health := MAX_HEALTH
var cast_cooldown := BASE_CAST_COOLDOWN
var cast_timer := 1.0
var charge_timer := 0.0
var recovery_timer := 0.0
var charging := false
var walk_time := 0.0
var dead := false
var target: PhysicsBody3D = null
var glow_tween: Tween
var knock_timer := 0.0
var last_attacker: PhysicsBody3D = null
var facing := Vector3.FORWARD
var wander_dir := Vector3.ZERO
var wander_timer := 0.0
var wander_wait := randf_range(0.0, WANDER_PAUSE_MAX)  # desynced from birth

@onready var cast_glow: OmniLight3D = $CastGlow
@onready var sprite: Sprite3D = $Sprite
@onready var step_sound: AudioStreamPlayer3D = $StepSound
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if dead:
		return
	if global_position.y < FALL_Y:
		_fall_into_dark()
		return
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
	var sees_target := _perceives(t, dist, sight)
	if sees_target and dist > 0.01:
		# A caster keeps its eyes on you even while backpedaling.
		facing = to_target.normalized()

	if charging:
		# Rooted while the cast winds up — orb at the chest, glow
		# swelling: the telegraph is the tell.
		velocity.x = 0.0
		velocity.z = 0.0
		charge_timer -= delta
		if charge_timer <= 0.0:
			charging = false
			_stop_cast_glow()
			if sees_target:
				_fire_orb(t)
				recovery_timer = RECOVERY_TIME
			cast_timer = cast_cooldown
	elif sees_target:
		# Keep respectful distance: back away if the target closes in.
		if dist < RETREAT_RANGE:
			var away := -to_target.normalized()
			if _floor_ahead(away):
				velocity.x = away.x * SPEED
				velocity.z = away.z * SPEED
			else:
				# A rim at its back: nowhere left to give, so it holds.
				velocity.x = 0.0
				velocity.z = 0.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
			velocity.z = move_toward(velocity.z, 0.0, SPEED)
		cast_timer -= delta
		if cast_timer <= 0.0 and dist <= CAST_RANGE:
			charging = true
			charge_timer = CHARGE_TIME
			_start_cast_glow()
	else:
		_wander(delta)

	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if charging:
		# Anticipation: the orb drawn to the chest.
		sprite.texture = TEX_SHOOT_1
	elif recovery_timer > 0.0:
		# Release, then follow-through.
		recovery_timer -= delta
		sprite.texture = TEX_SHOOT_2 if recovery_timer > RECOVERY_TIME * 0.5 else TEX_SHOOT_3
	elif moving:
		walk_time += delta
		_update_view(int(walk_time / WALK_FRAME_TIME) % 2)
	else:
		_update_view(0)
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


func setup(depth: int) -> void:
	# Deeper wizards cast a little more often.
	cast_cooldown = maxf(BASE_CAST_COOLDOWN - 0.08 * (depth - 1), 1.4)


func kill_label() -> String:
	return "Wizard"


func _floor_ahead(dir: Vector3) -> bool:
	# Probe for ground half a step ahead. Steering respects the rim;
	# only momentum (the knock skid) carries a body over it.
	var probe := global_position + dir * 0.7
	var query := PhysicsRayQueryParameters3D.create(
		probe, probe + Vector3.DOWN * 3.0, 1, [get_rid()])
	query.hit_from_inside = true
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _wander(delta: float) -> void:
	# Unwatched wizards drift about: short slow legs, long pauses.
	# Walls and rims end a leg early; sight overrides everything.
	if wander_timer > 0.0:
		wander_timer -= delta
		if is_on_wall() or not _floor_ahead(wander_dir):
			wander_timer = 0.0
		facing = wander_dir
		velocity.x = wander_dir.x * WANDER_SPEED
		velocity.z = wander_dir.z * WANDER_SPEED
		if wander_timer <= 0.0:
			wander_wait = randf_range(WANDER_PAUSE_MIN, WANDER_PAUSE_MAX)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		wander_wait -= delta
		if wander_wait <= 0.0:
			wander_dir = Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
			wander_timer = randf_range(WANDER_LEG_MIN, WANDER_LEG_MAX)


func _update_view(frame: int) -> void:
	# Four-way billboard, Doom style: project the heading onto the
	# camera's axes — the dominant component picks the view. Side art
	# faces left, so it flips when heading toward screen-right.
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var depth := facing.dot(-cam.global_transform.basis.z)
	var side := facing.dot(cam.global_transform.basis.x)
	if absf(depth) >= absf(side):
		sprite.flip_h = false
		sprite.texture = (BACK_FRAMES if depth > 0.0 else FRONT_FRAMES)[frame]
	else:
		sprite.flip_h = side > 0.0
		sprite.texture = SIDE_FRAMES[frame]


func _fall_into_dark() -> void:
	# The under-place keeps what it catches: credited if the player's
	# shove sent it over, but the body and its drops are gone.
	if last_attacker is Player:
		RunState.record_kill(kill_label())
	queue_free()


func _get_target() -> PhysicsBody3D:
	# A grudge holds only while its object stands; otherwise, the player.
	if target != null and is_instance_valid(target) and not target.get("dead"):
		return target
	target = null
	return player


func _start_cast_glow() -> void:
	# The chest-orb powers up: light swells across the whole charge.
	if glow_tween != null:
		glow_tween.kill()
	cast_glow.light_energy = 0.25
	glow_tween = create_tween()
	glow_tween.tween_property(cast_glow, "light_energy", 1.5, CHARGE_TIME)


func _stop_cast_glow() -> void:
	# The orb has left (or the cast broke) — the wizard goes dark.
	if glow_tween != null:
		glow_tween.kill()
	cast_glow.light_energy = 0.0


func _fire_orb(t: PhysicsBody3D) -> void:
	var from := global_position + Vector3.UP * 0.3
	var orb := ORB_SCENE.instantiate()
	orb.shooter = self
	orb.direction = (t.global_position - from).normalized()
	orb.position = from + orb.direction * 0.8
	get_parent().add_child.call_deferred(orb)


func _perceives(who: PhysicsBody3D, dist: float, reach: float) -> bool:
	# A known threat — a grudge, or infighting kin — is hunted on range +
	# line of sight alone. The player, unprovoked, must be HEARD (close, any
	# direction) or SEEN (inside the forward cone, at range, clear line):
	# no more noticing you through the back of the skull.
	if who != player or target != null:
		return dist < reach and _can_see(who)
	if dist <= HEAR_RANGE:
		return true
	if dist > SIGHT_RANGE:
		return false
	var to_who := who.global_position - global_position
	to_who.y = 0.0
	if facing.dot(to_who.normalized()) < cos(deg_to_rad(SIGHT_CONE_DEG * 0.5)):
		return false
	return _can_see(who)


func _can_see(t: PhysicsBody3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.5,
		t.global_position + Vector3.UP * 0.3,
		1, [get_rid(), t.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func take_damage(amount: int, push_dir: Vector3, attacker: PhysicsBody3D = null) -> void:
	if dead:
		return
	health -= amount
	Sfx.play_at(TAKE_HIT_SOUNDS[randi_range(0, TAKE_HIT_SOUNDS.size() - 1)],
			global_position, -4.0)
	velocity += push_dir * 6.0
	knock_timer = KNOCK_TIME
	if attacker != null and attacker != self:
		# Pain redirects attention to whoever caused it.
		target = attacker
		last_attacker = attacker
	sprite.modulate = Color(1.0, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)
	if health <= 0:
		_die(attacker == null or attacker is Player)


func _die(by_player: bool) -> void:
	# The corpse stays: crumpled robes where the wizard fell.
	dead = true
	_stop_cast_glow()
	step_sound.stop()
	if by_player:
		RunState.record_kill(kill_label())
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	sprite.flip_h = false
	sprite.texture = DEAD_TEXTURE
	sprite.modulate = Color.WHITE
	velocity = Vector3.ZERO
	# Roll drops off the corpse so the sprites never share a depth
	# (coplanar billboards z-fight). Halves are the common change,
	# full drops the treat.
	var roll := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU) * 0.45
	var r := randf()
	if RunState.lucky:
		# The Lucky Luck Stone: the deep is generous.
		r *= 0.6
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
