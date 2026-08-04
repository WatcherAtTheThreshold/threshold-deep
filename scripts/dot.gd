class_name Dot
extends Node

## A wound that keeps working: Rotstone poison and Emberstone burn
## (docs/item-plan.md, the Pillar 4 pair). Attached to a creature on
## a player hit; ticks damage credited to the attacker and tints the
## victim. Refresh over stack — re-hitting resets the clock, never
## doubles. A host that dies dotted keeps the stain on its corpse:
## the residue. Burns also char the plank underfoot each tick — fire
## spreads to the floor, and deliberate damage has the final say.
##
## VISUALS come in two channels that read together: the host's own sprite is
## TINTED (the body reacting), and a small overlay billboard plays the effect
## on top (the fire/rot itself). The overlay lives here rather than on any
## creature, so the whole bestiary gets it for free — the same leverage the
## enemy creak takes from StepSound.

const ROT_TINT := Color(0.55, 1.0, 0.5)
const EMBER_TINT := Color(1.0, 0.55, 0.25)
const TICKS := 3

# --- Overlay effect -------------------------------------------------------
# Five phases per kind, named after the Dot's own `kind` string so the set is
# derivable: catch (the flare, replayed on every re-application), two loop
# frames, out (dissipation), residue (what a corpse keeps).
enum F { CATCH, LOOP1, LOOP2, OUT, RESIDUE }
const FRAMES := {
	"Ember": [
		preload("res://assets/sprites/dot/dot_ember_catch1.png"),
		preload("res://assets/sprites/dot/dot_ember_loop1.png"),
		preload("res://assets/sprites/dot/dot_ember_loop2.png"),
		preload("res://assets/sprites/dot/dot_ember_out1.png"),
		preload("res://assets/sprites/dot/dot_ember_residue1.png"),
	],
	"Rot": [
		preload("res://assets/sprites/dot/dot_rot_catch1.png"),
		preload("res://assets/sprites/dot/dot_rot_loop1.png"),
		preload("res://assets/sprites/dot/dot_rot_loop2.png"),
		preload("res://assets/sprites/dot/dot_rot_out1.png"),
		preload("res://assets/sprites/dot/dot_rot_residue1.png"),
	],
}
const FX_CATCH_TIME := 0.22   # how long the flare holds before the loop
const FX_LOOP_TIME := 0.18    # per loop frame
const FX_OUT_TIME := 0.5      # dissipation fade once the wound closes
const FX_HEIGHT := 0.8        # of the HOST's sprite height, so scale follows the body
const FX_RESIDUE_ALPHA := 0.7
# A burning body is visible in the dark — light equals meaning, same rule the
# orbs follow. Rot gets no light; that asymmetry is itself readable.
const EMBER_LIGHT := Color(1.0, 0.55, 0.2)
const EMBER_LIGHT_ENERGY := 0.9
const EMBER_LIGHT_RANGE := 2.6

var interval := 1.2
var ticks_left := TICKS
var damage := 1
var burn := false
var kind := "Rot"
var tint := ROT_TINT
var attacker: CharacterBody3D = null
var clock := 0.0
var fx: Sprite3D = null       # the overlay; parented to the HOST so it follows the body
var glow: OmniLight3D = null
var fx_clock := 0.0
var catching := 0.0           # counts down through the catch flare


static func attach(host: Node, from: CharacterBody3D, kind_name: String) -> void:
	var existing := host.get_node_or_null(NodePath(kind_name))
	if existing is Dot:
		(existing as Dot).refresh()
		return
	var dot := Dot.new()
	dot.name = kind_name
	dot.kind = kind_name
	dot.burn = kind_name == "Ember"
	dot.tint = EMBER_TINT if dot.burn else ROT_TINT
	dot.interval = 0.8 if dot.burn else 1.2
	dot.attacker = from
	host.add_child(dot)


func refresh() -> void:
	# Re-applied: reset the clock and re-flare. The wound never stacks, but a
	# second hit should still READ as a second hit.
	ticks_left = TICKS
	catching = FX_CATCH_TIME


func _ready() -> void:
	_build_fx()


func _build_fx() -> void:
	var host := get_parent()
	if host == null or not host is Node3D or not FRAMES.has(kind):
		return
	var host_sprite := host.get_node_or_null("Sprite") as Sprite3D
	fx = Sprite3D.new()
	fx.name = kind + "FX"
	fx.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	fx.shaded = false  # fire lights itself; an unlit dungeon would swallow it
	fx.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	fx.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	fx.pixel_size = 0.03125
	fx.texture = FRAMES[kind][F.CATCH]
	if host_sprite != null:
		fx.position = host_sprite.position
		# Two coplanar billboards z-fight. render_priority is the fix —
		# nudging it forward in space breaks the moment you walk around it.
		fx.render_priority = host_sprite.render_priority + 1
		if host_sprite.texture != null:
			# Scale to the BODY: a mini-mush must not wear a bonfire.
			var h := host_sprite.texture.get_height() * host_sprite.pixel_size
			fx.scale = Vector3.ONE * maxf(h * FX_HEIGHT, 0.2)
	(host as Node3D).add_child(fx)
	if burn:
		# Sibling of the overlay, not a child — the overlay is scaled per host
		# and a light's range should not scale with the body it sits on.
		glow = OmniLight3D.new()
		glow.light_color = EMBER_LIGHT
		glow.light_energy = EMBER_LIGHT_ENERGY
		glow.omni_range = EMBER_LIGHT_RANGE
		glow.position = fx.position
		(host as Node3D).add_child(glow)
	catching = FX_CATCH_TIME


func _animate_fx(delta: float) -> void:
	if fx == null:
		return
	if catching > 0.0:
		catching -= delta
		fx.texture = FRAMES[kind][F.CATCH]
		return
	fx_clock += delta
	fx.texture = FRAMES[kind][
			F.LOOP1 if int(fx_clock / FX_LOOP_TIME) % 2 == 0 else F.LOOP2]


func _release_fx() -> void:
	# The wound closes and this node dies now — but the effect shouldn't pop.
	# The overlay is parented to the HOST, so it outlives us: hand it the out
	# frame and a short fade, and let it free itself.
	if glow != null:
		glow.queue_free()
		glow = null
	if fx == null:
		return
	fx.texture = FRAMES[kind][F.OUT]
	var tw := fx.create_tween()
	tw.tween_property(fx, "modulate:a", 0.0, FX_OUT_TIME)
	tw.tween_callback(fx.queue_free)
	fx = null


func _settle_fx() -> void:
	# Died festering: the mark stays on the corpse, static and dulled — the
	# same residue rule the tint already follows. No fade, no light.
	if glow != null:
		glow.queue_free()
		glow = null
	if fx == null:
		return
	fx.texture = FRAMES[kind][F.RESIDUE]
	fx.modulate.a = FX_RESIDUE_ALPHA
	fx = null


func _physics_process(delta: float) -> void:
	var host := get_parent()
	if host == null or not host is CharacterBody3D:
		queue_free()
		return
	if host.get("dead") == true:
		# Died festering: the corpse stays stained. That's the residue.
		_stain(host)
		_settle_fx()
		queue_free()
		return
	_stain(host)
	_animate_fx(delta)
	clock += delta
	if clock < interval:
		return
	clock = 0.0
	ticks_left -= 1
	# The source can die mid-wound (a slime that caustic-touched this victim,
	# then got killed) — a freed attacker passed to take_damage crashes, so
	# credit it only while it's still valid; otherwise the tick is uncredited
	# (there's nothing left to infight anyway).
	var credit: CharacterBody3D = attacker if is_instance_valid(attacker) else null
	host.take_damage(damage, Vector3.ZERO, credit)
	# Ticks hurt but never stagger — the wound works quietly.
	host.set("knock_timer", 0.0)
	if credit is Player:
		RunState.record_damage_dealt(damage)
	if burn:
		var scene := get_tree().current_scene
		if scene != null and scene.has_method("damage_wall"):
			scene.damage_wall(host.global_position + Vector3.DOWN * 0.2,
					Vector3.UP, 1)
	if ticks_left <= 0:
		_unstain(host)
		_release_fx()
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
