extends CharacterBody3D

enum State { BOSS, MEGA, MUSH, MINI }

# Boss is front-only (billboard) — no turnaround. Its two frames drive
# the walk shamble directly.
const TEX_BOSS_1 := preload("res://assets/sprites/mush/boss-mush/boss-mush1.png")
const TEX_BOSS_2 := preload("res://assets/sprites/mush/boss-mush/boss-mush2.png")
const TEX_DEAD_BOSS := preload("res://assets/sprites/mush/boss-mush/boss_mush_dead.png")

# Turnarounds per non-boss tier: front1/2, side1/2 (drawn facing left;
# code flips for right), back1/2. _update_view picks the view.
const MEGA_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mega-mush/mega-mush_front1.png"),
	preload("res://assets/sprites/mush/mega-mush/mega-mush_front2.png"),
]
const MEGA_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mega-mush/mega-mush_side1.png"),
	preload("res://assets/sprites/mush/mega-mush/mega-mush_side2.png"),
]
const MEGA_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mega-mush/mega-mush_back1.png"),
	preload("res://assets/sprites/mush/mega-mush/mega-mush_back2.png"),
]
const MUSH_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mush/mush_front1.png"),
	preload("res://assets/sprites/mush/mush/mush_front2.png"),
]
const MUSH_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mush/mush_side1.png"),
	preload("res://assets/sprites/mush/mush/mush_side2.png"),
]
const MUSH_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mush/mush_back1.png"),
	preload("res://assets/sprites/mush/mush/mush_back2.png"),
]
const MINI_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mini-mush/mini-mush_front1.png"),
	preload("res://assets/sprites/mush/mini-mush/mini-mush_front2.png"),
]
const MINI_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mini-mush/mini-mush_side1.png"),
	preload("res://assets/sprites/mush/mini-mush/mini-mush_side2.png"),
]
const MINI_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mini-mush/mini-mush_back1.png"),
	preload("res://assets/sprites/mush/mini-mush/mini-mush_back2.png"),
]
const TEX_MINI_SURPRISE := preload("res://assets/sprites/mush/mini-mush/mini-mush-suprise.png")
const TAKE_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/mush_take_hit1.ogg"),
	preload("res://assets/audio/sfx/enemies/mush_take_hit2.ogg"),
	preload("res://assets/audio/sfx/enemies/mush_take_hit3.ogg"),
]
const DISCOVER_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/mini_mush_discover_slime_puddle1.ogg"),
	preload("res://assets/audio/sfx/enemies/mini_mush_discover_slime_puddle2.ogg"),
	preload("res://assets/audio/sfx/enemies/mini_mush_discover_slime_puddle3.ogg"),
]
const TEX_DEAD_MEGA := preload("res://assets/sprites/mush/mega-mush/mega_mush_dead.png")
const TEX_DEAD_MUSH := preload("res://assets/sprites/mush/mush/mush_dead.png")
const TEX_DEAD_MINI := preload("res://assets/sprites/mush/mini-mush/mini_mush_dead.png")
const MINI_ATTACK_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mini-mush/mini-mush_front_attack1.png"),
	preload("res://assets/sprites/mush/mini-mush/mini-mush_front_attack2.png"),
]
const MINI_ATTACK_SIDE: Array[Texture2D] = [  # drawn facing left; flipped for right
	preload("res://assets/sprites/mush/mini-mush/mini-mush_side_attack1.png"),
	preload("res://assets/sprites/mush/mini-mush/mini-mush_side_attack2.png"),
]
const MINI_ATTACK_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mini-mush/mini-mush_back_attack1.png"),
	preload("res://assets/sprites/mush/mini-mush/mini-mush_back_attack2.png"),
]
const MUSH_ATTACK_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mush/mush_front_attack1.png"),
	preload("res://assets/sprites/mush/mush/mush_front_attack2.png"),
]
const MUSH_ATTACK_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mush/mush_side_attack1.png"),
	preload("res://assets/sprites/mush/mush/mush_side_attack2.png"),
]
const MUSH_ATTACK_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mush/mush_back_attack1.png"),
	preload("res://assets/sprites/mush/mush/mush_back_attack2.png"),
]
const MEGA_ATTACK_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mega-mush/mega-mush_front_attack1.png"),
	preload("res://assets/sprites/mush/mega-mush/mega-mush_front_attack2.png"),
]
const MEGA_ATTACK_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mega-mush/mega-mush_side_attack1.png"),
	preload("res://assets/sprites/mush/mega-mush/mega-mush_side_attack2.png"),
]
const MEGA_ATTACK_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mega-mush/mega-mush_back_attack1.png"),
	preload("res://assets/sprites/mush/mega-mush/mega-mush_back_attack2.png"),
]
const BOSS_ATTACK: Array[Texture2D] = [  # front-only, like the boss walk
	preload("res://assets/sprites/mush/boss-mush/boss-mush_attack1.png"),
	preload("res://assets/sprites/mush/boss-mush/boss-mush_attack2.png"),
]
const WALK_FRAME_TIME := 0.28
const ATTACK_FRAME_TIME := 0.12  # per attack frame; two of them = one lunge
const AGGRO_TIME := 0.45  # startle freeze — a touch longer; the cap is ponderous
const AGGRO_TURN_SPEED := 10.0  # rad/s it wheels around; slower = a heavier turn
const AGGRO_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/mush_aggro1.ogg"),
	preload("res://assets/audio/sfx/enemies/mush_aggro2.ogg"),
	preload("res://assets/audio/sfx/enemies/mush_aggro3.ogg"),
]
const AGGRO_MINI := preload("res://assets/sprites/mush/mini-mush/mini-mush_front_aggro1.png")
const AGGRO_MUSH := preload("res://assets/sprites/mush/mush/mush_front_aggro1.png")
const AGGRO_MEGA := preload("res://assets/sprites/mush/mega-mush/mega-mush_front_aggro1.png")
const AGGRO_BOSS := preload("res://assets/sprites/mush/boss-mush/boss-mush_aggro1.png")
const DEATH_MINI := preload("res://assets/audio/sfx/enemies/mini_mush_death.ogg")
const DEATH_MUSH := preload("res://assets/audio/sfx/enemies/mush_death.ogg")
const DEATH_MEGA := preload("res://assets/audio/sfx/enemies/mega_mush_death.ogg")
const DEATH_BOSS := preload("res://assets/audio/sfx/enemies/boss_mush_death.ogg")
const MINI_TAKEHIT_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mini-mush/mini-mush_front_takehit1.png"),
	preload("res://assets/sprites/mush/mini-mush/mini-mush_front_takehit2.png"),
]
const MINI_TAKEHIT_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mini-mush/mini-mush_side_takehit1.png"),
	preload("res://assets/sprites/mush/mini-mush/mini-mush_side_takehit2.png"),
]
const MINI_TAKEHIT_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mini-mush/mini-mush_back_takehit1.png"),
	preload("res://assets/sprites/mush/mini-mush/mini-mush_back_takehit2.png"),
]
const MUSH_TAKEHIT_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mush/mush_front_takehit1.png"),
	preload("res://assets/sprites/mush/mush/mush_front_takehit2.png"),
]
const MUSH_TAKEHIT_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mush/mush_side_takehit1.png"),
	preload("res://assets/sprites/mush/mush/mush_side_takehit2.png"),
]
const MUSH_TAKEHIT_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mush/mush_back_takehit1.png"),
	preload("res://assets/sprites/mush/mush/mush_back_takehit2.png"),
]
const MEGA_TAKEHIT_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mega-mush/mega-mush_front_takehit1.png"),
	preload("res://assets/sprites/mush/mega-mush/mega-mush_front_takehit2.png"),
]
const MEGA_TAKEHIT_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mega-mush/mega-mush_side_takehit1.png"),
	preload("res://assets/sprites/mush/mega-mush/mega-mush_side_takehit2.png"),
]
const MEGA_TAKEHIT_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/mush/mega-mush/mega-mush_back_takehit1.png"),
	preload("res://assets/sprites/mush/mega-mush/mega-mush_back_takehit2.png"),
]
const BOSS_TAKEHIT: Array[Texture2D] = [  # front-only, like the boss walk
	preload("res://assets/sprites/mush/boss-mush/boss-mush_takehit1.png"),
	preload("res://assets/sprites/mush/boss-mush/boss-mush_takehit2.png"),
]

const MUSH_MAX_HEALTH := 16
const MUSH_SPLIT_HEALTH := 8
const MEGA_MAX_HEALTH := 28
const MEGA_SPLIT_HEALTH := 14
const BOSS_MAX_HEALTH := 40
const BOSS_SPLIT_HEALTH := 20
const MERGE_RANGE := 1.2
const MERGE_COOLDOWN := 4.0
const SIGHT_RANGE := 13.0  # forward vision reach, cone-gated
const INFIGHT_SIGHT_RANGE := 20.0
const HEAR_RANGE := 3.5  # sensed this close regardless of facing
const SIGHT_CONE_DEG := 110.0  # forward vision arc, full width
const ATTACK_RANGE := 1.3
const ATTACK_COOLDOWN := 1.2
const KNOCK_TIME := 0.35
const KNOCK_FRICTION := 30.0
const FALL_Y := -1.5

const HUNT_DEPTH := 10
const STARTLE_TIME := 0.4
const EAT_RANGE := 0.9
const GREEN_TINT := Color(0.55, 1.05, 0.55)

# Idle creep: fungus with nowhere to be drifts a few short steps, then
# settles for a long spell. Slower and stiller than the bones' shuffle.
const WANDER_SPEED := 0.7
const WANDER_LEG_MIN := 0.8
const WANDER_LEG_MAX := 2.0
const WANDER_PAUSE_MIN := 2.5
const WANDER_PAUSE_MAX := 6.5

var state := State.MUSH
var health := MUSH_MAX_HEALTH
var speed := 1.6
var damage := 1
var body_radius := 0.5
var speed_scale := 1.0
var depth := 1
var green := false
var base_tint := Color.WHITE
var hunger := false  # boss-fight cascades hunt corpses at any depth
var hunt_target: PhysicsBody3D = null
var startle_timer := 0.0
var merge_cooldown := 0.0
var attack_timer := 0.0
var walk_time := 0.0
var dead := false
var target: PhysicsBody3D = null
var front_frames: Array[Texture2D] = MUSH_FRONT
var side_frames: Array[Texture2D] = MUSH_SIDE
var back_frames: Array[Texture2D] = MUSH_BACK  # empty for the boss (front-only)
var attack_front: Array[Texture2D] = MUSH_ATTACK_FRONT
var attack_side: Array[Texture2D] = MUSH_ATTACK_SIDE
var attack_back: Array[Texture2D] = MUSH_ATTACK_BACK  # empty for the boss
var takehit_front: Array[Texture2D] = MUSH_TAKEHIT_FRONT
var takehit_side: Array[Texture2D] = MUSH_TAKEHIT_SIDE
var takehit_back: Array[Texture2D] = MUSH_TAKEHIT_BACK  # empty for the boss
var attack_anim := 0.0  # counts down while the lunge frames play
var noticed := false    # true while it currently perceives the player
var aggro_timer := 0.0  # counts down through the startle freeze
var aggro_tex: Texture2D = AGGRO_MUSH  # the alert pose, set per tier
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
	# Unique shape per instance — the radius changes with state.
	$CollisionShape3D.shape = SphereShape3D.new()
	_apply_state()


func configure(new_state: State, hp: int, cooldown := 0.0, is_green := false) -> void:
	# Called before add_child by a splitting parent.
	noticed = true  # born mid-fight, already aware — no startle on spawn
	state = new_state
	health = hp
	merge_cooldown = cooldown
	green = is_green
	if green:
		base_tint = GREEN_TINT


func setup(new_depth: int) -> void:
	depth = new_depth
	speed_scale = 1.0 + minf(0.04 * (depth - 1), 0.4)


func _hit_pitch() -> float:
	# The boss speaks at the original pitch; each generation down the
	# family tree squeaks a little higher.
	match state:
		State.BOSS:
			return 1.0
		State.MEGA:
			return 1.12
		State.MUSH:
			return 1.25
		_:
			return 1.45


func kill_label() -> String:
	match state:
		State.BOSS:
			return "the Mush Boss"
		State.MEGA:
			return "Green Mega Mush" if green else "Mega Mush"
		State.MINI:
			return "Mini-Mush"
		_:
			return "Green Mush" if green else "Mush"


func _physics_process(delta: float) -> void:
	if dead:
		return
	if global_position.y < FALL_Y:
		_fall_into_dark()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	attack_timer = maxf(attack_timer - delta, 0.0)
	aggro_timer = maxf(aggro_timer - delta, 0.0)
	merge_cooldown = maxf(merge_cooldown - delta, 0.0)

	if knock_timer > 0.0:
		# Staggered: the shove owns the body for a beat. Skid under
		# friction — steering would erase the knockback next tick.
		# No merging or hunting mid-flight either.
		knock_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, KNOCK_FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, KNOCK_FRICTION * delta)
		move_and_slide()
		# The stagger IS the hit reaction: the 2-stage take-hit plays across
		# the skid (the red flash from take_damage tints it).
		_hit_view(0 if knock_timer > KNOCK_TIME * 0.5 else 1)
		return

	if state == State.MUSH and merge_cooldown == 0.0:
		_try_merge()

	# Deep-floor hunger: a mini that spots a slime corpse goes for it.
	if hunt_target != null and not is_instance_valid(hunt_target):
		hunt_target = null
	if state == State.MINI and (hunger or depth >= HUNT_DEPTH) \
			and hunt_target == null:
		_acquire_slime_corpse()
	if startle_timer > 0.0:
		# The startle: it just had an idea. Freeze, little hop, then run.
		startle_timer -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		sprite.texture = TEX_MINI_SURPRISE
		move_and_slide()
		return

	var t := _get_target()
	var goal := _pick_goal(t)
	var to_goal := goal.global_position - global_position
	to_goal.y = 0.0
	var dist := to_goal.length()
	var sight := SIGHT_RANGE if goal == player else INFIGHT_SIGHT_RANGE

	var seen := _perceives(goal, dist, sight)
	if seen and goal == player and not noticed:
		noticed = true
		aggro_timer = AGGRO_TIME
		Sfx.play_at(AGGRO_SOUNDS[randi_range(0, AGGRO_SOUNDS.size() - 1)],
				global_position, -4.0)
	elif not seen:
		noticed = false
	if aggro_timer > 0.0:
		# The notice beat: the cap rears up and WHEELS to face you — caught
		# from behind it turns through a side view — then it creeps in. Alarm
		# pose lands once it's basically looking at you.
		var want := to_goal.normalized()
		var swing := facing.signed_angle_to(want, Vector3.UP)
		facing = facing.rotated(Vector3.UP,
				clampf(swing, -AGGRO_TURN_SPEED * delta, AGGRO_TURN_SPEED * delta))
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if facing.dot(want) > 0.85:
			sprite.flip_h = false
			sprite.texture = aggro_tex
		else:
			_update_view(0)
		if step_sound.playing:
			step_sound.stop()
		return
	if goal == hunt_target and dist < EAT_RANGE:
		_eat_slime()
	elif seen:
		if goal != t or dist > ATTACK_RANGE:
			# Walking toward a merge mate, or closing on a target.
			var dir := to_goal.normalized()
			facing = dir
			if _floor_ahead(dir):
				velocity.x = dir.x * speed * speed_scale
				velocity.z = dir.z * speed * speed_scale
			else:
				# Pulled up at the rim: not even kin is worth the dark.
				velocity.x = 0.0
				velocity.z = 0.0
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			facing = to_goal.normalized()
			if attack_timer == 0.0:
				attack_timer = ATTACK_COOLDOWN
				attack_anim = ATTACK_FRAME_TIME * 2.0
				t.take_damage(damage, to_goal.normalized(), self)
				if t == player:
					_puff_spores()
	else:
		_wander(delta)

	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if moving:
		walk_time += delta
	# Two-frame shamble while moving; rest on the first frame when
	# still. Which view shows depends on camera versus heading.
	if attack_anim > 0.0:
		# The lunge takes over the walk turnaround while it plays.
		attack_anim -= delta
		_attack_view(0 if attack_anim > ATTACK_FRAME_TIME else 1)
	else:
		_update_view(int(walk_time / WALK_FRAME_TIME) % 2 if moving else 0)
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


func _wander(delta: float) -> void:
	# No kin to fuse with, no prey in sight: the cap drifts. Short
	# creeps, long stillnesses. A wall or a rim ends a leg early; the
	# sight/merge checks upstream override this the instant anything
	# worth chasing appears.
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
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
		wander_wait -= delta
		if wander_wait <= 0.0:
			wander_dir = Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
			wander_timer = randf_range(WANDER_LEG_MIN, WANDER_LEG_MAX)


func _pick_goal(t: PhysicsBody3D) -> PhysicsBody3D:
	# Union over war: an unhurried mush would rather find its kin and
	# fuse than fight — and an unhurried mini would rather eat a slime
	# corpse than fight. Pain (a grudge target) overrides everything.
	if t == player:
		if state == State.MINI and hunt_target != null:
			return hunt_target
		if state == State.MUSH and merge_cooldown == 0.0:
			var mate := _find_merge_mate()
			if mate != null:
				return mate
	return t


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
	# shove sent it over, but the body and its drops are gone.
	if is_instance_valid(last_attacker) and last_attacker is Player:
		RunState.record_kill(kill_label())
	queue_free()


func _acquire_slime_corpse() -> void:
	for s: PhysicsBody3D in get_tree().get_nodes_in_group("slimes"):
		if not is_instance_valid(s) or s.get("dead") != true:
			continue
		var to_corpse := s.global_position - global_position
		to_corpse.y = 0.0
		if to_corpse.length() < SIGHT_RANGE and _can_see(s):
			hunt_target = s
			startle_timer = STARTLE_TIME
			velocity.y = 3.0  # the little hop
			# It just had an idea — audibly.
			Sfx.play_at(DISCOVER_SOUNDS[randi_range(0, DISCOVER_SOUNDS.size() - 1)],
					global_position, -3.0)
			break


func _eat_slime() -> void:
	if is_instance_valid(hunt_target):
		hunt_target.queue_free()
	hunt_target = null
	# Fed and transformed: a green mush, with everything that implies.
	green = true
	base_tint = GREEN_TINT
	state = State.MUSH
	health = MUSH_MAX_HEALTH
	merge_cooldown = 1.0
	_apply_state()


func _find_merge_mate() -> PhysicsBody3D:
	var best: PhysicsBody3D = null
	var best_dist := INF
	for other in get_tree().get_nodes_in_group("mushes"):
		if other == self or not is_instance_valid(other):
			continue
		if other.dead or other.state != State.MUSH or other.merge_cooldown > 0.0:
			continue
		var d: float = (other.global_position - global_position).length()
		if d < best_dist and d < INFIGHT_SIGHT_RANGE and _can_see(other):
			best_dist = d
			best = other
	return best


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
			if other.green:
				green = true
				base_tint = GREEN_TINT
			other.queue_free()
			position += between * 0.5
			state = State.MEGA
			_apply_state()
			return


func _split(child_state: State) -> void:
	# Splits never fizzle: children get at least 1 HP each, so the
	# full cascade (boss → megas → mushes → minis) always runs its
	# course.
	@warning_ignore("integer_division")
	var h2 := maxi(health / 2, 1)
	var h1 := maxi(health - h2, 1)
	_drop_splat()
	var side := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
	var other: CharacterBody3D = (load("res://scenes/mush.tscn") as PackedScene).instantiate()
	other.configure(child_state, h2, MERGE_COOLDOWN, green)
	other.hunger = hunger
	other.setup(depth)
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
	var splat_tex := TEX_DEAD_MUSH
	if state == State.BOSS:
		splat_tex = TEX_DEAD_BOSS
	elif state == State.MEGA:
		splat_tex = TEX_DEAD_MEGA
	splat.texture = splat_tex
	splat.modulate = base_tint
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
		State.BOSS:
			# Front-only: empty side/back frames flag the boss in
			# _update_view, so its two frames drive the shamble directly.
			front_frames = [TEX_BOSS_1, TEX_BOSS_2]
			side_frames = []
			back_frames = []
			attack_front = BOSS_ATTACK
			attack_side = []
			attack_back = []
			aggro_tex = AGGRO_BOSS
			takehit_front = BOSS_TAKEHIT
			takehit_side = []
			takehit_back = []
			body_radius = 0.8
			# Boss canvas is 96px (3m): half-height 1.5 minus the
			# 0.8 body radius stands its bottom edge on the floor.
			sprite.position = Vector3(0, 0.7, 0)
			step_sound.pitch_scale = 0.7
			speed = 1.1
			damage = 4
		State.MEGA:
			front_frames = MEGA_FRONT
			side_frames = MEGA_SIDE
			back_frames = MEGA_BACK
			attack_front = MEGA_ATTACK_FRONT
			attack_side = MEGA_ATTACK_SIDE
			attack_back = MEGA_ATTACK_BACK
			aggro_tex = AGGRO_MEGA
			takehit_front = MEGA_TAKEHIT_FRONT
			takehit_side = MEGA_TAKEHIT_SIDE
			takehit_back = MEGA_TAKEHIT_BACK
			body_radius = 0.7
			sprite.position = Vector3(0, 0.3, 0)
			step_sound.pitch_scale = 0.85
			speed = 1.2
			damage = 4
		State.MUSH:
			front_frames = MUSH_FRONT
			side_frames = MUSH_SIDE
			back_frames = MUSH_BACK
			attack_front = MUSH_ATTACK_FRONT
			attack_side = MUSH_ATTACK_SIDE
			attack_back = MUSH_ATTACK_BACK
			aggro_tex = AGGRO_MUSH
			takehit_front = MUSH_TAKEHIT_FRONT
			takehit_side = MUSH_TAKEHIT_SIDE
			takehit_back = MUSH_TAKEHIT_BACK
			body_radius = 0.5
			sprite.position = Vector3(0, 0.5, 0)
			step_sound.pitch_scale = 1.05
			speed = 1.6
			damage = 2
		State.MINI:
			front_frames = MINI_FRONT
			side_frames = MINI_SIDE
			back_frames = MINI_BACK
			attack_front = MINI_ATTACK_FRONT
			attack_side = MINI_ATTACK_SIDE
			attack_back = MINI_ATTACK_BACK
			aggro_tex = AGGRO_MINI
			takehit_front = MINI_TAKEHIT_FRONT
			takehit_side = MINI_TAKEHIT_SIDE
			takehit_back = MINI_TAKEHIT_BACK
			body_radius = 0.35
			sprite.position = Vector3(0, 0.15, 0)
			step_sound.pitch_scale = 1.3
			speed = 2.8
			damage = 2
	$CollisionShape3D.shape.radius = body_radius
	attack_anim = 0.0  # clear any mid-lunge when the tier changes
	sprite.texture = front_frames[0]
	sprite.modulate = base_tint


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


func _attack_view(frame: int) -> void:
	# Attack turnaround, same projection as _update_view. The boss is
	# front-only (empty side/back attack) and stays front-facing.
	if attack_back.is_empty():
		sprite.flip_h = false
		sprite.texture = attack_front[frame]
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var depth_dot := facing.dot(-cam.global_transform.basis.z)
	var side_dot := facing.dot(cam.global_transform.basis.x)
	if absf(depth_dot) >= absf(side_dot):
		sprite.flip_h = false
		sprite.texture = (attack_back if depth_dot > 0.0 else attack_front)[frame]
	else:
		sprite.flip_h = side_dot > 0.0
		sprite.texture = attack_side[frame]


func _puff_spores() -> void:
	# A gold spore cloud bursts where the cap strikes the player: a quick
	# poof outward, then a slow drift down as it fades. CPUParticles (safe
	# in the web renderer), one-shot, freed once the burst has run.
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 14
	p.lifetime = 1.4
	p.explosiveness = 0.9
	p.direction = Vector3(0.0, 1.0, 0.0)
	p.spread = 55.0
	p.initial_velocity_min = 0.7
	p.initial_velocity_max = 1.9
	p.gravity = Vector3(0.0, -1.3, 0.0)
	p.damping_min = 0.4
	p.damping_max = 1.2
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.1
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.35, 1.0))
	grad.set_color(1, Color(1.0, 0.8, 0.3, 0.0))
	p.color_ramp = grad
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1.0, 0.85, 0.4)
	quad.material = mat
	p.mesh = quad
	p.position = global_position + Vector3(0.0, body_radius + 0.3, 0.0)
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.4).timeout.connect(p.queue_free)
	get_parent().add_child.call_deferred(p)


func _hit_view(frame: int) -> void:
	# Take-hit turnaround, same projection as _update_view. The boss is
	# front-only (empty side/back take-hit) and stays front-facing.
	if takehit_back.is_empty():
		sprite.flip_h = false
		sprite.texture = takehit_front[frame]
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var depth_dot := facing.dot(-cam.global_transform.basis.z)
	var side_dot := facing.dot(cam.global_transform.basis.x)
	if absf(depth_dot) >= absf(side_dot):
		sprite.flip_h = false
		sprite.texture = (takehit_back if depth_dot > 0.0 else takehit_front)[frame]
	else:
		sprite.flip_h = side_dot > 0.0
		sprite.texture = takehit_side[frame]


func _get_target() -> PhysicsBody3D:
	# A grudge holds only while its object stands; otherwise, the player.
	if target != null and is_instance_valid(target) and not target.get("dead"):
		return target
	target = null
	return player


func _perceives(who: PhysicsBody3D, dist: float, reach: float) -> bool:
	# Kin to fuse with, a corpse to eat, or a grudge is pursued on range +
	# line of sight alone. The player, unprovoked, must be HEARD (close, any
	# direction) or SEEN (inside the forward cone, at range, clear line):
	# no more sensing you through the back of the cap.
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


func alert() -> void:
	# Woken by a nearby kin's shout: snap awake, turn on the player, sting.
	# A grudge stays its own; only an idle cap adopts the player as target.
	if noticed:
		return
	noticed = true
	if target == null:
		target = player
	aggro_timer = AGGRO_TIME
	Sfx.play_at(AGGRO_SOUNDS[randi_range(0, AGGRO_SOUNDS.size() - 1)],
			global_position, -4.0)


func take_damage(amount: int, push_dir: Vector3, attacker: PhysicsBody3D = null) -> void:
	if dead:
		return
	health -= amount
	Sfx.play_at(TAKE_HIT_SOUNDS[randi_range(0, TAKE_HIT_SOUNDS.size() - 1)],
			global_position, -4.0, _hit_pitch())
	velocity += push_dir * 6.0
	knock_timer = KNOCK_TIME
	if attacker != null and attacker != self:
		# Pain redirects attention to whoever caused it.
		target = attacker
		last_attacker = attacker
		if attacker is Player:
			noticed = true  # a player hit wakes it — the dungeon poll then propagates
	sprite.modulate = Color(1.0, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", base_tint, 0.25)
	# Tiers above the bottom never die — lethal damage bursts them
	# instead, so the cascade always completes down to the minis.
	if state == State.BOSS and health <= BOSS_SPLIT_HEALTH:
		_split(State.MEGA)
	elif state == State.MEGA and health <= MEGA_SPLIT_HEALTH:
		_split(State.MUSH)
	elif state == State.MUSH and health <= MUSH_SPLIT_HEALTH:
		_split(State.MINI)
	elif health <= 0:
		_die(attacker == null or attacker is Player)


func _die(by_player: bool) -> void:
	# The squashed cap stays where it fell, flat like the slime splat.
	dead = true
	step_sound.stop()
	var death_snd := DEATH_MUSH
	if state == State.BOSS:
		death_snd = DEATH_BOSS
	elif state == State.MEGA:
		death_snd = DEATH_MEGA
	elif state == State.MINI:
		death_snd = DEATH_MINI
	Sfx.play_at(death_snd, global_position, -3.0)
	if by_player:
		RunState.record_kill(kill_label())
	remove_from_group("enemies")
	remove_from_group("mushes")
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	sprite.modulate = base_tint
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.rotation_degrees = Vector3(-90, 0, 0)
	# Body center rests at floor + radius; park the splat just above
	# the floor surface.
	sprite.position = Vector3(0, 0.03 - body_radius, 0)
	match state:
		State.BOSS:
			sprite.texture = TEX_DEAD_BOSS
		State.MEGA:
			sprite.texture = TEX_DEAD_MEGA
		State.MUSH:
			sprite.texture = TEX_DEAD_MUSH
		State.MINI:
			sprite.texture = TEX_DEAD_MINI
