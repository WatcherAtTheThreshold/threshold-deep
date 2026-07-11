extends CharacterBody3D

const POTION_SCENE := preload("res://scenes/potion.tscn")
const POTION_DROP_CHANCE := 0.25

const FRAME_A := preload("res://assets/sprites/skeleton.png")
const FRAME_B := preload("res://assets/sprites/skeleton2.png")
const DEAD_TEXTURE := preload("res://assets/sprites/skeleton_dead.png")
const WALK_FRAME_TIME := 0.3

const BASE_SPEED := 2.0
const MAX_SPEED := 3.2
const SIGHT_RANGE := 10.0
const INFIGHT_SIGHT_RANGE := 20.0
const ATTACK_RANGE := 1.4
const ATTACK_COOLDOWN := 1.2
const MAX_HEALTH := 3

var speed := BASE_SPEED
var health := MAX_HEALTH
var attack_timer := 0.0
var walk_time := 0.0
var dead := false
var target: PhysicsBody3D = null

@onready var sprite: Sprite3D = $Sprite
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if dead:
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	if not is_on_floor():
		velocity += get_gravity() * delta

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
				t.take_damage(1, to_target.normalized(), self)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

	# Two-frame shamble while moving; rest on the base frame when still.
	if Vector2(velocity.x, velocity.z).length() > 0.3:
		walk_time += delta
		sprite.texture = FRAME_A if int(walk_time / WALK_FRAME_TIME) % 2 == 0 else FRAME_B
	else:
		sprite.texture = FRAME_A


func setup(depth: int) -> void:
	# Deeper floors: faster bones, and a bit tougher every third floor.
	speed = minf(BASE_SPEED + 0.1 * (depth - 1), MAX_SPEED)
	health += (depth - 1) / 3


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
	# The corpse stays: swap to the bone pile and stop being a threat.
	dead = true
	if by_player:
		RunState.record_kill()
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	sprite.texture = DEAD_TEXTURE
	velocity = Vector3.ZERO
	if randf() < POTION_DROP_CHANCE:
		# Roll the bottle off the corpse so the sprites never share a
		# depth (coplanar billboards z-fight).
		var roll := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU) * 0.45
		var potion := POTION_SCENE.instantiate()
		potion.position = global_position + Vector3(0, -0.9, 0) + roll
		get_parent().add_child.call_deferred(potion)
