extends Area3D

const FRAME_A := preload("res://assets/sprites/wizard/wizard_orb1.png")
const FRAME_B := preload("res://assets/sprites/wizard/wizard_orb2.png")
const WIZARD_IMPACTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/wizard_orb_hit1.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_orb_hit2.ogg"),
	preload("res://assets/audio/sfx/enemies/wizard_orb_hit3.ogg"),
]
const WIZARD_FLIGHT := preload("res://assets/audio/sfx/enemies/wizard_orb_flight1.ogg")
# The blue wizard's bolt: the values that used to be baked into orb.tscn's
# Glow and FlightSound nodes. They live here now so a variant can override
# them like it overrides frames — and so blue keeps behaving exactly as it did.
const WIZARD_GLOW := Color(0.45, 0.9, 1)
const WIZARD_GLOW_ENERGY := 1.2  # orb.tscn's Glow value; a magic bolt burns bright
const SPEED := 6.0
const SPLASH_RANGE := 2.0
const LIFETIME := 4.0
const FRAME_TIME := 0.15

# Overridable per shooter (the Skeletal Wizard fires its own frames).
var frame_a: Texture2D = FRAME_A
var frame_b: Texture2D = FRAME_B
var impact_sounds: Array[AudioStream] = WIZARD_IMPACTS
# The light an orb throws is the game's clearest telegraph — in a dungeon lit
# only by your torch, a coloured glow travelling at you IS the readable threat
# (Pillar 3: light equals meaning). An elemental variant MUST set this or its
# fireball will paint the walls blue.
var glow_color: Color = WIZARD_GLOW
# How hard it burns. A thrown rock is not magical and wants far less than a
# bolt — but NOT zero: the dungeon is lit by your torch alone, so a projectile
# that throws no light is a projectile you cannot see coming, and Pillar 3
# says you can always tell what is about to hurt you. Dim it, never kill it.
var glow_energy := WIZARD_GLOW_ENERGY
var flight_sound: AudioStream = WIZARD_FLIGHT
# Non-empty: the impact also attaches this Dot (the red necromancer's "Ember").
# Creature victims only — see the note in _on_body_entered about the player.
var dot_kind := ""
var damage := 2  # half-heart units: a full heart per orb
var speed_scale := 1.0  # the Hasty Little Stone quickens player orbs
var splash := false  # Wide Swing: impacts spread to nearby enemies
var direction := Vector3.FORWARD
var shooter: PhysicsBody3D = null
var time := 0.0

@onready var sprite: Sprite3D = $Sprite
@onready var glow: OmniLight3D = $Glow
@onready var flight: AudioStreamPlayer3D = $FlightSound


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Apply the per-shooter look and voice. This runs AFTER the caster has set
	# its overrides (instantiate → set vars → add_child → _ready), which is why
	# FlightSound's `autoplay` had to come off the scene: children ready before
	# their parent, so autoplay would have started the DEFAULT stream a beat
	# early, and assigning `stream` to a playing player stops it dead.
	glow.light_color = glow_color
	glow.light_energy = glow_energy
	flight.stream = flight_sound
	flight.play()


func _physics_process(delta: float) -> void:
	time += delta
	if time > LIFETIME:
		queue_free()
		return
	position += direction * SPEED * speed_scale * delta
	sprite.texture = frame_a if int(time / FRAME_TIME) % 2 == 0 else frame_b
	# Keep the flight sizzle going for as long as the orb lives.
	if not flight.playing:
		flight.play()


func _on_body_entered(body: Node3D) -> void:
	if body == shooter:
		return
	# The caster can die while the orb is still in flight — a freed shooter
	# passed to take_damage crashes, so validate once and credit only while
	# it's alive (a dead caster has nothing to infight or record anyway).
	var credit: PhysicsBody3D = shooter if is_instance_valid(shooter) else null
	Sfx.play_at(impact_sounds[randi_range(0, impact_sounds.size() - 1)],
			global_position, -4.0)
	if body is Player:
		# Credit the caster.
		body.take_damage(damage, direction, credit)
	elif body.is_in_group("enemies"):
		# Friendly fire: a stray orb starts an infight. Player orbs
		# (the staff) count toward damage dealt.
		body.take_damage(damage, direction, credit)
		if credit is Player:
			RunState.record_damage_dealt(damage)
			credit.apply_dots(body)
		if dot_kind != "" and is_instance_valid(credit):
			# A red orb burns what it hits, and because Dot ticks credit the
			# caster, the victim turns on it — the same infighting rule the
			# slime's caustic touch runs on. Creatures only, deliberately: on
			# the PLAYER a Dot tick goes through take_damage, where i-frames
			# would swallow burns at random. That path needs its own
			# take_burn(), mirroring take_poison. See docs/necromancers.md.
			Dot.attach(body, credit, dot_kind)
	elif body is GridMap:
		# Orbs splinter wood — anyone's orbs. Each point of damage
		# counts as a hit against the wall.
		var scene := get_tree().current_scene
		if scene != null and scene.has_method("damage_wall"):
			scene.damage_wall(global_position + direction * 0.4, -direction, damage)
	if splash:
		# Wide Swing: the burst spreads from the point of impact to
		# everyone nearby but the caster and whoever was hit direct.
		for e: Node3D in get_tree().get_nodes_in_group("enemies"):
			if e == body or e == shooter or not is_instance_valid(e):
				continue
			if e.global_position.distance_to(global_position) <= SPLASH_RANGE:
				e.take_damage(damage, direction, credit)
				if credit is Player:
					RunState.record_damage_dealt(damage)
					credit.apply_dots(e)
	queue_free()
