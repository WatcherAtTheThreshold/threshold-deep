extends Node3D

## A specimen in a cage — docs/stations.md. Decoration that answers back.
##
## DELIBERATELY NOT the creature scenes. mush.gd splits at <=4 HP and hunts
## visible kin to fuse with; skeleton.gd chases, lunges and can rise restless.
## A caged copy of either would spend its whole life pathing into the bars.
## This has no AI at all: it breathes, it notices you, it can be killed through
## the bars, and it leaves a corpse. Node3D, not a body — it never moves.
##
## WHY IT JOINS "enemies": that is the only thing that makes player melee find
## it. The sweep is a group scan flattened in Y (`to.y = 0.0` in player.gd)
## with no raycast and no line-of-sight test, which is exactly why hitting it
## THROUGH the bars works for free and why height doesn't matter.
##
## THAT MEMBERSHIP IS WHY BOSS ARENAS GET NO PROPS. A living thing inside the
## arena bounds keeps `_arena_has_living_enemies` returning true and the fight
## never ends — a soft-lock. dungeon.gd's `_place_structures` excludes arenas;
## CLAUDE.md carries the rule. Don't relax either.
##
## It has no `alert()`, which is safe on purpose: dungeon.gd's rally poll and
## `_alert_around` both guard with `has_method("alert")`, so a thing with no
## brain is skipped rather than crashing. Give it one only if you want a caged
## specimen to be able to shout for help, which would be a strange game.
##
## ONE SCRIPT, TWO SCENES (caged_mush / caged_skeleton) because the logic is
## identical and this header is the part that must not drift. The scenes carry
## the frames. If a third specimen wants genuinely different BEHAVIOUR, give it
## its own script rather than growing another flag here.

## The frames a scene must supply. Textures live in the scene, not in consts
## here, so the two specimens share this file — and they stay warm on the web
## build regardless, since ShaderWarm harvests them from mush.gd/skeleton.gd,
## which own the same PNGs.
@export var idle_frames: Array[Texture2D] = []
@export var aggro_frame: Texture2D
@export var hit_frames: Array[Texture2D] = []
@export var dead_frame: Texture2D
@export var hit_sounds: Array[AudioStream] = []
@export var death_sound: AudioStream

@export var label := "a caged specimen"
@export var max_health := 2
@export var hit_pitch := 1.0

## The ONE thing the two specimens disagree on. A mush corpse is drawn
## TOP-DOWN like every splat in the game and must be laid flat — billboarded,
## a top-down puddle reads as a disc standing on edge. A skeleton corpse is a
## bone pile drawn upright, and skeleton.gd deliberately leaves its billboard
## alone. Match whichever the art is.
@export var corpse_lies_flat := false

const NOTICE_RANGE := 4.0
const FRAME_TIME := 0.55
const HIT_HOLD := 0.22
const SPLAT_LIFT := 0.03  # clearance off the surface a flat corpse lands on

## `base_tint` and `knock_timer` exist for dot.gd, not for this script: Dot
## restores a host's sprite to `base_tint` rather than white, and zeroes
## `knock_timer` on a tick. A caged thing can absolutely be set on fire.
var health := 0
var dead := false
var base_tint := Color.WHITE
var knock_timer := 0.0
var noticed := false
var anim := 0.0
var hit_timer := 0.0

@onready var sprite: Sprite3D = $Sprite


func _ready() -> void:
	# Exports aren't populated at var-init time, so health is set here.
	health = max_health


func kill_label() -> String:
	return label


func _process(delta: float) -> void:
	if dead or idle_frames.is_empty():
		return
	if hit_timer > 0.0:
		# The take-hit frame owns the sprite while it runs.
		hit_timer -= delta
		return
	var body := get_tree().get_first_node_in_group("player") as Node3D
	# `huntable` drops a beat after you die, which is how the whole roster
	# stands down — a specimen still glaring at your corpse would read as the
	# game not having noticed either.
	noticed = body != null and body.get("huntable") == true \
			and global_position.distance_to(body.global_position) <= NOTICE_RANGE
	if noticed and aggro_frame != null:
		# The entire story beat, for one texture swap: it sees you, and it
		# cannot reach you.
		sprite.texture = aggro_frame
		return
	anim += delta
	sprite.texture = idle_frames[int(anim / FRAME_TIME) % idle_frames.size()]


func take_damage(amount: int, _push_dir: Vector3,
		attacker: PhysicsBody3D = null) -> void:
	# Knockback is swallowed on purpose — it's in a cage. Everything else
	# follows the house pattern so a hit here feels like a hit anywhere.
	if dead:
		return
	health -= amount
	if not hit_sounds.is_empty():
		Sfx.play_at(hit_sounds[randi() % hit_sounds.size()],
				global_position, -4.0, hit_pitch)
	if not hit_frames.is_empty():
		sprite.texture = hit_frames[randi() % hit_frames.size()]
		hit_timer = HIT_HOLD
	sprite.modulate = Color(1.0, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", base_tint, 0.25)
	if health <= 0:
		# A Dot tick passes a null attacker; anything that isn't the player
		# (an infighting creature, a slime's creep) shouldn't score.
		_die(attacker == null or attacker is Player)


func _die(by_player: bool) -> void:
	dead = true
	if death_sound != null:
		Sfx.play_at(death_sound, global_position, -3.0)
	if by_player:
		RunState.record_kill(kill_label())
	# Leaving the group is what stops melee re-hitting a corpse and what keeps
	# it out of every other group sweep — the same thing mush.gd does.
	remove_from_group("enemies")
	sprite.modulate = base_tint
	if dead_frame != null:
		sprite.texture = dead_frame
	if corpse_lies_flat:
		sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		sprite.rotation_degrees = Vector3(-90, 0, 0)
		sprite.position = Vector3(0, SPLAT_LIFT, 0)
	set_process(false)
