extends CharacterBody3D

const DEATH_SOUND := preload("res://assets/audio/sfx/enemies/skeleton_death.ogg")
const REVIVE_SOUND := preload("res://assets/audio/sfx/enemies/skeleton_revive.ogg")
const TAKE_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/skeleton_take_hit1.ogg"),
	preload("res://assets/audio/sfx/enemies/skeleton_take_hit2.ogg"),
	preload("res://assets/audio/sfx/enemies/skeleton_take_hit3.ogg"),
]
const POTION_SCENE := preload("res://scenes/potion.tscn")
const HALF_POTION_SCENE := preload("res://scenes/half_potion.tscn")
const HEART_DROP_SCENE := preload("res://scenes/magic_heart_drop.tscn")
const HALF_HEART_DROP_SCENE := preload("res://scenes/half_magic_heart_drop.tscn")

const FRONT_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/skeleton/skeleton_front1.png"),
	preload("res://assets/sprites/skeleton/skeleton_front2.png"),
]
const SIDE_FRAMES: Array[Texture2D] = [  # drawn facing left; flipped for right
	preload("res://assets/sprites/skeleton/skeleton_side1.png"),
	preload("res://assets/sprites/skeleton/skeleton_side2.png"),
]
const BACK_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/skeleton/skeleton_back1.png"),
	preload("res://assets/sprites/skeleton/skeleton_back2.png"),
]
const DEAD_TEXTURE := preload("res://assets/sprites/skeleton/skeleton_dead.png")
const RISE_TEXTURE := preload("res://assets/sprites/skeleton/skeleton_mid_rise.png")
const FRONT_ATTACK: Array[Texture2D] = [  # faces what it hits, so no back
	preload("res://assets/sprites/skeleton/skeleton_front_attack1.png"),
	preload("res://assets/sprites/skeleton/skeleton_front_attack2.png"),
]
const SIDE_ATTACK: Array[Texture2D] = [  # drawn facing left; flipped for right
	preload("res://assets/sprites/skeleton/skeleton_side_attack1.png"),
	preload("res://assets/sprites/skeleton/skeleton_side_attack2.png"),
]
const WALK_FRAME_TIME := 0.3
const ATTACK_FRAME_TIME := 0.12  # per attack frame; two of them = one lunge
const AGGRO_TIME := 0.35  # startle freeze the first beat it notices you
const AGGRO_TURN_SPEED := 14.0  # rad/s it wheels around when caught from behind
const AGGRO_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/skeleton_aggro1.ogg"),
	preload("res://assets/audio/sfx/enemies/skeleton_aggro2.ogg"),
	preload("res://assets/audio/sfx/enemies/skeleton_aggro3.ogg"),
]
const AGGRO_TEX := preload("res://assets/sprites/skeleton/skeleton_front_aggro1.png")
const FRONT_TAKEHIT: Array[Texture2D] = [
	preload("res://assets/sprites/skeleton/skeleton_front_takehit1.png"),
	preload("res://assets/sprites/skeleton/skeleton_front_takehit2.png"),
]
const SIDE_TAKEHIT: Array[Texture2D] = [  # drawn facing left; flipped for right
	preload("res://assets/sprites/skeleton/skeleton_side_takehit1.png"),
	preload("res://assets/sprites/skeleton/skeleton_side_takehit2.png"),
]
const BACK_TAKEHIT: Array[Texture2D] = [
	preload("res://assets/sprites/skeleton/skeleton_back_takehit1.png"),
	preload("res://assets/sprites/skeleton/skeleton_back_takehit2.png"),
]

const RISE_CHANCE := 0.15
const RISE_RANGE := 3.5
const RISE_TIME := 1.0
const RISE_GRACE := 4.0
const RISEN_HEALTH := 4
const REVENANT_RISE_DELAY := 1.0  # beat of false calm after a pack drops, then it rises
# The floor twitches as bones stir — the rattle's redundant channel, for
# anyone playing quiet. Metres of camera jitter (the 3-3 floor caving is 0.2).
const RISE_SHAKE := 0.03            # one pile: a tick you feel without naming
const RISE_SHAKE_TIME := 0.35
const RISE_SHAKE_PACK := 0.07       # the whole pack standing: turn-around rumble
const RISE_SHAKE_PACK_TIME := 0.6
const RISE_SHAKE_RANGE := 10.0      # past this, a kick has no visible cause

const BASE_SPEED := 2.0
const MAX_SPEED := 3.2
const WANDER_SPEED := 0.9
const WANDER_LEG_MIN := 1.0
const WANDER_LEG_MAX := 2.5
const WANDER_PAUSE_MIN := 1.5
const WANDER_PAUSE_MAX := 5.0
const SIGHT_RANGE := 14.0  # forward vision reach, cone-gated
const INFIGHT_SIGHT_RANGE := 20.0
const HEAR_RANGE := 3.5  # sensed this close regardless of facing
const SIGHT_CONE_DEG := 110.0  # forward vision arc, full width
const ATTACK_RANGE := 1.4
const ATTACK_COOLDOWN := 1.2
# Flanking: when several bones chase the same prey, they shove off each other
# so the pack fans around you and closes in from the sides.
const FLANK_RANGE := 3.5     # a nearby enemy within this bends the approach
const FLANK_STRENGTH := 1.0  # how hard that push arcs the chase to a flank
# Chase persistence: after losing sight, keep coming to the last-seen spot for
# a beat before giving up — smart, but never live-tracks you through walls.
const CHASE_GRACE_TIME := 2.5  # seconds it pursues the last-seen position
const CHASE_ARRIVE := 1.0      # metres from that spot that count as "there"
const WALL_PROBE := 0.9        # how far ahead a wall counts as "blocking the way"
const MAX_HEALTH := 6
const KNOCK_TIME := 0.35
const KNOCK_FRICTION := 30.0
const FALL_Y := -1.5

var speed := BASE_SPEED
# The self-despawn net, per body so the boss drop can lower it (same pattern as
# skeletal_wizard.gd): a wave that rides the caving floor down must not delete
# itself to "the Dark Below" on the way to a chamber 12m under the old one.
var fall_y := FALL_Y
var health := MAX_HEALTH
var attack_timer := 0.0
var attack_anim := 0.0  # counts down while the lunge frames play
var noticed := false    # true while it currently perceives the player
var aggro_timer := 0.0  # counts down through the startle freeze
var last_seen := Vector3.ZERO  # where the player was last seen (pursuit target)
var chase_grace := 0.0         # ticks down out of sight; pursue last_seen until 0
var walk_time := 0.0
var dead := false
var restless := false
var rising := false
var rise_timer := 0.0
var rise_delay := 0.0
var revenant := false          # part of a rise-ONCE revenant pack (rises after you clear it)
var revenant_risen := false    # already spent its one revenant rise — stays down now
var revenant_pending := false  # whole pack is down; waiting out the beat to rise together
var pack: Array = []           # packmates, for the revenant all-down check
var target: PhysicsBody3D = null
var knock_timer := 0.0
var wander_dir := Vector3.ZERO
var wander_timer := 0.0
var facing := Vector3.FORWARD
var last_attacker: PhysicsBody3D = null
var wander_wait := randf_range(0.0, WANDER_PAUSE_MAX)  # desynced from birth

@onready var sprite: Sprite3D = $Sprite
@onready var step_sound: AudioStreamPlayer3D = $StepSound
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if dead:
		# Some piles are restless (stir when you come close); a revenant pack
		# rises once, together, after the whole pack is down. Both take a slow
		# second to stand — smash them mid-rise to scatter the bones for good.
		if restless or revenant_pending:
			rise_delay = maxf(rise_delay - delta, 0.0)
			if rising:
				rise_timer -= delta
				if rise_timer <= 0.0:
					_rise()
			elif rise_delay == 0.0:
				# Revenant: the pack already called it. Restless: only once
				# you've wandered into range.
				var wake := revenant_pending
				if restless and not wake and is_instance_valid(player):
					var to_p := player.global_position - global_position
					to_p.y = 0.0
					wake = to_p.length() < RISE_RANGE
				if wake:
					rising = true
					rise_timer = RISE_TIME
					sprite.texture = RISE_TEXTURE
					# The rattle: bones stirring, heard before seen.
					Sfx.play_at(REVIVE_SOUND, global_position, -2.0)
					_rise_shake()
		return
	if global_position.y < fall_y:
		_fall_into_dark()
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	aggro_timer = maxf(aggro_timer - delta, 0.0)
	if not is_on_floor():
		velocity += get_gravity() * delta

	if knock_timer > 0.0:
		# Staggered: the shove owns the body for a beat. Skid under
		# friction — steering would erase the knockback next tick.
		knock_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, KNOCK_FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, KNOCK_FRICTION * delta)
		move_and_slide()
		# The stagger IS the hit reaction: the 2-stage take-hit plays across
		# the skid (the red flash from take_damage tints it).
		_hit_view(0 if knock_timer > KNOCK_TIME * 0.5 else 1)
		return

	var t := _get_target()
	var to_target := t.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	var sight := SIGHT_RANGE if t == player else INFIGHT_SIGHT_RANGE

	var seen := _perceives(t, dist, sight)
	if seen and t == player:
		# Keep a running fix on where you are, and top up the pursuit clock.
		last_seen = t.global_position
		chase_grace = CHASE_GRACE_TIME
		if not noticed:
			noticed = true
			aggro_timer = AGGRO_TIME
			Sfx.play_at(AGGRO_SOUNDS[randi_range(0, AGGRO_SOUNDS.size() - 1)],
					global_position, -4.0)
	elif not seen:
		# Lost sight — hold the alert while the pursuit clock still runs.
		chase_grace = maxf(chase_grace - delta, 0.0)
		if chase_grace <= 0.0:
			noticed = false
	if aggro_timer > 0.0:
		# The notice beat: freeze and WHEEL to face you — creep up on its
		# back and it turns through a side view — then it charges. The alarm
		# pose lands once it's basically looking at you; until then the
		# turnaround frames show the spin.
		var want := to_target.normalized()
		var swing := facing.signed_angle_to(want, Vector3.UP)
		facing = facing.rotated(Vector3.UP,
				clampf(swing, -AGGRO_TURN_SPEED * delta, AGGRO_TURN_SPEED * delta))
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if facing.dot(want) > 0.85:
			sprite.flip_h = false
			sprite.texture = AGGRO_TEX
		else:
			_update_view(0)
		if step_sound.playing:
			step_sound.stop()
		return
	if seen:
		if dist > ATTACK_RANGE:
			var dir := to_target.normalized()
			if t == player:
				# Pack flanking: shove off nearby kin so a group arcs around
				# you and closes in from the sides, not a single-file line.
				dir = (dir + _flank_push() * FLANK_STRENGTH).normalized()
			dir = _nav_dir(dir)  # slip around doorway jambs instead of grinding
			facing = dir
			if _floor_ahead(dir):
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
			else:
				# Pulled up at the rim: it wants you, not the dark.
				velocity.x = 0.0
				velocity.z = 0.0
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			facing = to_target.normalized()
			if attack_timer == 0.0:
				attack_timer = ATTACK_COOLDOWN
				attack_anim = ATTACK_FRAME_TIME * 2.0
				t.take_damage(2, to_target.normalized(), self)
	elif chase_grace > 0.0:
		# Lost sight but still committed: press on to where you were last
		# seen (it watched you round the corner). Reach the spot, or the
		# clock runs out, and it drops back to wandering — it never tracks
		# you live through the wall, so a change of direction still loses it.
		var to_last := last_seen - global_position
		to_last.y = 0.0
		if to_last.length() > CHASE_ARRIVE:
			var dir := _nav_dir(to_last.normalized())  # navigate the doorway too
			facing = dir
			if _floor_ahead(dir):
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
			else:
				velocity.x = 0.0
				velocity.z = 0.0
		else:
			# Reached the empty spot — nothing here. Give it up.
			chase_grace = 0.0
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		_wander(delta)

	move_and_slide()

	# Two-frame shamble while moving; rest on the first frame when
	# still. Which view shows depends on camera versus heading.
	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if moving:
		walk_time += delta
	if attack_anim > 0.0:
		# The lunge takes over the walk: front or side (never back — a
		# skeleton faces what it hits), same projection as the walk view.
		attack_anim -= delta
		_attack_view(0 if attack_anim > ATTACK_FRAME_TIME else 1)
	else:
		_update_view(int(walk_time / WALK_FRAME_TIME) % 2 if moving else 0)
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


func _wander(delta: float) -> void:
	# Off-duty bones shamble about: short legs, long pauses. Walls
	# end a leg early; the sight check upstream overrides everything
	# the moment a target appears.
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
		sprite.texture = (BACK_FRAMES if depth > 0.0 else FRONT_FRAMES)[frame]
	else:
		sprite.flip_h = side > 0.0
		sprite.texture = SIDE_FRAMES[frame]


func _attack_view(frame: int) -> void:
	# The strike, same projection as _update_view but front/side only — no
	# back attack, since a skeleton turns to face whatever it hits.
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var depth := facing.dot(-cam.global_transform.basis.z)
	var side := facing.dot(cam.global_transform.basis.x)
	if absf(depth) >= absf(side):
		sprite.flip_h = false
		# No back-ATTACK art: facing away, the walk's back view stands in
		# (the lunge isn't visible from behind anyway).
		sprite.texture = BACK_FRAMES[frame] if depth > 0.0 else FRONT_ATTACK[frame]
	else:
		sprite.flip_h = side > 0.0
		sprite.texture = SIDE_ATTACK[frame]


func _hit_view(frame: int) -> void:
	# Take-hit turnaround, same projection as _update_view — the recoil
	# reads from whatever side the blow landed on.
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var depth := facing.dot(-cam.global_transform.basis.z)
	var side := facing.dot(cam.global_transform.basis.x)
	if absf(depth) >= absf(side):
		sprite.flip_h = false
		sprite.texture = (BACK_TAKEHIT if depth > 0.0 else FRONT_TAKEHIT)[frame]
	else:
		sprite.flip_h = side > 0.0
		sprite.texture = SIDE_TAKEHIT[frame]


func _floor_ahead(dir: Vector3) -> bool:
	# Probe for ground half a step ahead. Steering respects the rim;
	# only momentum (the knock skid) carries a body over it.
	var probe := global_position + dir * 0.7
	var query := PhysicsRayQueryParameters3D.create(
		probe, probe + Vector3.DOWN * 3.0, 1, [get_rid()])
	query.hit_from_inside = true
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _wall_ahead(dir: Vector3) -> bool:
	# A forward feeler for walls (the floor probe only catches pits). Cast at
	# mid-body height so it reads the wall, not the floor slab.
	var from := global_position + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(
		from, from + dir * WALL_PROBE, 1, [get_rid()])
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _nav_dir(desired: Vector3) -> Vector3:
	# Direct chase grinds on doorway jambs — it walks at you through the wall.
	# If the heading is blocked, fan out to nearby angles and take the first
	# that's open (clear + floored), so it slips around the corner. No real
	# pathfinding; falls through to the desired heading if truly boxed in.
	if not _wall_ahead(desired):
		return desired
	for a in [0.6, 1.1, 1.7]:
		var l := desired.rotated(Vector3.UP, a)
		if _floor_ahead(l) and not _wall_ahead(l):
			return l
		var r := desired.rotated(Vector3.UP, -a)
		if _floor_ahead(r) and not _wall_ahead(r):
			return r
	return desired


func _flank_push() -> Vector3:
	# Separation from nearby enemies, added to the seek so a pack fans out and
	# surrounds you instead of stacking single-file. Closer = harder push.
	var push := Vector3.ZERO
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e) or e.get("dead") == true:
			continue
		var away: Vector3 = global_position - e.global_position
		away.y = 0.0
		var d := away.length()
		if d > 0.01 and d < FLANK_RANGE:
			push += away.normalized() * (1.0 - d / FLANK_RANGE)
	return push


func _fall_into_dark() -> void:
	# The under-place keeps what it catches: credited if the player's
	# shove sent it over, but the body and its drops are gone.
	if is_instance_valid(last_attacker) and last_attacker is Player:
		RunState.record_kill(kill_label())
	queue_free()


func setup(depth: int) -> void:
	# Deeper floors: faster bones, and a bit tougher every third floor.
	speed = minf(BASE_SPEED + 0.1 * (depth - 1), MAX_SPEED)
	@warning_ignore("integer_division")
	health += 2 * ((depth - 1) / 3)


func kill_label() -> String:
	return "Skeleton"


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
	# no more noticing you through the back of the skull.
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
		global_position + Vector3.UP * 0.5,
		t.global_position + Vector3.UP * 0.3,
		1, [get_rid(), t.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _rise() -> void:
	# It remembers you.
	dead = false
	restless = false
	rising = false
	revenant_pending = false
	if revenant:
		# A revenant rises exactly once; after this it's an ordinary bone.
		revenant_risen = true
		revenant = false
	health = RISEN_HEALTH
	target = player
	add_to_group("enemies")
	$CollisionShape3D.set_deferred("disabled", false)
	sprite.texture = FRONT_FRAMES[0]


func _rise_shake() -> void:
	# Lands on the rattle, not on the stand — the shake IS the warning, so it
	# has to arrive with the sound it stands in for. Fades out with distance:
	# a revenant pack can wake a room away, and a kick from nowhere reads as a
	# bug. Restless singles are always inside RISE_RANGE, so they never fade
	# far. Packmates all fire the same frame; player.shake takes the max, so
	# three bones make one rumble, not three.
	if not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)
	if dist > RISE_SHAKE_RANGE:
		return
	var falloff := 1.0 - dist / RISE_SHAKE_RANGE
	if revenant_pending:
		player.shake(RISE_SHAKE_PACK * falloff, RISE_SHAKE_PACK_TIME)
	else:
		player.shake(RISE_SHAKE * falloff, RISE_SHAKE_TIME)


func _revenant_check() -> void:
	# A revenant packmate just went down. If the WHOLE pack is down (dead or
	# fallen away), wake them all at once after a beat — the rattle tell, then
	# they stand together for a second wave.
	for m in pack:
		if is_instance_valid(m) and not m.get("dead"):
			return  # someone's still standing — not yet
	for m in pack:
		if is_instance_valid(m) and m.get("dead") and not m.get("revenant_risen"):
			m.set("revenant_pending", true)
			m.set("rise_delay", REVENANT_RISE_DELAY)


func alert() -> void:
	# Woken by a nearby kin's shout: snap awake, turn on the player, sting.
	# A grudge stays its own; only idle bones adopt the player as target.
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
		if rising:
			# Caught it mid-rise: the bones scatter for good.
			restless = false
			rising = false
			revenant_pending = false
			revenant_risen = true
			sprite.texture = DEAD_TEXTURE
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
		if attacker is Player:
			noticed = true  # a player hit wakes it — the dungeon poll then propagates
	sprite.modulate = Color(1.0, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)
	if health <= 0:
		_die(attacker == null or attacker is Player)


func _die(by_player: bool) -> void:
	# The corpse stays: swap to the bone pile and stop being a threat.
	dead = true
	attack_anim = 0.0  # drop any mid-lunge so a rise doesn't flash it
	step_sound.stop()
	Sfx.play_at(DEATH_SOUND, global_position, -3.0)
	if by_player:
		RunState.record_kill(kill_label())
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	sprite.flip_h = false
	sprite.texture = DEAD_TEXTURE
	velocity = Vector3.ZERO
	if revenant and not revenant_risen:
		# A revenant packmate is down — it does NOT rise on its own; the pack
		# rises together once every member is down.
		_revenant_check()
	elif not revenant_risen:
		# A plain skeleton: maybe a restless pile that stirs on approach.
		restless = randf() < RISE_CHANCE
		rise_delay = RISE_GRACE
	# (A revenant that already rose stays down — no restless roll.)
	# Roll drops off the corpse so the sprites never share a depth
	# (coplanar billboards z-fight). Halves are the common change,
	# full drops the treat.
	var roll := Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU) * 0.45
	var r := randf()
	if RunState.lucky:
		# The Lucky Luck Stone: the deep is generous.
		r *= 0.6
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
