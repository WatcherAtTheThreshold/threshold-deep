extends Node

## Autoload singleton: the state of the current run. Scene reloads
## (new floors, death) rebuild the whole world tree, so anything that
## must survive them lives here.

signal changed

var depth := 1
var kills := 0
var carried_health := -1  # -1 = fresh run, spawn with full hearts


func record_kill() -> void:
	kills += 1
	changed.emit()


func descend(current_health: int) -> void:
	depth += 1
	carried_health = current_health
	changed.emit()


func reset() -> void:
	print("Run over: reached depth %d with %d kills." % [depth, kills])
	depth = 1
	kills = 0
	carried_health = -1
	changed.emit()
