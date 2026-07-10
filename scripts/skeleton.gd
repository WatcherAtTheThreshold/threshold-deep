extends CharacterBody3D

const SPEED := 2.0
const SIGHT_RANGE := 10.0
const ATTACK_RANGE := 1.4
const ATTACK_COOLDOWN := 1.2
const MAX_HEALTH := 3

var health := MAX_HEALTH
var attack_timer := 0.0
var dead := false

@onready var sprite: Sprite3D = $Sprite
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if dead:
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	if not is_on_floor():
		velocity += get_gravity() * delta

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if dist < SIGHT_RANGE and _can_see_player():
		if dist > ATTACK_RANGE:
			var dir := to_player.normalized()
			velocity.x = dir.x * SPEED
			velocity.z = dir.z * SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if attack_timer == 0.0:
				attack_timer = ATTACK_COOLDOWN
				player.take_damage(1, to_player.normalized())
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()


func _can_see_player() -> bool:
	# A wall between us means no aggro — no x-ray vision through the dungeon.
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
	dead = true
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.6)
	tween.tween_property(sprite, "position:y", sprite.position.y - 0.8, 0.6)
	tween.chain().tween_callback(queue_free)
