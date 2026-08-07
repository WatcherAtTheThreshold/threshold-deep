extends CharacterBody3D

## The amalgam (docs/structure.md): assembled from the corpses the
## player created. Fights with both verbs — skeleton rush and wizard
## telegraphed volley — alternating so no single rhythm works.
##
## THREE of them rise, one per necromancer colour, and each inherits its
## element's fight style straight from wizard.gd: blue is the baseline, red
## trades power for tempo, brown trades tempo for weight. Same enum + const
## block + `_apply_element()` shape as the necromancers, so the two files read
## the same way and a fourth element is a block and an arm in both.
## The dungeon sets `element` BEFORE add_child; `_ready()` does the node work.
enum Element { BLUE, RED, BROWN }

const FRONT_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_front1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_front2.png"),
]
const SIDE_FRAMES: Array[Texture2D] = [  # drawn facing left; flipped for right
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_side1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_side2.png"),
]
const BACK_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_back1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_back2.png"),
]
const ATTACK_FRAMES: Array[Texture2D] = [  # windup (charge), release (recover)
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_attack1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_attack2.png"),
]
const DEAD_TEXTURE := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_dead.png")
const ORB_SCENE := preload("res://scenes/orb.tscn")
const ORB_FRAME_1 := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_orb1.png")
const ORB_FRAME_2 := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_orb2.png")
const ORB_IMPACTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/Skeletal_wizard_orb_hit1.ogg"),
	preload("res://assets/audio/sfx/enemies/Skeletal_wizard_orb_hit2.ogg"),
	preload("res://assets/audio/sfx/enemies/Skeletal_wizard_orb_hit3.ogg"),
]
const TAKE_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/skeletal_wizard_take_hit1.ogg"),
	preload("res://assets/audio/sfx/enemies/skeletal_wizard_take_hit2.ogg"),
	preload("res://assets/audio/sfx/enemies/skeletal_wizard_take_hit3.ogg"),
]
const WALK_FRAME_TIME := 0.28
const DEATH_SOUND := preload("res://assets/audio/sfx/enemies/skeletal_wizard_death.ogg")
const ROAR_SOUND := preload("res://assets/audio/sfx/enemies/skeletal_wizard_roar.ogg")
const ROAR_TEX := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_roar1.png")
const ROAR_TIME := 1.0  # the rise: reared up and bellowing before the hunt
const RISE_HEIGHT := 1.6  # how far it heaves up out of the pile during the roar
const FRONT_TAKEHIT: Array[Texture2D] = [  # front-only; it always faces you
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_front_takehit1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_front_takehit2.png"),
]
const HIT_FRAME_TIME := 0.12  # per take-hit frame; two = one flinch

const RUSH_TIME := 4.0
const RUSH_SPEED := 3.0
const MELEE_RANGE := 1.7
const MELEE_DAMAGE := 4
const MELEE_COOLDOWN := 1.0
const CHARGE_TIME := 0.55
const VOLLEY_SIZE := 3
const VOLLEY_SPREAD := 0.28
const CAST_RECOVER := 0.6
const ORB_DAMAGE := 2  # half-heart units; orb.gd's own default, named here

# --- RED: the fireball amalgam ---------------------------------------------
# Same trade its necromancer makes — tempo over power. Rushes harder, breaks to
# cast sooner, winds up shorter, and its orbs arrive faster. Its bite is the
# Ember it leaves on you, not the impact.
const RED_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_front1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_front2.png"),
]
const RED_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_side1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_side2.png"),
]
const RED_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_back1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_back2.png"),
]
const RED_ATTACK: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_attack1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_attack2.png"),
]
const RED_TAKEHIT: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_front_takehit1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_front_takehit2.png"),
]
const RED_DEAD := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_dead.png")
const RED_ROAR := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_roar1.png")
const RED_ORB_A := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_orb1.png")
const RED_ORB_B := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_red/skeletal_wizard_red_orb2.png")
const RED_RUSH_TIME := 3.0
const RED_RUSH_SPEED := 3.8
const RED_CHARGE_TIME := 0.38
const RED_CAST_RECOVER := 0.45
const RED_MELEE_DAMAGE := 4
const RED_ORB_SPEED := 1.25
const RED_GLOW := Color(1.0, 0.45, 0.15)

# --- BROWN: the rubble amalgam ---------------------------------------------
# Power over tempo, and the same Pillar-3 bargain the brown necromancer makes:
# it hits for 6 in melee and 3 an orb, so it telegraphs nearly twice as long,
# lumbers, and lobs slowly. The long wind-up is what makes the weight fair.
const BROWN_FRONT: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_front1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_front2.png"),
]
const BROWN_SIDE: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_side1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_side2.png"),
]
const BROWN_BACK: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_back1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_back2.png"),
]
const BROWN_ATTACK: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_attack1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_attack2.png"),
]
const BROWN_TAKEHIT: Array[Texture2D] = [
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_front_takehit1.png"),
	preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_front_takehit2.png"),
]
const BROWN_DEAD := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_dead.png")
const BROWN_ROAR := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_roar1.png")
const BROWN_ORB_A := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_orb1.png")
const BROWN_ORB_B := preload("res://assets/sprites/skeletal_wizard/skeletal_wizard_brown/skeletal_wizard_brown_orb2.png")
const BROWN_RUSH_TIME := 5.0
const BROWN_RUSH_SPEED := 2.2
const BROWN_CHARGE_TIME := 0.85
const BROWN_CAST_RECOVER := 0.8
const BROWN_MELEE_DAMAGE := 6
const BROWN_ORB_DAMAGE := 3
const BROWN_ORB_SPEED := 0.8
const BROWN_GLOW := Color(0.85, 0.6, 0.3)

enum Mode { RUSH, CHARGE, RECOVER }

const FALL_Y := -1.5
# Live floor: the dungeon drops it below the boss chamber when the amalgam
# assembles down there, so its own safety net doesn't delete it on spawn.
var fall_y := FALL_Y

## Set by the dungeon BEFORE add_child, applied in _ready() — same order the
## necromancers use, so nothing touches a node that doesn't exist yet.
var element := Element.BLUE
# Art, blue by default; only red and brown need an arm in _apply_element().
var front_frames: Array[Texture2D] = FRONT_FRAMES
var side_frames: Array[Texture2D] = SIDE_FRAMES
var back_frames: Array[Texture2D] = BACK_FRAMES
var attack_frames: Array[Texture2D] = ATTACK_FRAMES
var takehit_frames: Array[Texture2D] = FRONT_TAKEHIT
var dead_texture: Texture2D = DEAD_TEXTURE
var roar_texture: Texture2D = ROAR_TEX
var orb_frame_a: Texture2D = ORB_FRAME_1
var orb_frame_b: Texture2D = ORB_FRAME_2
var element_glow := Color(0.45, 0.9, 1)
# Fight style, blue by default.
var rush_time := RUSH_TIME
var rush_speed := RUSH_SPEED
var charge_time := CHARGE_TIME
var cast_recover := CAST_RECOVER
var melee_damage := MELEE_DAMAGE
var orb_damage := ORB_DAMAGE
var orb_speed_scale := 1.0
var ember := false  # red's signature, exactly as on the necromancer

var health := 40
## Kept so the dungeon can tell when this one is halfway down — that's the cue
## for the next colour to rise. Set alongside `health` at spawn.
var max_health := 40
var mode := Mode.RUSH
var mode_timer := RUSH_TIME
var attack_timer := 0.0
var walk_time := 0.0
var dead := false
var facing := Vector3.FORWARD
var roar_timer := ROAR_TIME  # counts down through the rise-roar freeze
var _rise_stand_y := 0.0  # the height it settles at once risen
var _rise_start_y := 0.0  # sunk into the pile at spawn, rises to _rise_stand_y
var hit_anim := 0.0  # counts down through the take-hit flinch

@onready var sprite: Sprite3D = $Sprite
@onready var cast_glow: OmniLight3D = $CastGlow
@onready var step_sound: AudioStreamPlayer3D = $StepSound
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	_apply_element()
	# It heaves up out of the pile of your dead with a bellow — the rise.
	Sfx.play_at(ROAR_SOUND, global_position, -2.0)
	_rise_stand_y = global_position.y
	_rise_start_y = _rise_stand_y - RISE_HEIGHT
	global_position.y = _rise_start_y  # start sunk; the roar heaves it up


func _apply_element() -> void:
	# Blue's values are already the defaults, so only a non-blue element needs
	# an arm here — the same shape as wizard.gd's.
	match element:
		Element.RED:
			front_frames = RED_FRONT
			side_frames = RED_SIDE
			back_frames = RED_BACK
			attack_frames = RED_ATTACK
			takehit_frames = RED_TAKEHIT
			dead_texture = RED_DEAD
			roar_texture = RED_ROAR
			orb_frame_a = RED_ORB_A
			orb_frame_b = RED_ORB_B
			element_glow = RED_GLOW
			ember = true
			rush_time = RED_RUSH_TIME
			rush_speed = RED_RUSH_SPEED
			charge_time = RED_CHARGE_TIME
			cast_recover = RED_CAST_RECOVER
			melee_damage = RED_MELEE_DAMAGE
			orb_speed_scale = RED_ORB_SPEED
		Element.BROWN:
			front_frames = BROWN_FRONT
			side_frames = BROWN_SIDE
			back_frames = BROWN_BACK
			attack_frames = BROWN_ATTACK
			takehit_frames = BROWN_TAKEHIT
			dead_texture = BROWN_DEAD
			roar_texture = BROWN_ROAR
			orb_frame_a = BROWN_ORB_A
			orb_frame_b = BROWN_ORB_B
			element_glow = BROWN_GLOW
			rush_time = BROWN_RUSH_TIME
			rush_speed = BROWN_RUSH_SPEED
			charge_time = BROWN_CHARGE_TIME
			cast_recover = BROWN_CAST_RECOVER
			melee_damage = BROWN_MELEE_DAMAGE
			orb_damage = BROWN_ORB_DAMAGE
			orb_speed_scale = BROWN_ORB_SPEED
	# The wind-up light wears the colour, same reason the necromancers do: a
	# red amalgam charging under a blue glow lies about what's coming.
	cast_glow.light_color = element_glow
	mode_timer = rush_time


func _floor_ahead(dir: Vector3) -> bool:
	# The amalgam has no stagger to skid on, so this probe alone
	# keeps it out of the shafts.
	var probe := global_position + dir * 0.7
	var query := PhysicsRayQueryParameters3D.create(
		probe, probe + Vector3.DOWN * 3.0, 1, [get_rid()])
	query.hit_from_inside = true
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _physics_process(delta: float) -> void:
	if dead:
		return
	if global_position.y < fall_y:
		# Safety net only — the probe should make this unreachable.
		queue_free()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	attack_timer = maxf(attack_timer - delta, 0.0)
	hit_anim = maxf(hit_anim - delta, 0.0)
	mode_timer -= delta

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	# It was built from things that saw you: it always faces you.
	if dist > 0.01:
		facing = to_player.normalized()

	if roar_timer > 0.0:
		# The rise: it heaves up out of the pile, reared up and bellowing
		# before the hunt. Drive Y by hand (ease-out) so gravity can't slam
		# it back down mid-rise.
		roar_timer -= delta
		var rise_t := clampf(1.0 - roar_timer / ROAR_TIME, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - rise_t, 3.0)
		global_position.y = lerpf(_rise_start_y, _rise_stand_y, eased)
		velocity = Vector3.ZERO
		sprite.flip_h = false
		sprite.texture = roar_texture
		return

	if mode == Mode.RUSH:
		# The skeleton verb. It knows where you are — it was built
		# from things that saw you.
		if dist > MELEE_RANGE:
			var dir := to_player.normalized()
			if _floor_ahead(dir):
				velocity.x = dir.x * rush_speed
				velocity.z = dir.z * rush_speed
			else:
				# It was built from things that fell. Never again.
				velocity.x = 0.0
				velocity.z = 0.0
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if attack_timer == 0.0:
				attack_timer = MELEE_COOLDOWN
				player.take_damage(melee_damage, to_player.normalized(), self)
		if mode_timer <= 0.0:
			mode = Mode.CHARGE
			mode_timer = charge_time
			velocity.x = 0.0
			velocity.z = 0.0
			cast_glow.light_energy = 0.3
			create_tween().tween_property(cast_glow, "light_energy", 1.8, charge_time)
	elif mode == Mode.CHARGE:
		# The wizard verb: rooted, glowing, then the volley.
		velocity.x = 0.0
		velocity.z = 0.0
		if mode_timer <= 0.0:
			cast_glow.light_energy = 0.0
			_fire_volley()
			mode = Mode.RECOVER
			mode_timer = cast_recover
	else:
		velocity.x = move_toward(velocity.x, 0.0, rush_speed)
		velocity.z = move_toward(velocity.z, 0.0, rush_speed)
		if mode_timer <= 0.0:
			mode = Mode.RUSH
			mode_timer = rush_time

	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if moving:
		walk_time += delta
	if hit_anim > 0.0:
		# A hit-flinch that doesn't stall the boss's momentum (no stagger).
		sprite.flip_h = false
		sprite.texture = takehit_frames[0 if hit_anim > HIT_FRAME_TIME else 1]
	elif mode == Mode.CHARGE:
		# The drawn telegraph: windup while rooted, glow swelling.
		sprite.flip_h = false
		sprite.texture = attack_frames[0]
	elif mode == Mode.RECOVER:
		sprite.flip_h = false
		sprite.texture = attack_frames[1]
	else:
		_update_view(int(walk_time / WALK_FRAME_TIME) % 2 if moving else 0)
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


func _update_view(frame: int) -> void:
	# Four-way billboard: mostly the front, since it always faces the
	# player — the sides earn their keep when you strafe its rush.
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


func _fire_volley() -> void:
	var from := global_position + Vector3.UP * 0.6
	var base_dir := (player.global_position - from).normalized()
	for i in VOLLEY_SIZE:
		var dir := base_dir.rotated(Vector3.UP, (i - 1) * VOLLEY_SPREAD)
		var orb := ORB_SCENE.instantiate()
		orb.shooter = self
		orb.frame_a = orb_frame_a
		orb.frame_b = orb_frame_b
		orb.impact_sounds = ORB_IMPACTS
		# The element's weight and its light, same as the necromancer's orb.
		orb.damage = orb_damage
		orb.speed_scale = orb_speed_scale
		orb.glow_color = element_glow
		if ember:
			orb.dot_kind = "Ember"
		orb.direction = dir
		orb.position = from + dir * 1.0
		get_parent().add_child.call_deferred(orb)


func kill_label() -> String:
	# The death report names which one took you — the fiction, like the
	# necromancers' "Necromancer" / "Red Necromancer".
	match element:
		Element.RED:
			return "the Ember Amalgam"
		Element.BROWN:
			return "the Rubble Amalgam"
		_:
			return "the Skeletal Wizard"


func setup(_depth: int) -> void:
	pass


func take_damage(amount: int, push_dir: Vector3, attacker: PhysicsBody3D = null) -> void:
	if dead:
		return
	health -= amount
	Sfx.play_at(TAKE_HIT_SOUNDS[randi_range(0, TAKE_HIT_SOUNDS.size() - 1)],
			global_position, -4.0)
	velocity += push_dir * 2.0  # too heavy to shove far
	hit_anim = HIT_FRAME_TIME * 2.0
	sprite.modulate = Color(1.0, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)
	if health <= 0:
		_die(attacker == null or attacker is Player)


func _die(by_player: bool) -> void:
	# It falls apart — you walk out through the wreckage of the
	# fight you had twice.
	dead = true
	step_sound.stop()
	Sfx.play_at(DEATH_SOUND, global_position, -2.0)
	cast_glow.light_energy = 0.0
	if by_player:
		RunState.record_kill(kill_label())
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	sprite.modulate = Color.WHITE
	sprite.flip_h = false
	sprite.texture = dead_texture
