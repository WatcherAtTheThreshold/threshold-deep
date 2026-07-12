extends CharacterBody3D

enum State { MEGA, MUSH, MINI }

const TEX_MEGA_1 := preload("res://assets/sprites/mush/mega-mush/mega-mush1.png")
const TEX_MEGA_2 := preload("res://assets/sprites/mush/mega-mush/mega-mush2.png")
const TEX_MUSH_1 := preload("res://assets/sprites/mush/mush/mush1.png")
const TEX_MUSH_2 := preload("res://assets/sprites/mush/mush/mush2.png")
const TEX_MINI_1 := preload("res://assets/sprites/mush/mini-mush/mini-mush1.png")
const TEX_MINI_2 := preload("res://assets/sprites/mush/mini-mush/mini-mush2.png")
const TEX_DEAD_MEGA := preload("res://assets/sprites/mush/mega-mush/mega_mush_dead.png")
const TEX_DEAD_MUSH := preload("res://assets/sprites/mush/mush/mush_dead.png")
const TEX_DEAD_MINI := preload("res://assets/sprites/mush/mini-mush/mini_mush_dead.png")
const WALK_FRAME_TIME := 0.28

const MUSH_MAX_HEALTH := 8
const MUSH_SPLIT_HEALTH := 4
const MEGA_MAX_HEALTH := 14
const MEGA_SPLIT_HEALTH := 7
const MERGE_RANGE := 1.2
const MERGE_COOLDOWN := 4.0
const SIGHT_RANGE := 9.0
const INFIGHT_SIGHT_RANGE := 20.0
const ATTACK_RANGE := 1.3
const ATTACK_COOLDOWN := 1.2

var state := State.MUSH
var health := MUSH_MAX_HEALTH
var speed := 1.6
var damage := 1
var body_radius := 0.5
var speed_scale := 1.0
var merge_cooldown := 0.0
var attack_timer := 0.0
var walk_time := 0.0
var dead := false
var target: PhysicsBody3D = null
var frame_a: Texture2D = TEX_MUSH_1
var frame_b: Texture2D = TEX_MUSH_2

@onready var sprite: Sprite3D = $Sprite
@onready var step_sound: AudioStreamPlayer3D = $StepSound
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	# Unique shape per instance — the radius changes with state.
	$CollisionShape3D.shape = SphereShape3D.new()
	_apply_state()


func configure(new_state: State, hp: int, cooldown := 0.0) -> void:
	# Called before add_child by a splitting parent.
	state = new_state
	health = hp
	merge_cooldown = cooldown


func setup(depth: int) -> void:
	speed_scale = 1.0 + minf(0.04 * (depth - 1), 0.4)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	attack_timer = maxf(attack_timer - delta, 0.0)
	merge_cooldown = maxf(merge_cooldown - delta, 0.0)

	if state == State.MUSH and merge_cooldown == 0.0:
		_try_merge()

	var t := _get_target()
	var to_target := t.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	var sight := SIGHT_RANGE if t == player else INFIGHT_SIGHT_RANGE

	if dist < sight and _can_see(t):
		if dist > ATTACK_RANGE:
			var dir := to_target.normalized()
			velocity.x = dir.x * speed * speed_scale
			velocity.z = dir.z * speed * speed_scale
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if attack_timer == 0.0:
				attack_timer = ATTACK_COOLDOWN
				t.take_damage(damage, to_target.normalized(), self)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if moving:
		walk_time += delta
		sprite.texture = frame_a if int(walk_time / WALK_FRAME_TIME) % 2 == 0 else frame_b
	else:
		sprite.texture = frame_a
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


func _try_merge() -> void:
	# Two full mushes that meet become a mega. One initiator (lowest
	# instance id) performs it; split-born mushes wait out a cooldown
	# so a burst mega can't instantly reassemble.
	for other in get_tree().get_nodes_in_group("mushes"):
		if other == self or not is_instance_valid(other):
			continue
		if other.dead or other.state != State.MUSH or other.merge_cooldown > 0.0:
			continue
		if get_instance_id() > other.get_instance_id():
			continue
		var between: Vector3 = other.global_position - global_position
		between.y = 0.0
		if between.length() < MERGE_RANGE:
			health = clampi(health + other.health, 1, MEGA_MAX_HEALTH)
			other.queue_free()
			position += between * 0.5
			state = State.MEGA
			_apply_state()
			return


func _split(child_state: State) -> void:
	var h2 := health / 2
	var h1 := health - h2
	if h2 < 1:
		return
	_drop_splat()
	var side := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
	var other: CharacterBody3D = (load("res://scenes/mush.tscn") as PackedScene).instantiate()
	other.configure(child_state, h2, MERGE_COOLDOWN)
	other.position = global_position + side * 0.8
	other.velocity = side * 3.5
	get_parent().add_child.call_deferred(other)
	state = child_state
	health = h1
	merge_cooldown = MERGE_COOLDOWN
	velocity += -side * 3.5
	_apply_state()


func _drop_splat() -> void:
	# Every burst leaves the residue of the body that burst. Random
	# spin for variety; slight height jitter so overlapping splats
	# layer instead of z-fighting.
	var splat := Sprite3D.new()
	splat.texture = TEX_DEAD_MEGA if state == State.MEGA else TEX_DEAD_MUSH
	splat.pixel_size = 0.03125
	splat.shaded = true
	splat.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	splat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	splat.rotation_degrees = Vector3(-90, randf() * 360.0, 0)
	splat.position = Vector3(
		global_position.x,
		global_position.y - body_radius + 0.03 + randf() * 0.02,
		global_position.z)
	get_parent().add_child.call_deferred(splat)


func _apply_state() -> void:
	# Body center rests at floor + radius; offsets stand each canvas's
	# bottom edge on the floor surface.
	match state:
		State.MEGA:
			frame_a = TEX_MEGA_1
			frame_b = TEX_MEGA_2
			body_radius = 0.7
			sprite.position = Vector3(0, 0.3, 0)
			step_sound.pitch_scale = 0.85
			speed = 1.2
			damage = 2
		State.MUSH:
			frame_a = TEX_MUSH_1
			frame_b = TEX_MUSH_2
			body_radius = 0.5
			sprite.position = Vector3(0, 0.5, 0)
			step_sound.pitch_scale = 1.05
			speed = 1.6
			damage = 1
		State.MINI:
			frame_a = TEX_MINI_1
			frame_b = TEX_MINI_2
			body_radius = 0.35
			sprite.position = Vector3(0, 0.15, 0)
			step_sound.pitch_scale = 1.3
			speed = 2.8
			damage = 1
	$CollisionShape3D.shape.radius = body_radius
	sprite.texture = frame_a


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
	elif state == State.MEGA and health <= MEGA_SPLIT_HEALTH:
		_split(State.MUSH)
	elif state == State.MUSH and health <= MUSH_SPLIT_HEALTH:
		_split(State.MINI)


func _die(by_player: bool) -> void:
	# The squashed cap stays where it fell, flat like the slime splat.
	dead = true
	step_sound.stop()
	if by_player:
		RunState.record_kill()
	remove_from_group("enemies")
	remove_from_group("mushes")
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	sprite.modulate = Color.WHITE
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.rotation_degrees = Vector3(-90, 0, 0)
	# Body center rests at floor + radius; park the splat just above
	# the floor surface.
	sprite.position = Vector3(0, 0.03 - body_radius, 0)
	match state:
		State.MEGA:
			sprite.texture = TEX_DEAD_MEGA
		State.MUSH:
			sprite.texture = TEX_DEAD_MUSH
		State.MINI:
			sprite.texture = TEX_DEAD_MINI
