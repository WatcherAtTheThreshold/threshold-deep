extends Node

## Autoload singleton: the state of the current run. Scene reloads
## (new floors, death) rebuild the whole world tree, so anything that
## must survive them lives here.

signal changed

var depth := 1
var kills := 0
var carried_health := -1  # -1 = fresh run, spawn with full hearts
var carried_max_health := -1  # -1 = fresh run, base containers
var carried_magic := 0
var has_sword := false

var damage_dealt := 0
var damage_taken := 0
var kills_by_type := {}
var killer_name := ""
var killer_texture: Texture2D = null


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
	carried_health = -1
	carried_max_health = -1
	carried_magic = 0
	has_sword = false
	damage_dealt = 0
	damage_taken = 0
	kills_by_type = {}
	killer_name = ""
	killer_texture = null
	changed.emit()
