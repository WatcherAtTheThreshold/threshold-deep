extends CharacterBody3D

const FRAME_A := preload("res://assets/sprites/wizard1.png")
const FRAME_B := preload("res://assets/sprites/wizard2.png")
const DEAD_TEXTURE := preload("res://assets/sprites/wizard_dead.png")
const ORB_SCENE := preload("res://scenes/orb.tscn")
const POTION_SCENE := preload("res://scenes/potion.tscn")
const POTION_DROP_CHANCE := 0.25
const WALK_FRAME_TIME := 0.3

const SPEED := 1.6
const RETREAT_RANGE := 4.0
const CAST_RANGE := 11.0
const SIGHT_RANGE := 12.0
const BASE_CAST_COOLDOWN := 2.2
const CHARGE_TIME := 0.45
const MAX_HEALTH := 2
const CHARGE_TINT := Color(1.6, 1.3, 2.0)

var health := MAX_HEALTH
var cast_cooldown := BASE_CAST_COOLDOWN
var cast_timer := 1.0
var charge_timer := 0.0
var charging := false
var walk_time := 0.0
var dead := false

@onready var sprite: Sprite3D = $Sprite
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var sees_player := dist < SIGHT_RANGE and _can_see_player()

	if charging:
		# Rooted while the cast winds up — the telegraph is the tell.
		velocity.x = 0.0
		velocity.z = 0.0
		charge_timer -= delta
		if charge_timer <= 0.0:
			charging = false
			sprite.modulate = Color.WHITE
			if sees_player:
				_fire_orb()
			cast_timer = cast_cooldown
	elif sees_player:
		# Keep respectful distance: back away if the player closes in.
		if dist < RETREAT_RANGE:
			var away := -to_player.normalized()
			velocity.x = away.x * SPEED
			velocity.z = away.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
			velocity.z = move_toward(velocity.z, 0.0, SPEED)
		cast_timer -= delta
		if cast_timer <= 0.0 and dist <= CAST_RANGE:
			charging = true
			charge_timer = CHARGE_TIME
			sprite.modulate = CHARGE_TINT
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()

	if Vector2(velocity.x, velocity.z).length() > 0.3:
		walk_time += delta
		sprite.texture = FRAME_A if int(walk_time / WALK_FRAME_TIME) % 2 == 0 else FRAME_B
	else:
		sprite.texture = FRAME_A


func setup(depth: int) -> void:
	# Deeper wizards cast a little more often.
	cast_cooldown = maxf(BASE_CAST_COOLDOWN - 0.08 * (depth - 1), 1.4)


func _fire_orb() -> void:
	var from := global_position + Vector3.UP * 0.3
	var orb := ORB_SCENE.instantiate()
	orb.direction = (player.global_position - from).normalized()
	orb.position = from + orb.direction * 0.8
	get_parent().add_child.call_deferred(orb)


func _can_see_player() -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.5,
		player.global_position + Vector3.UP * 0.3,
		1, [get_rid(), player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func take_damage(amount: int, push_dir: Vector3) -> void:
	if dead:
		return
	health -= amount
	velocity += push_dir * 6.0
	sprite.modulate = Color(1.0, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)
	if health <= 0:
		_die()


func _die() -> void:
	# The corpse stays: crumpled robes where the wizard fell.
	dead = true
	RunState.record_kill()
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	sprite.texture = DEAD_TEXTURE
	sprite.modulate = Color.WHITE
	velocity = Vector3.ZERO
	if randf() < POTION_DROP_CHANCE:
		var potion := POTION_SCENE.instantiate()
		potion.position = global_position + Vector3(0, -0.9, 0)
		get_parent().add_child.call_deferred(potion)
