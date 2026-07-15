extends Node

## Autoload singleton: the state of the current run. Scene reloads
## (new floors, death) rebuild the whole world tree, so anything that
## must survive them lives here.

signal changed

enum FloorKind { REGULAR, BOSS, ITEM }

var depth := 1
var bosses_defeated := 0
var victory_shown := false
var kills := 0
var carried_health := -1  # -1 = fresh run, spawn with full hearts
var carried_max_health := -1  # -1 = fresh run, base containers
var carried_magic := 0
var has_sword := false
var has_staff := false
var has_boots := false
var armor_tier := 0  # 0 none, 1 leather (25% block), 2 steel (40%)

var damage_dealt := 0
var damage_taken := 0
var kills_by_type := {}
var killer_name := ""
var killer_texture: Texture2D = null


func floor_kind(d: int) -> FloorKind:
	# The run cadence: each world is explore → item → boss.
	# 1-1 regular, 1-2 item, 1-3 BOSS, then world 2... and the
	# pattern continues below the victory floor for endless descent.
	if d % 3 == 2:
		return FloorKind.ITEM
	if d % 3 == 0:
		return FloorKind.BOSS
	return FloorKind.REGULAR


func floor_label(d: int) -> String:
	# Depth rendered as world - stage: 1-1, 1-2, 1-3, 2-1...
	@warning_ignore("integer_division")
	var world := (d + 2) / 3
	var stage := ((d - 1) % 3) + 1
	return "%d - %d" % [world, stage]


func record_kill(label: String) -> void:
	kills += 1
	kills_by_type[label] = kills_by_type.get(label, 0) + 1
	changed.emit()


func record_damage_dealt(amount: int) -> void:
	damage_dealt += amount


func record_damage_taken(amount: int) -> void:
	damage_taken += amount


func set_killer(label: String, texture: Texture2D) -> void:
	killer_name = label
	killer_texture = texture


func descend(current_health: int, current_max: int, current_magic: int) -> void:
	depth += 1
	carried_health = current_health
	carried_max_health = current_max
	carried_magic = current_magic
	changed.emit()


func reset() -> void:
	print("Run over: reached depth %d with %d kills (dealt %d, took %d)." \
			% [depth, kills, damage_dealt, damage_taken])
	depth = 1
	kills = 0
	bosses_defeated = 0
	victory_shown = false
	carried_health = -1
	carried_max_health = -1
	carried_magic = 0
	has_sword = false
	has_staff = false
	has_boots = false
	armor_tier = 0
	damage_dealt = 0
	damage_taken = 0
	kills_by_type = {}
	killer_name = ""
	killer_texture = null
	changed.emit()
