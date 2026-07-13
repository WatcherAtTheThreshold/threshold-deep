extends Node3D

## A wall of rolling mist filling a doorway cell (docs/structure.md).
## Cold/pale marks a boss room, warm gold an item room. Always
## passable until seal() — mist = commitment, the plate is the lock.

const MIST_TEXTURE := preload("res://assets/textures/mist-overlay.png")
const COLD := Color(0.72, 0.85, 1.0, 0.55)
const GOLD := Color(1.0, 0.82, 0.45, 0.6)

var gold := false
var material: StandardMaterial3D

@onready var visual: MeshInstance3D = $Visual
@onready var wall_shape: CollisionShape3D = $Wall/CollisionShape3D


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 3.6)
	material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = MIST_TEXTURE
	material.albedo_color = GOLD if gold else COLD
	quad.material = material
	visual.mesh = quad
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 4.0, 0.6)
	wall_shape.shape = box
	wall_shape.disabled = true


func _process(delta: float) -> void:
	# The roll: a slow drift of the texture through the doorway.
	material.uv1_offset += Vector2(0.03, 0.05) * delta


func seal() -> void:
	wall_shape.disabled = false
	material.albedo_color.a = minf(material.albedo_color.a + 0.3, 0.9)


func dissolve() -> void:
	wall_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 1.4)
	tween.tween_callback(queue_free)
