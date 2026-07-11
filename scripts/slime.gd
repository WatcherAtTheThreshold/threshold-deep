extends CharacterBody3D

enum State { PUDDLE, LARGE, SMALL }

const TEX_LARGE_1 := preload("res://assets/sprites/slime/slime-large/slime-large-down1.png")
const TEX_LARGE_2 := preload("res://assets/sprites/slime/slime-large/slime-large-down2.png")
const TEX_SMALL_1 := preload("res://assets/sprites/slime/slime-small/slimes-small-down1.png")
const TEX_SMALL_2 := preload("res://assets/sprites/slime/slime-small/slimes-small-down2.png")
const TEX_SPAWN := preload("res://assets/sprites/slime/slime-spawn.png")
const TEX_DEAD := preload("res://assets/sprites/slime/slime_dead.png")
const WALK_FRAME_TIME := 0.25

const SPAWN_TIME := 1.3
const LARGE_MAX_HEALTH := 6
const SPLIT_HEALTH := 3
const LARGE_SPEED := 1.4
const SMALL_SPEED := 2.6
const SIGHT_RANGE := 9.0
const INFIGHT_SIGHT_RANGE := 20.0
const ATTACK_RANGE := 1.2
const ATTACK_COOLDOWN := 1.2
const MERGE_RANGE := 1.0
const PLAYER_PRIORITY_RANGE := 5.0

var state := State.PUDDLE
var health := LARGE_MAX_HEALTH
var speed_scale := 1.0
var spawn_timer := SPAWN_TIME
var attack_timer := 0.0
var walk_time := 0.0
var dead := false
var target: PhysicsBody3D = null
var partner: CharacterBody3D = null  # fellow small to re-merge with

@onready var sprite: Sprite3D = $Sprite
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	if state == State.PUDDLE:
		_show_flat(TEX_SPAWN)
	else:
		# Split-spawned smalls skip the puddle and are live immediately.
		add_to_group("enemies")
		_apply_state()


func make_small(hp: int, buddy: CharacterBody3D) -> void:
	# Called before add_child by the splitting parent.
	state = State.SMALL
	health = hp
	partner = buddy


func setup(depth: int) -> void:
	speed_scale = 1.0 + minf(0.04 * (depth - 1), 0.4)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	attack_timer = maxf(attack_timer - delta, 0.0)

	if state == State.PUDDLE:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_emerge()
		move_and_slide()
		return

	var speed := (LARGE_SPEED if state == State.LARGE else SMALL_SPEED) * speed_scale
	var goal := _pick_goal()
	var to_goal := goal.global_position - global_position
	to_goal.y = 0.0
	var dist := to_goal.length()
	var sight := SIGHT_RANGE if _get_target() == player else INFIGHT_SIGHT_RANGE

	if goal == partner and dist < MERGE_RANGE:
		# Initiator rule so only one of the pair performs the merge.
		if get_instance_id() < partner.get_instance_id():
			_merge()
	elif dist < sight and _can_see(goal):
		if goal == partner or dist > ATTACK_RANGE:
			var dir := to_goal.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if attack_timer == 0.0:
				attack_timer = ATTACK_COOLDOWN
				goal.take_damage(1, to_goal.normalized(), self)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

	if Vector2(velocity.x, velocity.z).length() > 0.3:
		walk_time += delta
		var first := int(walk_time / WALK_FRAME_TIME) % 2 == 0
		if state == State.LARGE:
			sprite.texture = TEX_LARGE_1 if first else TEX_LARGE_2
		else:
			sprite.texture = TEX_SMALL_1 if first else TEX_SMALL_2
	elif state == State.LARGE:
		sprite.texture = TEX_LARGE_1
	else:
		sprite.texture = TEX_SMALL_1


func _pick_goal() -> PhysicsBody3D:
	# Grudges (being hit) always take priority. Otherwise a small
	# slime would rather find its twin and re-merge — unless the
	# player is close enough to be worth fighting.
	var t := _get_target()
	if state == State.SMALL and t == player and _partner_alive():
		var player_dist := (player.global_position - global_position).length()
		if player_dist > PLAYER_PRIORITY_RANGE or not _can_see(player):
			return partner
	return t


func _partner_alive() -> bool:
	if partner != null and is_instance_valid(partner) and not partner.dead:
		return true
	partner = null
	return false


func _emerge() -> void:
	state = State.LARGE
	add_to_group("enemies")
	_apply_state()


func _merge() -> void:
	health = clampi(health + partner.health, 1, LARGE_MAX_HEALTH)
	partner.queue_free()
	partner = null
	state = State.LARGE
	_apply_state()


func _split(h1: int, h2: int) -> void:
	var side := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
	var other: CharacterBody3D = (load("res://scenes/slime.tscn") as PackedScene).instantiate()
	other.make_small(h2, self)
	other.position = global_position + side * 0.7
	other.velocity = side * 3.0
	get_parent().add_child.call_deferred(other)
	partner = other
	state = State.SMALL
	health = h1
	velocity += -side * 3.0
	_apply_state()


func _apply_state() -> void:
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.rotation = Vector3.ZERO
	if state == State.LARGE:
		sprite.texture = TEX_LARGE_1
		sprite.position = Vector3.ZERO
	else:
		sprite.texture = TEX_SMALL_1
		sprite.position = Vector3(0, -0.5, 0)


func _show_flat(tex: Texture2D) -> void:
	# Puddles and corpses lie on the floor like the hatch does.
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.rotation_degrees = Vector3(-90, 0, 0)
	sprite.position = Vector3(0, -0.47, 0)
	sprite.texture = tex


func _get_target() -> PhysicsBody3D:
	# A grudge holds only while its object stands; otherwise, the player.
	if target != null and is_instance_valid(target) and not target.get("dead"):
		return target
	target = null
	return player


func _can_see(t: PhysicsBody3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.3,
		t.global_position + Vector3.UP * 0.3,
		1, [get_rid(), t.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func take_damage(amount: int, push_dir: Vector3, attacker: PhysicsBody3D = null) -> void:
	if dead or state == State.PUDDLE:
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
	elif state == State.LARGE and health <= SPLIT_HEALTH:
		var h2 := health / 2
		var h1 := health - h2
		if h2 >= 1:
			_split(h1, h2)


func _die(by_player: bool) -> void:
	# The splat stays where the slime burst.
	dead = true
	if by_player:
		RunState.record_kill()
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	sprite.modulate = Color.WHITE
	_show_flat(TEX_DEAD)
