extends CharacterBody3D

enum State { PUDDLE, BOSS, LARGE, SMALL }

const TEX_BOSS_1 := preload("res://assets/sprites/slime/slime-boss/slime-boss-front1.png")
const TEX_BOSS_2 := preload("res://assets/sprites/slime/slime-boss/slime-boss-front2.png")
const TEX_LARGE_1 := preload("res://assets/sprites/slime/slime-large/slime-large-down1.png")
const TEX_LARGE_2 := preload("res://assets/sprites/slime/slime-large/slime-large-down2.png")
const TEX_SMALL_1 := preload("res://assets/sprites/slime/slime-small/slimes-small-down1.png")
const TEX_SMALL_2 := preload("res://assets/sprites/slime/slime-small/slimes-small-down2.png")
const TAKE_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/slime_taking_hits1.wav"),
	preload("res://assets/audio/sfx/enemies/slime_taking_hits2.wav"),
	preload("res://assets/audio/sfx/enemies/slime_taking_hits3.wav"),
]
const TEX_SPAWN := preload("res://assets/sprites/slime/slime-spawn.png")
const TEX_MID_SPAWN := preload("res://assets/sprites/slime/slime-mid-spawn.png")
const TEX_DEAD := preload("res://assets/sprites/slime/slime_dead.png")
const MID_SPAWN_TIME := 0.45
const WALK_FRAME_TIME := 0.25

const SPAWN_TIME_MIN := 1.0
const SPAWN_TIME_MAX := 10.0
const RESPAWN_CHANCE := 0.15
const RESPAWN_DELAY_MIN := 8.0
const RESPAWN_DELAY_MAX := 20.0
const RESPAWN_TELL_TIME := 3.0
const LARGE_MAX_HEALTH := 12
const SPLIT_HEALTH := 6
const BOSS_MAX_HEALTH := 24
const BOSS_SPLIT_HEALTH := 12
const BOSS_SPEED := 1.2
const LARGE_SPEED := 1.4
const SMALL_SPEED := 2.6
const SIGHT_RANGE := 9.0
const INFIGHT_SIGHT_RANGE := 20.0
const ATTACK_RANGE := 1.2
const ATTACK_COOLDOWN := 1.2
const MERGE_RANGE := 1.0
const PLAYER_PRIORITY_RANGE := 5.0
const KNOCK_TIME := 0.35
const KNOCK_FRICTION := 30.0

var state := State.PUDDLE
var health := LARGE_MAX_HEALTH
var speed_scale := 1.0
var spawn_timer := 2.0
var respawn_timer := -1.0
var emerge_state := State.LARGE
var damage := 1
var attack_timer := 0.0
var walk_time := 0.0
var dead := false
var target: PhysicsBody3D = null
var partner: CharacterBody3D = null  # fellow small to re-merge with
var knock_timer := 0.0

@onready var sprite: Sprite3D = $Sprite
@onready var step_sound: AudioStreamPlayer3D = $StepSound
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	if state == State.PUDDLE:
		# Random incubation: this puddle might erupt long after you
		# walked past it.
		spawn_timer = randf_range(SPAWN_TIME_MIN, SPAWN_TIME_MAX)
		_show_flat(TEX_SPAWN)
	else:
		# Split-spawned smalls skip the puddle and are live immediately.
		add_to_group("enemies")
		_apply_state()


func make_child(child_state: State, hp: int, buddy: CharacterBody3D) -> void:
	# Called before add_child by the splitting parent.
	state = child_state
	health = hp
	partner = buddy


func setup(depth: int) -> void:
	speed_scale = 1.0 + minf(0.04 * (depth - 1), 0.4)


func kill_label() -> String:
	match state:
		State.BOSS:
			return "the Slime Boss"
		State.LARGE:
			return "Slime"
		_:
			return "Small Slime"


func _physics_process(delta: float) -> void:
	if dead:
		# Semi-rarely, a death puddle stirs again. The splat swaps to
		# spawn-puddle art a few seconds before rising — the tell.
		if respawn_timer > 0.0:
			respawn_timer -= delta
			if respawn_timer <= RESPAWN_TELL_TIME and sprite.texture != TEX_SPAWN:
				sprite.texture = TEX_SPAWN
			if respawn_timer <= 0.0:
				_respawn()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	attack_timer = maxf(attack_timer - delta, 0.0)

	if state == State.PUDDLE:
		spawn_timer -= delta
		# Half-risen blob for the final moment before emerging.
		if spawn_timer <= MID_SPAWN_TIME and sprite.texture != TEX_MID_SPAWN:
			_show_mid_spawn()
		if spawn_timer <= 0.0:
			_emerge()
		move_and_slide()
		return

	if knock_timer > 0.0:
		# Staggered: the shove owns the body for a beat. Skid under
		# friction — steering would erase the knockback next tick.
		knock_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, KNOCK_FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, KNOCK_FRICTION * delta)
		move_and_slide()
		return

	var tier_speed := SMALL_SPEED
	if state == State.BOSS:
		tier_speed = BOSS_SPEED
	elif state == State.LARGE:
		tier_speed = LARGE_SPEED
	var speed := tier_speed * speed_scale
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
				goal.take_damage(damage, to_goal.normalized(), self)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	var first := int(walk_time / WALK_FRAME_TIME) % 2 == 0 if moving else true
	if moving:
		walk_time += delta
	if state == State.BOSS:
		sprite.texture = TEX_BOSS_1 if first else TEX_BOSS_2
	elif state == State.LARGE:
		sprite.texture = TEX_LARGE_1 if first else TEX_LARGE_2
	else:
		sprite.texture = TEX_SMALL_1 if first else TEX_SMALL_2
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


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
		# A split-born twin enters the tree deferred: for the rest of
		# that frame it exists but has no global transform. Not gone —
		# just not chaseable yet, so don't null it.
		return partner.is_inside_tree()
	partner = null
	return false


func _emerge() -> void:
	state = emerge_state
	add_to_group("enemies")
	_apply_state()


func _respawn() -> void:
	# Back from the puddle — smaller, weaker, still hungry.
	dead = false
	emerge_state = State.SMALL
	health = 4
	state = State.PUDDLE
	spawn_timer = randf_range(1.0, 4.0)
	$CollisionShape3D.set_deferred("disabled", false)
	_show_flat(TEX_SPAWN)


func _merge() -> void:
	health = clampi(health + partner.health, 1, LARGE_MAX_HEALTH)
	partner.queue_free()
	partner = null
	state = State.LARGE
	_apply_state()


func _split(child_state: State) -> void:
	# Splits never fizzle: children get at least 1 HP each, so the
	# full cascade (boss → larges → smalls) always runs its course.
	@warning_ignore("integer_division")
	var h2 := maxi(health / 2, 1)
	var h1 := maxi(health - h2, 1)
	_drop_splat()
	var side := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
	var other: CharacterBody3D = (load("res://scenes/slime.tscn") as PackedScene).instantiate()
	other.make_child(child_state, h2, self)
	other.position = global_position + side * 0.7
	other.velocity = side * 3.0
	get_parent().add_child.call_deferred(other)
	partner = other
	state = child_state
	health = h1
	velocity += -side * 3.0
	_apply_state()


func _drop_splat() -> void:
	# The burst leaves residue where it happened, same as the mushes.
	# Random spin for variety; slight height jitter so overlapping
	# splats layer instead of z-fighting.
	var splat := Sprite3D.new()
	splat.texture = TEX_DEAD
	splat.pixel_size = 0.03125
	splat.shaded = true
	splat.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	splat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	splat.rotation_degrees = Vector3(-90, randf() * 360.0, 0)
	splat.position = Vector3(
		global_position.x,
		global_position.y - 0.5 + 0.03 + randf() * 0.02,
		global_position.z)
	get_parent().add_child.call_deferred(splat)


func _apply_state() -> void:
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.rotation = Vector3.ZERO
	# Body center rests at floor + 0.5 (sphere radius), so the canvas
	# bottom edge lands exactly on the floor surface at these offsets.
	# Smalls squish at a higher pitch than the big one.
	if state == State.BOSS:
		sprite.texture = TEX_BOSS_1
		sprite.position = Vector3(0, 0.5, 0)
		step_sound.pitch_scale = 0.7
		damage = 4
	elif state == State.LARGE:
		sprite.texture = TEX_LARGE_1
		sprite.position = Vector3(0, 0.5, 0)
		step_sound.pitch_scale = 0.85
		damage = 2
	else:
		sprite.texture = TEX_SMALL_1
		sprite.position = Vector3.ZERO
		step_sound.pitch_scale = 1.2
		damage = 2


func _show_mid_spawn() -> void:
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.rotation = Vector3.ZERO
	sprite.position = Vector3(0, 0.5, 0)
	sprite.texture = TEX_MID_SPAWN


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
	Sfx.play_at(TAKE_HIT_SOUNDS[randi_range(0, TAKE_HIT_SOUNDS.size() - 1)],
			global_position, -4.0)
	velocity += push_dir * 6.0
	knock_timer = KNOCK_TIME
	if attacker != null and attacker != self:
		# Pain redirects attention to whoever caused it.
		target = attacker
	sprite.modulate = Color(1.0, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)
	# Tiers above the bottom never die — lethal damage bursts them
	# instead, so the cascade always completes down to the smalls.
	if state == State.BOSS and health <= BOSS_SPLIT_HEALTH:
		_split(State.LARGE)
	elif state == State.LARGE and health <= SPLIT_HEALTH:
		_split(State.SMALL)
	elif health <= 0:
		_die(attacker == null or attacker is Player)


func _die(by_player: bool) -> void:
	# The splat stays where the slime burst.
	dead = true
	step_sound.stop()
	if by_player:
		RunState.record_kill(kill_label())
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	sprite.modulate = Color.WHITE
	_show_flat(TEX_DEAD)
	if randf() < RESPAWN_CHANCE:
		respawn_timer = randf_range(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)
