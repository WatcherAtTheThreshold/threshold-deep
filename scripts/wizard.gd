extends CharacterBody3D

# --- The necromancer roster (docs/necromancers.md) -------------------------
# ONE script, many necromancers — the mush.gd / slime.gd pattern (one script,
# a state var, per-state assets). Behaviour is IDENTICAL across elements: same
# keep-your-distance chase, same telegraphed cast, same startle. What changes
# is the look, the voice, and what the orb leaves behind. Adding brown means
# adding a const block and a `match` arm, nothing else.
enum Element { BLUE, RED, BROWN }

# BLUE — the original bolt-thrower.
const BLUE_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_front1.png"),
	preload("res://assets/sprites/wizard/wizard_front2.png"),
]
const BLUE_SIDE: Array[Texture2D] = [  # drawn facing left; flipped for right
	preload("res://assets/sprites/wizard/wizard_side1.png"),
	preload("res://assets/sprites/wizard/wizard_side2.png"),
]
const BLUE_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_back1.png"),
	preload("res://assets/sprites/wizard/wizard_back2.png"),
]
const BLUE_DEAD := preload("res://assets/sprites/wizard/wizard_dead.png")
const BLUE_SHOOT_1 := preload("res://assets/sprites/wizard/wizard_shoot1.png")
const BLUE_SHOOT_2 := preload("res://assets/sprites/wizard/wizard_shoot2.png")
const BLUE_SHOOT_3 := preload("res://assets/sprites/wizard/wizard_shoot3.png")
const BLUE_AGGRO_TEX := preload("res://assets/sprites/wizard/wizard_front_aggro1.png")
const BLUE_FRONT_TAKEHIT: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_front_takehit1.png"),
	preload("res://assets/sprites/wizard/wizard_front_takehit2.png"),
]
const BLUE_SIDE_TAKEHIT: Array[Texture2D] = [  # drawn facing left
	preload("res://assets/sprites/wizard/wizard_side_takehit1.png"),
	preload("res://assets/sprites/wizard/wizard_side_takehit2.png"),
]
const BLUE_BACK_TAKEHIT: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_back_takehit1.png"),
	preload("res://assets/sprites/wizard/wizard_back_takehit2.png"),
]
const BLUE_ORB_A := preload("res://assets/sprites/wizard/wizard_orb1.png")
const BLUE_ORB_B := preload("res://assets/sprites/wizard/wizard_orb2.png")
const BLUE_AGGRO_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/wizard_aggro1.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_aggro2.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_aggro3.ogg"),
]
const BLUE_CAST_SOUND := preload("res://assets/audio/sfx/enemies/wizard_cast1.ogg")
const BLUE_ORB_IMPACTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/wizard_orb_hit1.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_orb_hit2.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_orb_hit3.ogg"),
]
const BLUE_ORB_FLIGHT := preload("res://assets/audio/sfx/enemies/wizard_orb_flight1.ogg")
const BLUE_GLOW := Color(0.45, 0.9, 1)
const BLUE_GLOW_ENERGY := 1.2  # matches orb.tscn's Glow; the roster's brightest

# RED — the fireball caster, fully its own now (art landed 2026-08-02).
# Note the nested path: red lives in wizard/wizard_red/, a subfolder rather
# than a sibling of wizard/ (the frogmen phase-folder shape). Blue's frames
# stay loose in wizard/.
const RED_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_front1.png"),
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_front2.png"),
]
const RED_SIDE: Array[Texture2D] = [  # drawn facing left; flipped for right
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_side1.png"),
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_side2.png"),
]
const RED_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_back1.png"),
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_back2.png"),
]
const RED_DEAD := preload("res://assets/sprites/wizard/wizard_red/wizard_red_dead.png")
const RED_SHOOT_1 := preload("res://assets/sprites/wizard/wizard_red/wizard_red_shoot1.png")
const RED_SHOOT_2 := preload("res://assets/sprites/wizard/wizard_red/wizard_red_shoot2.png")
const RED_SHOOT_3 := preload("res://assets/sprites/wizard/wizard_red/wizard_red_shoot3.png")
const RED_AGGRO_TEX := preload("res://assets/sprites/wizard/wizard_red/wizard_red_front_aggro1.png")
const RED_FRONT_TAKEHIT: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_front_takehit1.png"),
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_front_takehit2.png"),
]
const RED_SIDE_TAKEHIT: Array[Texture2D] = [  # drawn facing left
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_side_takehit1.png"),
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_side_takehit2.png"),
]
const RED_BACK_TAKEHIT: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_back_takehit1.png"),
	preload("res://assets/sprites/wizard/wizard_red/wizard_red_back_takehit2.png"),
]
const RED_ORB_A := preload("res://assets/sprites/wizard/wizard_red/wizard_red_orb1.png")
const RED_ORB_B := preload("res://assets/sprites/wizard/wizard_red/wizard_red_orb2.png")
# Red's own voice.
const RED_AGGRO_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/wizard_red_aggro1.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_red_aggro2.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_red_aggro3.ogg"),
]
const RED_CAST_SOUND := preload("res://assets/audio/sfx/enemies/wizard_red_cast1.ogg")
const RED_ORB_IMPACTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/wizard_red_orb_hit1.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_red_orb_hit2.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_red_orb_hit3.ogg"),
]
const RED_ORB_FLIGHT := preload("res://assets/audio/sfx/enemies/wizard_red_orb_flight1.ogg")
const RED_GLOW := Color(1.0, 0.45, 0.15)  # firelight, not bolt-blue
const RED_GLOW_ENERGY := BLUE_GLOW_ENERGY  # fire burns as bright as the bolt

# BROWN — conjures an orb of debris: earth and rubble pulled together and
# thrown. No Dot, and the dimmest orb on the roster.
const BROWN_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_front1.png"),
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_front2.png"),
]
const BROWN_SIDE: Array[Texture2D] = [  # drawn facing left; flipped for right
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_side1.png"),
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_side2.png"),
]
const BROWN_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_back1.png"),
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_back2.png"),
]
const BROWN_DEAD := preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_dead.png")
const BROWN_SHOOT_1 := preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_shoot1.png")
const BROWN_SHOOT_2 := preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_shoot2.png")
const BROWN_SHOOT_3 := preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_shoot3.png")
const BROWN_AGGRO_TEX := preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_front_aggro1.png")
const BROWN_FRONT_TAKEHIT: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_front_takehit1.png"),
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_front_takehit2.png"),
]
const BROWN_SIDE_TAKEHIT: Array[Texture2D] = [  # drawn facing left
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_side_takehit1.png"),
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_side_takehit2.png"),
]
const BROWN_BACK_TAKEHIT: Array[Texture2D] = [
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_back_takehit1.png"),
	preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_back_takehit2.png"),
]
const BROWN_ORB_A := preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_orb1.png")
const BROWN_ORB_B := preload("res://assets/sprites/wizard/wizard_brown/wizard_brown_orb2.png")
const BROWN_AGGRO_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/wizard_brown_aggro1.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_brown_aggro2.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_brown_aggro3.ogg"),
]
const BROWN_CAST_SOUND := preload("res://assets/audio/sfx/enemies/wizard_brown_cast1.ogg")
const BROWN_ORB_IMPACTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/wizard_brown_orb_hit1.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_brown_orb_hit2.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_brown_orb_hit3.ogg"),
]
const BROWN_ORB_FLIGHT := preload("res://assets/audio/sfx/enemies/wizard_brown_orb_flight1.ogg")
const BROWN_GLOW := Color(0.72, 0.5, 0.28)  # dusty amber — earth, not spellwork
const BROWN_GLOW_ENERGY := 0.6  # dim, but never dark: see orb.gd's glow_energy

# Which necromancer a spawn turns out to be — cumulative thresholds, the same
# shape dungeon.gd rolls enemy types with. What's left over stays blue. Set one
# to 1.0 to make every wizard that element while testing.
const RED_CHANCE := 0.3
const BROWN_CHANCE := 0.3

# SHARED across the whole roster — they are all people in robes, and one set
# of pain is enough (docs/necromancers.md, the shared/per-variant table).
const TAKE_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/wizard_take_hit1.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_take_hit2.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_take_hit3.ogg"),
]
const DEATH_SOUND := preload("res://assets/audio/sfx/enemies/wizard_death1.ogg")

const ORB_SCENE := preload("res://scenes/orb.tscn")
const POTION_SCENE := preload("res://scenes/potion.tscn")
const HALF_POTION_SCENE := preload("res://scenes/half_potion.tscn")
const HEART_DROP_SCENE := preload("res://scenes/magic_heart_drop.tscn")
const HALF_HEART_DROP_SCENE := preload("res://scenes/half_magic_heart_drop.tscn")
const WALK_FRAME_TIME := 0.3
const AGGRO_TIME := 0.35  # startle freeze the first beat it notices you
const AGGRO_TURN_SPEED := 14.0  # rad/s it wheels around when caught from behind

const SPEED := 1.6
const RETREAT_RANGE := 4.0
const CAST_RANGE := 11.0
const SIGHT_RANGE := 14.0  # forward vision reach, cone-gated
const INFIGHT_SIGHT_RANGE := 20.0
const HEAR_RANGE := 3.5  # sensed this close regardless of facing
const SIGHT_CONE_DEG := 110.0  # forward vision arc, full width
const BASE_CAST_COOLDOWN := 2.2
const CHARGE_TIME := 0.45
const RECOVERY_TIME := 0.4
const MAX_HEALTH := 4
const KNOCK_TIME := 0.35
const KNOCK_FRICTION := 30.0
const FALL_Y := -1.5
# Wizards drift when unwatched: slower, shorter wanders than bones.
const WANDER_SPEED := 0.8
const WANDER_LEG_MIN := 0.8
const WANDER_LEG_MAX := 2.0
const WANDER_PAUSE_MIN := 2.0
const WANDER_PAUSE_MAX := 6.0

# The self-despawn net, per body so the boss drop can lower it (same pattern as
# skeletal_wizard.gd): a wave that rides the caving floor down must not delete
# itself to "the Dark Below" on the way to a chamber 12m under the old one.
var fall_y := FALL_Y
# Which necromancer this one is. Rolled in setup() (before add_child, so no
# node touching there) and APPLIED in _ready(), once @onready nodes exist.
var element := Element.BLUE
var front_frames: Array[Texture2D] = BLUE_FRONT
var side_frames: Array[Texture2D] = BLUE_SIDE
var back_frames: Array[Texture2D] = BLUE_BACK
var dead_texture: Texture2D = BLUE_DEAD
var tex_shoot_1: Texture2D = BLUE_SHOOT_1
var tex_shoot_2: Texture2D = BLUE_SHOOT_2
var tex_shoot_3: Texture2D = BLUE_SHOOT_3
var aggro_tex: Texture2D = BLUE_AGGRO_TEX
var front_takehit: Array[Texture2D] = BLUE_FRONT_TAKEHIT
var side_takehit: Array[Texture2D] = BLUE_SIDE_TAKEHIT
var back_takehit: Array[Texture2D] = BLUE_BACK_TAKEHIT
var orb_frame_a: Texture2D = BLUE_ORB_A
var orb_frame_b: Texture2D = BLUE_ORB_B
var aggro_sounds: Array[AudioStream] = BLUE_AGGRO_SOUNDS
var cast_sound: AudioStream = BLUE_CAST_SOUND
var orb_impacts: Array[AudioStream] = BLUE_ORB_IMPACTS
var orb_flight: AudioStream = BLUE_ORB_FLIGHT
var element_glow: Color = BLUE_GLOW
var element_glow_energy := BLUE_GLOW_ENERGY
var ember := false  # red's signature: its orb leaves a burn on what it hits
var health := MAX_HEALTH
var cast_cooldown := BASE_CAST_COOLDOWN
var cast_timer := 1.0
var charge_timer := 0.0
var recovery_timer := 0.0
var charging := false
var walk_time := 0.0
var dead := false
var target: PhysicsBody3D = null
var glow_tween: Tween
var knock_timer := 0.0
var last_attacker: PhysicsBody3D = null
var facing := Vector3.FORWARD
var noticed := false    # true while it currently perceives the player
var aggro_timer := 0.0  # counts down through the startle freeze
var wander_dir := Vector3.ZERO
var wander_timer := 0.0
var wander_wait := randf_range(0.0, WANDER_PAUSE_MAX)  # desynced from birth

@onready var cast_glow: OmniLight3D = $CastGlow
@onready var sprite: Sprite3D = $Sprite
@onready var step_sound: AudioStreamPlayer3D = $StepSound
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	_apply_element()


func _apply_element() -> void:
	# Blue's values are already the defaults, so only a non-blue element needs
	# a arm here. Runs after add_child, so the nodes are real.
	match element:
		Element.RED:
			front_frames = RED_FRONT
			side_frames = RED_SIDE
			back_frames = RED_BACK
			dead_texture = RED_DEAD
			tex_shoot_1 = RED_SHOOT_1
			tex_shoot_2 = RED_SHOOT_2
			tex_shoot_3 = RED_SHOOT_3
			aggro_tex = RED_AGGRO_TEX
			front_takehit = RED_FRONT_TAKEHIT
			side_takehit = RED_SIDE_TAKEHIT
			back_takehit = RED_BACK_TAKEHIT
			orb_frame_a = RED_ORB_A
			orb_frame_b = RED_ORB_B
			aggro_sounds = RED_AGGRO_SOUNDS
			cast_sound = RED_CAST_SOUND
			orb_impacts = RED_ORB_IMPACTS
			orb_flight = RED_ORB_FLIGHT
			element_glow = RED_GLOW
			element_glow_energy = RED_GLOW_ENERGY
			ember = true
		Element.BROWN:
			front_frames = BROWN_FRONT
			side_frames = BROWN_SIDE
			back_frames = BROWN_BACK
			dead_texture = BROWN_DEAD
			tex_shoot_1 = BROWN_SHOOT_1
			tex_shoot_2 = BROWN_SHOOT_2
			tex_shoot_3 = BROWN_SHOOT_3
			aggro_tex = BROWN_AGGRO_TEX
			front_takehit = BROWN_FRONT_TAKEHIT
			side_takehit = BROWN_SIDE_TAKEHIT
			back_takehit = BROWN_BACK_TAKEHIT
			orb_frame_a = BROWN_ORB_A
			orb_frame_b = BROWN_ORB_B
			aggro_sounds = BROWN_AGGRO_SOUNDS
			cast_sound = BROWN_CAST_SOUND
			orb_impacts = BROWN_ORB_IMPACTS
			orb_flight = BROWN_ORB_FLIGHT
			element_glow = BROWN_GLOW
			element_glow_energy = BROWN_GLOW_ENERGY
			# No ember: the rock is just a rock.
	# The charge telegraph wears the element's colour — a red caster winding up
	# under a blue light would break the read the robe is supposed to give you.
	cast_glow.light_color = element_glow
	sprite.texture = front_frames[0]


func _physics_process(delta: float) -> void:
	if dead:
		return
	if global_position.y < fall_y:
		_fall_into_dark()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	aggro_timer = maxf(aggro_timer - delta, 0.0)
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
	var sees_target := _perceives(t, dist, sight)
	if sees_target and t == player and not noticed:
		noticed = true
		aggro_timer = AGGRO_TIME
		Sfx.play_at(aggro_sounds[randi_range(0, aggro_sounds.size() - 1)],
				global_position, -4.0)
	elif not sees_target:
		noticed = false
	if sees_target and dist > 0.01 and aggro_timer <= 0.0:
		# A caster keeps its eyes on you even while backpedaling — but not
		# mid-startle, where it's still wheeling round toward the noise.
		facing = to_target.normalized()
	if aggro_timer > 0.0:
		# The notice beat: freeze, cast broken, and WHEEL to face you —
		# caught from behind it turns through a side view — then it resumes
		# keeping eyes on you. Alarm pose lands once it's basically there.
		_stop_cast_glow()
		charging = false
		var want := to_target.normalized()
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

	if charging:
		# Rooted while the cast winds up — orb at the chest, glow
		# swelling: the telegraph is the tell.
		velocity.x = 0.0
		velocity.z = 0.0
		charge_timer -= delta
		if charge_timer <= 0.0:
			charging = false
			_stop_cast_glow()
			if sees_target:
				_fire_orb(t)
				recovery_timer = RECOVERY_TIME
			cast_timer = cast_cooldown
	elif sees_target:
		# Keep respectful distance: back away if the target closes in.
		if dist < RETREAT_RANGE:
			var away := -to_target.normalized()
			if _floor_ahead(away):
				velocity.x = away.x * SPEED
				velocity.z = away.z * SPEED
			else:
				# A rim at its back: nowhere left to give, so it holds.
				velocity.x = 0.0
				velocity.z = 0.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
			velocity.z = move_toward(velocity.z, 0.0, SPEED)
		cast_timer -= delta
		if cast_timer <= 0.0 and dist <= CAST_RANGE:
			charging = true
			charge_timer = CHARGE_TIME
			_start_cast_glow()
	else:
		_wander(delta)

	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if charging:
		# Anticipation: the orb drawn to the chest.
		sprite.texture = tex_shoot_1
	elif recovery_timer > 0.0:
		# Release, then follow-through.
		recovery_timer -= delta
		sprite.texture = tex_shoot_2 if recovery_timer > RECOVERY_TIME * 0.5 else tex_shoot_3
	elif moving:
		walk_time += delta
		_update_view(int(walk_time / WALK_FRAME_TIME) % 2)
	else:
		_update_view(0)
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


func setup(depth: int) -> void:
	# Deeper wizards cast a little more often.
	cast_cooldown = maxf(BASE_CAST_COOLDOWN - 0.08 * (depth - 1), 1.4)
	# Which necromancer showed up. Rolled HERE because setup() runs before
	# add_child — only the flag is set; _ready() does the node work.
	var roll := randf()
	if roll < RED_CHANCE:
		element = Element.RED
	elif roll < RED_CHANCE + BROWN_CHANCE:
		element = Element.BROWN


func kill_label() -> String:
	# The fiction name. The code family stays `wizard` (it's load-bearing
	# across scripts, scenes and assets); the player only ever sees this.
	match element:
		Element.RED:
			return "Red Necromancer"
		Element.BROWN:
			return "Brown Necromancer"
	return "Necromancer"


func _floor_ahead(dir: Vector3) -> bool:
	# Probe for ground half a step ahead. Steering respects the rim;
	# only momentum (the knock skid) carries a body over it.
	var probe := global_position + dir * 0.7
	var query := PhysicsRayQueryParameters3D.create(
		probe, probe + Vector3.DOWN * 3.0, 1, [get_rid()])
	query.hit_from_inside = true
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _wander(delta: float) -> void:
	# Unwatched wizards drift about: short slow legs, long pauses.
	# Walls and rims end a leg early; sight overrides everything.
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
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
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
		sprite.texture = (back_frames if depth > 0.0 else front_frames)[frame]
	else:
		sprite.flip_h = side > 0.0
		sprite.texture = side_frames[frame]


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
		sprite.texture = (back_takehit if depth > 0.0 else front_takehit)[frame]
	else:
		sprite.flip_h = side > 0.0
		sprite.texture = side_takehit[frame]


func _fall_into_dark() -> void:
	# The under-place keeps what it catches: credited if the player's
	# shove sent it over, but the body and its drops are gone.
	if is_instance_valid(last_attacker) and last_attacker is Player:
		RunState.record_kill(kill_label())
	queue_free()


func _get_target() -> PhysicsBody3D:
	# A grudge holds only while its object stands; otherwise, the player.
	if target != null and is_instance_valid(target) and not target.get("dead"):
		return target
	target = null
	return player


func _start_cast_glow() -> void:
	# The chest-orb powers up: light swells across the whole charge.
	if glow_tween != null:
		glow_tween.kill()
	cast_glow.light_energy = 0.25
	glow_tween = create_tween()
	glow_tween.tween_property(cast_glow, "light_energy", 1.5, CHARGE_TIME)


func _stop_cast_glow() -> void:
	# The orb has left (or the cast broke) — the wizard goes dark.
	if glow_tween != null:
		glow_tween.kill()
	cast_glow.light_energy = 0.0


func _fire_orb(t: PhysicsBody3D) -> void:
	var from := global_position + Vector3.UP * 0.3
	var orb := ORB_SCENE.instantiate()
	orb.shooter = self
	# The orb wears the element: frames, the light it throws down the corridor
	# (the clearest telegraph the game has), its flight voice and its impact.
	orb.frame_a = orb_frame_a
	orb.frame_b = orb_frame_b
	orb.glow_color = element_glow
	orb.glow_energy = element_glow_energy
	orb.flight_sound = orb_flight
	orb.impact_sounds = orb_impacts
	if ember:
		orb.dot_kind = "Ember"
	orb.direction = (t.global_position - from).normalized()
	orb.position = from + orb.direction * 0.8
	get_parent().add_child.call_deferred(orb)
	# The launch. Without it the cast reads as a thing that ARRIVED rather than
	# a thing someone DID (creature-polish.md's outstanding wizard item).
	Sfx.play_at(cast_sound, global_position, -4.0)


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


func alert(against: PhysicsBody3D = null) -> void:
	# Woken by a nearby kin's shout: snap awake, sting, and pile in. `against`
	# is set when the shout came from an INFIGHT — then the neighbours turn on
	# the AGGRESSOR rather than the player. A grudge stays its own; only an
	# idle caster adopts a target from the shout.
	if noticed:
		return
	noticed = true
	if target == null:
		target = against if is_instance_valid(against) else player
	aggro_timer = AGGRO_TIME
	Sfx.play_at(aggro_sounds[randi_range(0, aggro_sounds.size() - 1)],
			global_position, -4.0)


func take_damage(amount: int, push_dir: Vector3, attacker: PhysicsBody3D = null) -> void:
	if dead:
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
	# The corpse stays: crumpled robes where the wizard fell.
	dead = true
	Sfx.play_at(DEATH_SOUND, global_position, -3.0)
	_stop_cast_glow()
	step_sound.stop()
	if by_player:
		RunState.record_kill(kill_label())
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	sprite.flip_h = false
	sprite.texture = dead_texture
	sprite.modulate = Color.WHITE
	velocity = Vector3.ZERO
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
