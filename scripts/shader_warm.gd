extends Node3D

## Pre-pays the web build's first-use costs during the title walk, buried in
## solid stone where nothing can be seen (see title.gd's header for the spot
## and why a wall doesn't stop a draw call).
##
## TWO different costs, and they need different tricks:
##
## 1. SHADER VARIANTS compile the first time a material CONFIG is drawn. The
##    four sibling nodes (Mist / Orb / Dot / Creature) cover every config the
##    dungeon uses; they just have to exist and be in frustum.
## 2. TEXTURES upload to the GPU the first time each ONE is drawn — per
##    texture, not per config. 321 sprites, and the first room plus the first
##    fight touches enough of them to produce the 3-to-23-second stutter storm
##    measured 2026-08-08. That's what this script is for.
##
## The upload happens on DRAW, not on load, so cycling means assigning one
## texture per slot per frame and letting the frame render. More slots = more
## per frame; four clears the whole roster in about 80 frames.
##
## WHERE THE LIST COMES FROM: harvested at runtime from the creature scripts'
## own constants, never hand-maintained. A second list would drift the first
## time you drew a frame and forgot this file existed. Scripts are `load()`ed
## rather than `preload()`ed on purpose — every creature declares
## `@onready var player: Player`, and a parse-time edge from here into that
## graph is exactly the "Parse Error: Busy" cycle CLAUDE.md warns about.
## Runtime load has no such edge.
##
## Directory scanning is NOT an option — it doesn't survive an export, the
## same trap the music `*_TRACKS` arrays exist to avoid. Hence explicit script
## paths, but harvested contents.

## 3. RUNTIME `load()` CALLS block the frame on a single-threaded web export
##    (`thread_support=false`). Three creature scripts load their OWN scene to
##    spawn a copy of themselves — they can't use preload without risking the
##    cycle above — so the first slime split jags. Touching the scenes here
##    puts them in ResourceLoader's cache and the in-fight load becomes a hit.
const WARM_SCENES: Array[String] = [
	"res://scenes/slime.tscn",
	"res://scenes/mush.tscn",
	"res://scenes/frogman.tscn",
]

## Add a script here when it holds textures the first minute of play will hit.
const WARM_SCRIPTS: Array[String] = [
	"res://scripts/skeleton.gd",
	"res://scripts/wizard.gd",
	"res://scripts/slime.gd",
	"res://scripts/mush.gd",
	"res://scripts/frogman.gd",
	"res://scripts/skeletal_wizard.gd",
	"res://scripts/dot.gd",
	"res://scripts/orb.gd",
	"res://scripts/viewmodel.gd",
	"res://scripts/hud.gd",
]

var queue: Array[Texture2D] = []
var seen: Dictionary = {}
var scene_index := 0
var script_index := 0
var queue_index := 0

@onready var slots: Array[Sprite3D] = [
	$Slot0, $Slot1, $Slot2, $Slot3,
]


func _process(_delta: float) -> void:
	# One blocking load per frame, in phases: scenes, then scripts, then the
	# texture cycle. All of it runs from frame one — before the click, behind
	# the black gate, where a stalled frame costs nothing at all.
	if scene_index < WARM_SCENES.size():
		load(WARM_SCENES[scene_index])
		scene_index += 1
		return
	if script_index < WARM_SCRIPTS.size():
		_harvest(WARM_SCRIPTS[script_index])
		script_index += 1
		return
	if queue_index >= queue.size():
		set_process(false)  # everything paid; stop touching the frame budget
		return
	for slot in slots:
		if queue_index >= queue.size():
			break
		slot.texture = queue[queue_index]
		queue_index += 1


func _harvest(path: String) -> void:
	var script := load(path) as Script
	if script == null:
		return  # a renamed script shouldn't take the title screen down
	for value in script.get_script_constant_map().values():
		_collect(value)


func _collect(value: Variant) -> void:
	# Constants hold textures three ways: bare, in arrays (frame sets), and in
	# dictionaries of arrays (dot.gd's FRAMES, keyed by kind). Recurse rather
	# than assume, so a new shape doesn't silently warm nothing.
	if value is Texture2D:
		var tex := value as Texture2D
		if not seen.has(tex):
			seen[tex] = true
			queue.append(tex)
	elif value is Array:
		for v in value:
			_collect(v)
	elif value is Dictionary:
		for k in value:
			_collect(value[k])
