extends Node3D

## A wall of rolling mist filling a doorway cell (docs/structure.md).
## Cold/pale marks a boss room, warm gold an item room. Always
## passable until seal() — mist = commitment, the plate is the lock.
## The shader feathers the quad's edges so wonky doorways never show
## a hard cut, and scrolls the texture on its own clock.

const MIST_SHADER := preload("res://assets/shaders/mist.gdshader")
const MIST_TEXTURE := preload("res://assets/textures/mist-overlay.png")
const COLD := Color(0.72, 0.85, 1.0, 0.55)
const GOLD := Color(1.0, 0.82, 0.45, 0.6)

var gold := false
var span := 2.0  # opening width in meters — one curtain per opening
var material: ShaderMaterial
var tint := COLD

@onready var visual: MeshInstance3D = $Visual
@onready var wall_shape: CollisionShape3D = $Wall/CollisionShape3D


func _ready() -> void:
	var quad := QuadMesh.new()
	# Slightly wider than the opening: the feathered ends tuck into
	# the flanking walls.
	var width := span + 0.4
	quad.size = Vector2(width, 3.6)
	material = ShaderMaterial.new()
	material.shader = MIST_SHADER
	material.set_shader_parameter("mist_tex", MIST_TEXTURE)
	material.set_shader_parameter("tiles", width / 2.0)
	material.set_shader_parameter("feather", clampf(0.5 / width, 0.08, 0.18))
	tint = GOLD if gold else COLD
	material.set_shader_parameter("tint", tint)
	quad.material = material
	visual.mesh = quad
	var box := BoxShape3D.new()
	box.size = Vector3(span, 4.0, 0.6)
	wall_shape.shape = box
	wall_shape.disabled = true


func seal() -> void:
	wall_shape.disabled = false
	tint.a = minf(tint.a + 0.3, 0.9)
	material.set_shader_parameter("tint", tint)


func dissolve() -> void:
	wall_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_method(_set_tint_alpha, tint.a, 0.0, 1.4)
	tween.tween_callback(queue_free)


func _set_tint_alpha(a: float) -> void:
	tint.a = a
	material.set_shader_parameter("tint", tint)
