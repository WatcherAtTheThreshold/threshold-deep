extends Area3D

const FRAME_A := preload("res://assets/sprites/wizard_orb1.png")
const FRAME_B := preload("res://assets/sprites/wizard_orb2.png")
const WIZARD_IMPACTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/enemies/wizard_orb_hit1.wav"),
	preload("res://assets/audio/sfx/enemies/wizard_orb_hit2.wav"),
	preload("res://assets/audio/sfx/enemies/wizard_orb_hit3.wav"),
]
const SPEED := 6.0
const SPLASH_RANGE := 2.0
const LIFETIME := 4.0
const FRAME_TIME := 0.15

# Overridable per shooter (the Skeletal Wizard fires its own frames).
var frame_a: Texture2D = FRAME_A
var frame_b: Texture2D = FRAME_B
var impact_sounds: Array[AudioStream] = WIZARD_IMPACTS
var damage := 2  # half-heart units: a full heart per orb
var speed_scale := 1.0  # the Hasty Little Stone quickens player orbs
var splash := false  # Wide Swing: impacts spread to nearby enemies
var direction := Vector3.FORWARD
var shooter: PhysicsBody3D = null
var time := 0.0

@onready var sprite: Sprite3D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	time += delta
	if time > LIFETIME:
		queue_free()
		return
	position += direction * SPEED * speed_scale * delta
	sprite.texture = frame_a if int(time / FRAME_TIME) % 2 == 0 else frame_b
	# Keep the flight sizzle going for as long as the orb lives.
	if not $FlightSound.playing:
		$FlightSound.play()


func _on_body_entered(body: Node3D) -> void:
	if body == shooter:
		return
	Sfx.play_at(impact_sounds[randi_range(0, impact_sounds.size() - 1)],
			global_position, -4.0)
	if body is Player:
		# Credit the caster.
		body.take_damage(damage, direction, shooter if is_instance_valid(shooter) else null)
	elif body.is_in_group("enemies"):
		# Friendly fire: a stray orb starts an infight. Player orbs
		# (the staff) count toward damage dealt.
		body.take_damage(damage, direction, shooter)
		if shooter is Player:
			RunState.record_damage_dealt(damage)
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
				e.take_damage(damage, direction, shooter)
				if shooter is Player:
					RunState.record_damage_dealt(damage)
	queue_free()
