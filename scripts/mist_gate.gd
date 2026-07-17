extends Area3D

## A pale mist doorway standing at the stage's edge: walk through to
## cross into the next stage of this world. Worlds are places — only
## the boss floor has a true downward hatch.

const MIST_SHADER := preload("res://assets/shaders/mist.gdshader")
const MIST_TEXTURE := preload("res://assets/textures/mist-overlay.png")
const CROSS_SOUND := preload("res://assets/audio/sfx/environment/item_room_mist_door.wav")
const PALE := Color(0.88, 0.92, 1.0, 0.5)

var used := false

@onready var visual: MeshInstance3D = $Visual


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2.2, 3.4)
	var material := ShaderMaterial.new()
	material.shader = MIST_SHADER
	material.set_shader_parameter("mist_tex", MIST_TEXTURE)
	material.set_shader_parameter("tiles", 1.1)
	material.set_shader_parameter("feather", 0.18)
	material.set_shader_parameter("tint", PALE)
	quad.material = material
	visual.mesh = quad


func _physics_process(_delta: float) -> void:
	# Polled, not signalled: a gate near a corner can be grazed from
	# alongside the wall, and a rejected body_entered would never
	# re-fire once the player walked around to the front. Only a body
	# squarely before the doorway crosses.
	if used:
		return
	for body in get_overlapping_bodies():
		if body is Player and _in_front(body):
			used = true
			Sfx.play_ui(CROSS_SOUND, -10.0)
			# The gate's front (+Z) faces the room; -Z is through the wall.
			body.start_gate_crossing(-global_transform.basis.z)
			return


func _in_front(body: Node3D) -> bool:
	var local := to_local(body.global_position)
	return absf(local.x) < 0.8 and local.z > 0.1
