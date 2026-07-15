extends CharacterBody3D

const FRAME_A := preload("res://assets/sprites/wizard1.png")
const FRAME_B := preload("res://assets/sprites/wizard2.png")
const DEAD_TEXTURE := preload("res://assets/sprites/wizard_dead.png")
const TEX_SHOOT_1 := preload("res://assets/sprites/wizard_shoot1.png")
const TEX_SHOOT_2 := preload("res://assets/sprites/wizard_shoot2.png")
const TEX_SHOOT_3 := preload("res://assets/sprites/wizard_shoot3.png")
const ORB_SCENE := preload("res://scenes/orb.tscn")
const POTION_SCENE := preload("res://scenes/potion.tscn")
const HALF_POTION_SCENE := preload("res://scenes/half_potion.tscn")
const HEART_DROP_SCENE := preload("res://scenes/magic_heart_drop.tscn")
const HALF_HEART_DROP_SCENE := preload("res://scenes/half_magic_heart_drop.tscn")
const WALK_FRAME_TIME := 0.3

const SPEED := 1.6
const RETREAT_RANGE := 4.0
const CAST_RANGE := 11.0
const SIGHT_RANGE := 12.0
const INFIGHT_SIGHT_RANGE := 20.0
const BASE_CAST_COOLDOWN := 2.2
const CHARGE_TIME := 0.45
const RECOVERY_TIME := 0.4
const MAX_HEALTH := 4

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

@onready var cast_glow: OmniLight3D = $CastGlow
@onready var sprite: Sprite3D = $Sprite
@onready var step_sound: AudioStreamPlayer3D = $StepSound
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	var t := _get_target()
	var to_target := t.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	var sight := SIGHT_RANGE if t == player else INFIGHT_SIGHT_RANGE
	var sees_target := dist < sight and _can_see(t)

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
			velocity.x = away.x * SPEED
			velocity.z = away.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
			velocity.z = move_toward(velocity.z, 0.0, SPEED)
		cast_timer -= delta
		if cast_timer <= 0.0 and dist <= CAST_RANGE:
			charging = true
			charge_timer = CHARGE_TIME
			_start_cast_glow()
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

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
		sprite.texture = FRAME_A if int(walk_time / WALK_FRAME_TIME) % 2 == 0 else FRAME_B
	else:
		sprite.texture = FRAME_A
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


func setup(depth: int) -> void:
	# Deeper wizards cast a little more often.
	cast_cooldown = maxf(BASE_CAST_COOLDOWN - 0.08 * (depth - 1), 1.4)


func kill_label() -> String:
	return "Wizard"


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
	velocity += push_dir * 6.0
	if attacker != null and attacker != self:
		# Pain redirects attention to whoever caused it.
		target = attacker
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
	sprite.texture = DEAD_TEXTURE
	sprite.modulate = Color.WHITE
	velocity = Vector3.ZERO
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
