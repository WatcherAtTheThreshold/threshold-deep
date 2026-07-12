extends CanvasLayer

const HEART_FULL := preload("res://assets/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/ui/heart_empty.png")
const HEART_SIZE := Vector2(48, 48)

const FADE_IN_TIME := 0.7
const DESCENT_FADE_TIME := 0.5
const DEATH_HOLD_TIME := 4.0

var last_health := 0
var heart_icons: Array[TextureRect] = []

@onready var player: Player = get_parent()
@onready var hearts_box: HBoxContainer = $Hearts
@onready var hurt_flash: ColorRect = $HurtFlash
@onready var run_info: Label = $RunInfo
@onready var screen_fade: ColorRect = $ScreenFade
@onready var death_label: Label = $DeathLabel
@onready var killer_face: TextureRect = $KillerFace
@onready var death_cause: Label = $DeathCause
@onready var death_stats: Label = $DeathStats


func _ready() -> void:
	RunState.changed.connect(_update_run_info)
	_update_run_info()
	for i in player.MAX_HEALTH:
		var icon := TextureRect.new()
		icon.texture = HEART_FULL
		icon.custom_minimum_size = HEART_SIZE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		hearts_box.add_child(icon)
		heart_icons.append(icon)
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	last_health = player.health
	_refresh(player.health)
	# Every floor and every run opens with a fade in from black.
	screen_fade.color.a = 1.0
	create_tween().tween_property(screen_fade, "color:a", 0.0, FADE_IN_TIME)


func start_descent_fade() -> void:
	var tween := create_tween()
	tween.tween_property(screen_fade, "color:a", 1.0, DESCENT_FADE_TIME)
	tween.tween_callback(_go_down)


func _go_down() -> void:
	RunState.descend(player.health)
	get_tree().reload_current_scene()


func _on_player_died() -> void:
	death_cause.text = "Slain by %s" % _killer_phrase()
	death_stats.text = _build_death_stats()
	killer_face.texture = RunState.killer_texture
	var elements: Array[CanvasItem] = [death_label, death_cause, death_stats]
	if RunState.killer_texture != null:
		elements.append(killer_face)
	for e in elements:
		e.modulate.a = 0.0
		e.visible = true
	var tween := create_tween()
	# Half-darken the world, bring in the verdict and the culprit...
	tween.tween_property(screen_fade, "color:a", 0.55, 0.5)
	tween.parallel().tween_property(death_label, "modulate:a", 1.0, 0.7)
	tween.parallel().tween_property(killer_face, "modulate:a", 1.0, 0.7)
	tween.parallel().tween_property(death_cause, "modulate:a", 1.0, 0.7)
	tween.tween_property(death_stats, "modulate:a", 1.0, 0.4)
	# ...let it sit, then close the dark over everything.
	tween.tween_interval(DEATH_HOLD_TIME)
	tween.tween_property(screen_fade, "color:a", 1.0, 0.9)
	for e in elements:
		tween.parallel().tween_property(e, "modulate:a", 0.0, 0.9)
	tween.tween_callback(_restart_run)


func _killer_phrase() -> String:
	var who := RunState.killer_name
	if who == "" or who == "the Dungeon":
		return "the Dungeon"
	return "a %s" % who


func _build_death_stats() -> String:
	var lines: Array[String] = [
		"Depth %d   ·   %d kills" % [RunState.depth, RunState.kills],
		"Damage dealt %d   ·   taken %d" \
				% [RunState.damage_dealt, RunState.damage_taken],
	]
	var by_type := RunState.kills_by_type
	if by_type.size() > 0:
		var labels := by_type.keys()
		labels.sort_custom(func(a: String, b: String) -> bool:
			return by_type[a] > by_type[b])
		var tally: Array[String] = []
		for label: String in labels:
			tally.append("%s ×%d" % [label, by_type[label]])
		lines.append("   ".join(tally))
	return "\n".join(lines)


func _restart_run() -> void:
	RunState.reset()
	get_tree().reload_current_scene()


func _on_health_changed(current: int, _maximum: int) -> void:
	if current < last_health:
		hurt_flash.color.a = 0.4
		create_tween().tween_property(hurt_flash, "color:a", 0.0, 0.4)
	last_health = current
	_refresh(current)


func _refresh(current: int) -> void:
	for i in heart_icons.size():
		heart_icons[i].texture = HEART_FULL if i < current else HEART_EMPTY


func _update_run_info() -> void:
	run_info.text = "Depth %d   Kills %d" % [RunState.depth, RunState.kills]
