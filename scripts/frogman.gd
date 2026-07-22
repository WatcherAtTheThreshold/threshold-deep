extends CharacterBody3D

enum State { COATED, REVEAL, FROG, TOAD }

const COATED_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/frogmen/frogmen-phase1/frogmen_front1.png"),
	preload("res://assets/sprites/frogmen/frogmen-phase1/frogmen_front2.png"),
]
const COATED_SIDE: Array[Texture2D] = [  # drawn facing left; flipped for right
	preload("res://assets/sprites/frogmen/frogmen-phase1/frogmen_side1.png"),
	preload("res://assets/sprites/frogmen/frogmen-phase1/frogmen_side2.png"),
]
const COATED_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/frogmen/frogmen-phase1/frogmen_back1.png"),
	preload("res://assets/sprites/frogmen/frogmen-phase1/frogmen_back2.png"),
]
const TEX_REVEAL := preload("res://assets/sprites/frogmen/frogmen-phase-stransition.png")
const TEX_FROG_1 := preload("res://assets/sprites/frogmen/frogmen-phase2/frog1.png")
const TEX_FROG_2 := preload("res://assets/sprites/frogmen/frogmen-phase2/frog2.png")
const TEX_TOAD_1 := preload("res://assets/sprites/frogmen/frogmen-phase2/toad1.png")
const TEX_TOAD_2 := preload("res://assets/sprites/frogmen/frogmen-phase2/toad2.png")
const TEX_COAT := preload("res://assets/sprites/frogmen/frogmen-phase1/frogmen-dead.png")
const TEX_FROG_DEAD := preload("res://assets/sprites/frogmen/frogmen-phase2/frog_dead.png")
const TEX_TOAD_DEAD := preload("res://assets/sprites/frogmen/frogmen-phase2/toad_dead.png")
const TAKE_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/frogmen_frog_toad_take_damage1.wav"),
	preload("res://assets/audio/sfx/enemies/frogmen_frog_toad_take_damage2.wav"),
	preload("res://assets/audio/sfx/enemies/frogmen_frog_toad_take_damage3.wav"),
]
const WALK_FRAME_TIME := 0.3

const COATED_HEALTH := 14
const REVEAL_AT := 6
const REVEAL_TIME := 0.7
const FROG_HEALTH := 4
const TOAD_HEALTH := 6
const COATED_SPEED := 1.8
const TOAD_SPEED := 1.6
const FROG_HOP_SPEED := 5.0
const FROG_HOP_TIME := 0.35
const FROG_HOP_REST := 0.55
const SIGHT_RANGE := 14.0  # forward vision reach, cone-gated
const INFIGHT_SIGHT_RANGE := 20.0
const HEAR_RANGE := 3.5  # sensed this close regardless of facing
const SIGHT_CONE_DEG := 110.0  # forward vision arc, full width
const ATTACK_RANGE := 1.3
const ATTACK_COOLDOWN := 1.2
const KNOCK_TIME := 0.35
const KNOCK_FRICTION := 30.0
const FALL_Y := -1.5
# Coated wanderers stride: longer legs than the skeleton's shuffle,
# so a frogman crossing a long corridor is a sight you can meet.
const WANDER_SPEED := 1.2
const WANDER_LEG_MIN := 1.5
const WANDER_LEG_MAX := 3.5
const WANDER_PAUSE_MIN := 2.0
const WANDER_PAUSE_MAX := 6.0

var state := State.COATED
var health := COATED_HEALTH
var damage := 2
var speed_scale := 1.0
var reveal_timer := 0.0
var hop_clock := 0.0
var attack_timer := 0.0
var walk_time := 0.0
var dead := false
var target: PhysicsBody3D = null
var frame_a: Texture2D = COATED_FRONT[0]
var frame_b: Texture2D = COATED_FRONT[1]
var knock_timer := 0.0
var last_attacker: PhysicsBody3D = null
var facing := Vector3.FORWARD
var wander_dir := Vector3.ZERO
var wander_timer := 0.0
var wander_wait := randf_range(0.0, WANDER_PAUSE_MAX)  # desynced from birth

@onready var sprite: Sprite3D = $Sprite
@onready var step_sound: AudioStreamPlayer3D = $StepSound
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	_apply_state()


func configure(new_state: State, hp: int) -> void:
	# Called before add_child by the splitting parent.
	state = new_state
	health = hp


func setup(depth: int) -> void:
	speed_scale = 1.0 + minf(0.04 * (depth - 1), 0.4)


func kill_label() -> String:
	match state:
		State.FROG:
			return "Frog"
		State.TOAD:
			return "Toad"
		_:
			return "Frogman"


func _physics_process(delta: float) -> void:
	if dead:
		return
	if global_position.y < FALL_Y:
		_fall_into_dark()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	attack_timer = maxf(attack_timer - delta, 0.0)

	if state == State.REVEAL:
		# The comedic beat: coat off, secret out, nobody moves.
		velocity.x = 0.0
		velocity.z = 0.0
		reveal_timer -= delta
		if reveal_timer <= 0.0:
			_split()
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

	var t := _get_target()
	var to_target := t.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	var sight := SIGHT_RANGE if t == player else INFIGHT_SIGHT_RANGE

	if _perceives(t, dist, sight):
		if dist > ATTACK_RANGE:
			var dir := to_target.normalized()
			facing = dir
			if not _floor_ahead(dir):
				# Pulled up at the rim — even the frog knows better.
				velocity.x = move_toward(velocity.x, 0.0, 4.0)
				velocity.z = move_toward(velocity.z, 0.0, 4.0)
			elif state == State.FROG:
				# Froggy locomotion: lunge, rest, lunge.
				hop_clock += delta
				if fmod(hop_clock, FROG_HOP_TIME + FROG_HOP_REST) < FROG_HOP_TIME:
					velocity.x = dir.x * FROG_HOP_SPEED * speed_scale
					velocity.z = dir.z * FROG_HOP_SPEED * speed_scale
				else:
					velocity.x = move_toward(velocity.x, 0.0, FROG_HOP_SPEED * 0.15)
					velocity.z = move_toward(velocity.z, 0.0, FROG_HOP_SPEED * 0.15)
			else:
				var speed := (COATED_SPEED if state == State.COATED else TOAD_SPEED) * speed_scale
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			facing = to_target.normalized()
			if attack_timer == 0.0:
				attack_timer = ATTACK_COOLDOWN
				t.take_damage(damage, to_target.normalized(), self)
	elif state == State.COATED:
		# Unbothered coats patrol; frogs and toads exist mid-fight
		# and just settle.
		_wander(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 2.0)
		velocity.z = move_toward(velocity.z, 0.0, 2.0)

	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if moving:
		walk_time += delta
	var frame := int(walk_time / WALK_FRAME_TIME) % 2 if moving else 0
	if state == State.COATED:
		_update_view(frame)
	else:
		sprite.texture = frame_a if frame == 0 else frame_b
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


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
	if last_attacker is Player:
		RunState.record_kill(kill_label())
	queue_free()


func _wander(delta: float) -> void:
	# Off-duty coats stride about: longer legs, unhurried pauses.
	# Walls and rims end a leg early; the sight check upstream
	# overrides the moment a target appears.
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
		velocity.x = move_toward(velocity.x, 0.0, 2.0)
		velocity.z = move_toward(velocity.z, 0.0, 2.0)
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
		sprite.texture = (COATED_BACK if depth > 0.0 else COATED_FRONT)[frame]
	else:
		sprite.flip_h = side > 0.0
		sprite.texture = COATED_SIDE[frame]


func _start_reveal() -> void:
	state = State.REVEAL
	reveal_timer = REVEAL_TIME
	sprite.flip_h = false
	sprite.texture = TEX_REVEAL
	sprite.modulate = Color.WHITE
	velocity = Vector3.ZERO
	step_sound.stop()


func _split() -> void:
	# The crumpled coat stays where the secret came out.
	var coat := Sprite3D.new()
	coat.texture = TEX_COAT
	coat.pixel_size = 0.03125
	coat.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	coat.shaded = true
	coat.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	coat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	coat.position = global_position + Vector3(0, 0.1, 0)
	get_parent().add_child.call_deferred(coat)
	# The frog (this body) and the toad go their separate ways.
	var side := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
	var toad: CharacterBody3D = (load("res://scenes/frogman.tscn") as PackedScene).instantiate()
	toad.configure(State.TOAD, TOAD_HEALTH)
	toad.position = global_position + side * 0.8
	toad.velocity = side * 2.5
	get_parent().add_child.call_deferred(toad)
	state = State.FROG
	health = FROG_HEALTH
	velocity = -side * 2.5
	_apply_state()


func _apply_state() -> void:
	match state:
		State.COATED:
			frame_a = COATED_FRONT[0]
			frame_b = COATED_FRONT[1]
			$CollisionShape3D.shape = CapsuleShape3D.new()
			$CollisionShape3D.shape.radius = 0.5
			$CollisionShape3D.shape.height = 1.8
			sprite.position = Vector3(0, 0.1, 0)
			step_sound.pitch_scale = 1.0
		State.FROG:
			frame_a = TEX_FROG_1
			frame_b = TEX_FROG_2
			$CollisionShape3D.shape = SphereShape3D.new()
			$CollisionShape3D.shape.radius = 0.5
			sprite.position = Vector3(0, 0.5, 0)
			step_sound.pitch_scale = 1.25
		State.TOAD:
			frame_a = TEX_TOAD_1
			frame_b = TEX_TOAD_2
			$CollisionShape3D.shape = SphereShape3D.new()
			$CollisionShape3D.shape.radius = 0.5
			sprite.position = Vector3(0, 0.5, 0)
			step_sound.pitch_scale = 0.9
		_:
			pass
	sprite.texture = frame_a


func _get_target() -> PhysicsBody3D:
	# A grudge holds only while its object stands; otherwise, the player.
	if target != null and is_instance_valid(target) and not target.get("dead"):
		return target
	target = null
	return player


func _perceives(who: PhysicsBody3D, dist: float, reach: float) -> bool:
	# A known threat — a grudge, or infighting kin — is hunted on range +
	# line of sight alone. The player, unprovoked, must be HEARD (close, any
	# direction) or SEEN (inside the forward cone, at range, clear line):
	# no more noticing you through the back of the coat.
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
	# The reveal beat is untouchable — the joke always lands.
	if dead or state == State.REVEAL:
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
	if state == State.COATED:
		if health <= REVEAL_AT:
			_start_reveal()
	elif health <= 0:
		_die(attacker == null or attacker is Player)


func _die(by_player: bool) -> void:
	# The corpse stays: frog or toad, collapsed where it fell.
	dead = true
	step_sound.stop()
	if by_player:
		RunState.record_kill(kill_label())
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	sprite.modulate = Color.WHITE
	sprite.texture = TEX_FROG_DEAD if state == State.FROG else TEX_TOAD_DEAD
