extends CharacterBody3D

enum State { PUDDLE, BOSS, LARGE, SMALL }

# Boss is front-only (no turnaround) — its two frames drive the walk
# shamble directly.
const TEX_BOSS_1 := preload("res://assets/sprites/slime/slime-boss/slime-boss-front1.png")
const TEX_BOSS_2 := preload("res://assets/sprites/slime/slime-boss/slime-boss-front2.png")

# Turnarounds for large + small: front1/2, side1/2 (drawn facing left;
# code flips for right), back1/2. _update_view picks the view.
const LARGE_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/slime/slime-large/slime_large_front1.png"),
	preload("res://assets/sprites/slime/slime-large/slime_large_front2.png"),
]
const LARGE_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/slime/slime-large/slime_large_side1.png"),
	preload("res://assets/sprites/slime/slime-large/slime_large_side2.png"),
]
const LARGE_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/slime/slime-large/slime_large_back1.png"),
	preload("res://assets/sprites/slime/slime-large/slime_large_back2.png"),
]
const SMALL_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/slime/slime-small/slime_small_front1.png"),
	preload("res://assets/sprites/slime/slime-small/slime_small_front2.png"),
]
const SMALL_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/slime/slime-small/slime_small_side1.png"),
	preload("res://assets/sprites/slime/slime-small/slime_small_side2.png"),
]
const SMALL_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/slime/slime-small/slime_small_back1.png"),
	preload("res://assets/sprites/slime/slime-small/slime_small_back2.png"),
]
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
const SIGHT_RANGE := 13.0  # forward vision reach, cone-gated
const INFIGHT_SIGHT_RANGE := 20.0
const HEAR_RANGE := 3.5  # sensed this close regardless of facing
const SIGHT_CONE_DEG := 110.0  # forward vision arc, full width
const ATTACK_RANGE := 1.2
const ATTACK_COOLDOWN := 1.2
const MERGE_RANGE := 1.0
const PLAYER_PRIORITY_RANGE := 5.0
const KNOCK_TIME := 0.35
const KNOCK_FRICTION := 30.0
const FALL_Y := -1.5

# Idle ooze: with no one to chase and no twin to rejoin, the blob
# slides a little way, then sits. Slow, aimless, frequent long rests.
const WANDER_SPEED := 0.7
const WANDER_LEG_MIN := 1.0
const WANDER_LEG_MAX := 2.5
const WANDER_PAUSE_MIN := 1.5
const WANDER_PAUSE_MAX := 5.5

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
var front_frames: Array[Texture2D] = LARGE_FRONT
var side_frames: Array[Texture2D] = LARGE_SIDE
var back_frames: Array[Texture2D] = LARGE_BACK  # empty for the boss (front-only)
var facing := Vector3.FORWARD
var wander_dir := Vector3.ZERO
var wander_timer := 0.0
var wander_wait := randf_range(0.0, WANDER_PAUSE_MAX)  # desynced from birth
var knock_timer := 0.0
var last_attacker: PhysicsBody3D = null

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
	if global_position.y < FALL_Y:
		_fall_into_dark()
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
	elif _perceives(goal, dist, sight):
		if goal == partner or dist > ATTACK_RANGE:
			var dir := to_goal.normalized()
			facing = dir
			if _floor_ahead(dir):
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
			else:
				# Pulled up at the rim: goo respects gravity.
				velocity.x = 0.0
				velocity.z = 0.0
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			facing = to_goal.normalized()
			if attack_timer == 0.0:
				attack_timer = ATTACK_COOLDOWN
				goal.take_damage(damage, to_goal.normalized(), self)
	else:
		_wander(delta, speed)

	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	# Two-frame squish while moving; rest on the first frame when
	# still. Which view shows depends on camera versus heading.
	_update_view(int(walk_time / WALK_FRAME_TIME) % 2 if moving else 0)
	if moving:
		walk_time += delta
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


func _wander(delta: float, decel: float) -> void:
	# No target, no twin to rejoin: the blob oozes at random. Short
	# slides, long rests. A wall or a rim ends a slide early; the
	# sight/merge checks upstream override the moment anything appears.
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
		velocity.x = move_toward(velocity.x, 0.0, decel)
		velocity.z = move_toward(velocity.z, 0.0, decel)
		wander_wait -= delta
		if wander_wait <= 0.0:
			wander_dir = Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
			wander_timer = randf_range(WANDER_LEG_MIN, WANDER_LEG_MAX)


func _floor_ahead(dir: Vector3) -> bool:
	# Probe for ground half a step ahead. Steering respects the rim;
	# only momentum (the knock skid) carries a body over it.
	var probe := global_position + dir * 0.7
	var query := PhysicsRayQueryParameters3D.create(
		probe, probe + Vector3.DOWN * 3.0, 1, [get_rid()])
	query.hit_from_inside = true
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _fall_into_dark() -> void:
	# The under-place keeps what it catches: credited if the player's
	# shove sent it over, but the body, its splits, and its drops are
	# gone — a whole boss can vanish mid-cascade.
	if last_attacker is Player:
		RunState.record_kill(kill_label())
	queue_free()


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
		# Front-only: empty side/back frames flag the boss in
		# _update_view, so its two frames drive the shamble directly.
		front_frames = [TEX_BOSS_1, TEX_BOSS_2]
		side_frames = []
		back_frames = []
		# Boss canvas is 96px (3m): half-height 1.5 minus the 0.5
		# body radius stands its bottom edge on the floor.
		sprite.position = Vector3(0, 1.0, 0)
		step_sound.pitch_scale = 0.7
		damage = 4
	elif state == State.LARGE:
		front_frames = LARGE_FRONT
		side_frames = LARGE_SIDE
		back_frames = LARGE_BACK
		sprite.position = Vector3(0, 0.5, 0)
		step_sound.pitch_scale = 0.85
		damage = 2
	else:
		front_frames = SMALL_FRONT
		side_frames = SMALL_SIDE
		back_frames = SMALL_BACK
		sprite.position = Vector3.ZERO
		step_sound.pitch_scale = 1.2
		damage = 2
	sprite.texture = front_frames[0]


func _update_view(frame: int) -> void:
	# Four-way billboard, Doom style: project the heading onto the
	# camera's axes — the dominant component picks the view. Side art
	# faces left, so it flips when heading toward screen-right. The boss
	# has no turnaround (empty side/back) and stays front-facing.
	if back_frames.is_empty():
		sprite.flip_h = false
		sprite.texture = front_frames[frame]
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var depth_dot := facing.dot(-cam.global_transform.basis.z)
	var side_dot := facing.dot(cam.global_transform.basis.x)
	if absf(depth_dot) >= absf(side_dot):
		sprite.flip_h = false
		sprite.texture = (back_frames if depth_dot > 0.0 else front_frames)[frame]
	else:
		sprite.flip_h = side_dot > 0.0
		sprite.texture = side_frames[frame]


func _show_mid_spawn() -> void:
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.rotation = Vector3.ZERO
	sprite.flip_h = false  # clear any leftover side-view mirroring
	sprite.position = Vector3(0, 0.5, 0)
	sprite.texture = TEX_MID_SPAWN


func _show_flat(tex: Texture2D) -> void:
	# Puddles and corpses lie on the floor like the hatch does.
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.rotation_degrees = Vector3(-90, 0, 0)
	sprite.flip_h = false  # clear any leftover side-view mirroring
	sprite.position = Vector3(0, -0.47, 0)
	sprite.texture = tex


func _get_target() -> PhysicsBody3D:
	# A grudge holds only while its object stands; otherwise, the player.
	if target != null and is_instance_valid(target) and not target.get("dead"):
		return target
	target = null
	return player


func _perceives(who: PhysicsBody3D, dist: float, reach: float) -> bool:
	# A twin to rejoin or a grudge is pursued on range + line of sight
	# alone. The player, unprovoked, must be HEARD (close, any direction) or
	# SEEN (inside the forward cone, at range, clear line): no more sensing
	# you through the back of the blob.
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
		last_attacker = attacker
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
