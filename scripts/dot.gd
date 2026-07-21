class_name Dot
extends Node

## A wound that keeps working: Rotstone poison and Emberstone burn
## (docs/item-plan.md, the Pillar 4 pair). Attached to a creature on
## a player hit; ticks damage credited to the attacker and tints the
## victim. Refresh over stack — re-hitting resets the clock, never
## doubles. A host that dies dotted keeps the stain on its corpse:
## the residue, until drawn residue art exists. Burns also char the
## plank underfoot each tick — fire spreads to the floor, and
## deliberate damage has the final say.

const ROT_TINT := Color(0.55, 1.0, 0.5)
const EMBER_TINT := Color(1.0, 0.55, 0.25)
const TICKS := 3

var interval := 1.2
var ticks_left := TICKS
var damage := 1
var burn := false
var tint := ROT_TINT
var attacker: CharacterBody3D = null
var clock := 0.0


static func attach(host: Node, from: CharacterBody3D, kind: String) -> void:
	var existing := host.get_node_or_null(NodePath(kind))
	if existing is Dot:
		existing.ticks_left = TICKS
		return
	var dot := Dot.new()
	dot.name = kind
	dot.burn = kind == "Ember"
	dot.tint = EMBER_TINT if dot.burn else ROT_TINT
	dot.interval = 0.8 if dot.burn else 1.2
	dot.attacker = from
	host.add_child(dot)


func _physics_process(delta: float) -> void:
	var host := get_parent()
	if host == null or not host is CharacterBody3D:
		queue_free()
		return
	if host.get("dead") == true:
		# Died festering: the corpse stays stained. That's the residue.
		_stain(host)
		queue_free()
		return
	_stain(host)
	clock += delta
	if clock < interval:
		return
	clock = 0.0
	ticks_left -= 1
	host.take_damage(damage, Vector3.ZERO, attacker)
	# Ticks hurt but never stagger — the wound works quietly.
	host.set("knock_timer", 0.0)
	if attacker is Player:
		RunState.record_damage_dealt(damage)
	if burn:
		var scene := get_tree().current_scene
		if scene != null and scene.has_method("damage_wall"):
			scene.damage_wall(host.global_position + Vector3.DOWN * 0.2,
					Vector3.UP, 1)
	if ticks_left <= 0:
		_unstain(host)
		queue_free()


func _stain(host: Node) -> void:
	var sprite := host.get_node_or_null("Sprite")
	if sprite is Sprite3D:
		sprite.modulate = tint


func _unstain(host: Node) -> void:
	var sprite := host.get_node_or_null("Sprite")
	if sprite is Sprite3D:
		# Green mushes carry a base tint of their own; restore it,
		# not plain white.
		var base: Variant = host.get("base_tint")
		sprite.modulate = base if base is Color else Color.WHITE
