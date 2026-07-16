extends CharacterBody3D

## The amalgam (docs/structure.md): assembled from the corpses the
## player created. Fights with both verbs — skeleton rush and wizard
## telegraphed volley — alternating so no single rhythm works.

const FRAME_A := preload("res://assets/sprites/skeletal-wizard/skeletal-wizard1.png")
const FRAME_B := preload("res://assets/sprites/skeletal-wizard/skeletal-wizard2.png")
const DEAD_TEXTURE := preload("res://assets/sprites/skeletal-wizard/skeletal-wizard-dead.png")
const ORB_SCENE := preload("res://scenes/orb.tscn")
const ORB_FRAME_1 := preload("res://assets/sprites/skeletal-wizard/skeletal_wizard_orb1.png")
const ORB_FRAME_2 := preload("res://assets/sprites/skeletal-wizard/skeletal_wizard_orb2.png")
const ORB_IMPACTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/Skeletal_wizard_orb_hit1.wav"),
	preload("res://assets/audio/sfx/enemies/Skeletal_wizard_orb_hit2.wav"),
	preload("res://assets/audio/sfx/enemies/Skeletal_wizard_orb_hit3.wav"),
]
const TAKE_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/skeletal_wizard_take_hit1.wav"),
	preload("res://assets/audio/sfx/enemies/skeletal_wizard_take_hit2.wav"),
	preload("res://assets/audio/sfx/enemies/skeletal_wizard_take_hit3.wav"),
]
const WALK_FRAME_TIME := 0.28

const RUSH_TIME := 4.0
const RUSH_SPEED := 3.0
const MELEE_RANGE := 1.7
const MELEE_DAMAGE := 4
const MELEE_COOLDOWN := 1.0
const CHARGE_TIME := 0.55
const VOLLEY_SIZE := 3
const VOLLEY_SPREAD := 0.28
const CAST_RECOVER := 0.6

enum Mode { RUSH, CHARGE, RECOVER }

var health := 40
var mode := Mode.RUSH
var mode_timer := RUSH_TIME
var attack_timer := 0.0
var walk_time := 0.0
var dead := false

@onready var sprite: Sprite3D = $Sprite
@onready var cast_glow: OmniLight3D = $CastGlow
@onready var step_sound: AudioStreamPlayer3D = $StepSound
@onready var player: Player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	attack_timer = maxf(attack_timer - delta, 0.0)
	mode_timer -= delta

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if mode == Mode.RUSH:
		# The skeleton verb. It knows where you are — it was built
		# from things that saw you.
		if dist > MELEE_RANGE:
			var dir := to_player.normalized()
			velocity.x = dir.x * RUSH_SPEED
			velocity.z = dir.z * RUSH_SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if attack_timer == 0.0:
				attack_timer = MELEE_COOLDOWN
				player.take_damage(MELEE_DAMAGE, to_player.normalized(), self)
		if mode_timer <= 0.0:
			mode = Mode.CHARGE
			mode_timer = CHARGE_TIME
			velocity.x = 0.0
			velocity.z = 0.0
			cast_glow.light_energy = 0.3
			create_tween().tween_property(cast_glow, "light_energy", 1.8, CHARGE_TIME)
	elif mode == Mode.CHARGE:
		# The wizard verb: rooted, glowing, then the volley.
		velocity.x = 0.0
		velocity.z = 0.0
		if mode_timer <= 0.0:
			cast_glow.light_energy = 0.0
			_fire_volley()
			mode = Mode.RECOVER
			mode_timer = CAST_RECOVER
	else:
		velocity.x = move_toward(velocity.x, 0.0, RUSH_SPEED)
		velocity.z = move_toward(velocity.z, 0.0, RUSH_SPEED)
		if mode_timer <= 0.0:
			mode = Mode.RUSH
			mode_timer = RUSH_TIME

	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if moving:
		walk_time += delta
		sprite.texture = FRAME_A if int(walk_time / WALK_FRAME_TIME) % 2 == 0 else FRAME_B
	else:
		sprite.texture = FRAME_A
	if moving and not step_sound.playing:
		step_sound.play()
	elif not moving and step_sound.playing:
		step_sound.stop()


func _fire_volley() -> void:
	var from := global_position + Vector3.UP * 0.6
	var base_dir := (player.global_position - from).normalized()
	for i in VOLLEY_SIZE:
		var dir := base_dir.rotated(Vector3.UP, (i - 1) * VOLLEY_SPREAD)
		var orb := ORB_SCENE.instantiate()
		orb.shooter = self
		orb.frame_a = ORB_FRAME_1
		orb.frame_b = ORB_FRAME_2
		orb.impact_sounds = ORB_IMPACTS
		orb.direction = dir
		orb.position = from + dir * 1.0
		get_parent().add_child.call_deferred(orb)


func kill_label() -> String:
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
	sprite.modulate = Color(1.0, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)
	if health <= 0:
		_die(attacker == null or attacker is Player)


func _die(by_player: bool) -> void:
	# It falls apart — you walk out through the wreckage of the
	# fight you had twice.
	dead = true
	step_sound.stop()
	cast_glow.light_energy = 0.0
	if by_player:
		RunState.record_kill(kill_label())
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	sprite.modulate = Color.WHITE
	sprite.texture = DEAD_TEXTURE
