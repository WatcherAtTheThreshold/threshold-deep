extends CanvasLayer

const HEART_FULL := preload("res://assets/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/ui/heart_empty.png")
const HEART_MAGIC := preload("res://assets/ui/heart_magic.png")
const HEART_SIZE := Vector2(48, 48)

const FADE_IN_TIME := 0.7
const DESCENT_FADE_TIME := 0.5
const DEATH_HOLD_TIME := 5.0

var last_total := 0

@onready var player: Player = get_parent()
@onready var hearts_box: HBoxContainer = $Hearts
@onready var hurt_flash: ColorRect = $HurtFlash
@onready var run_info: Label = $RunInfo
@onready var screen_fade: ColorRect = $ScreenFade
@onready var level_mist: TextureRect = $LevelMist
@onready var level_label: Label = $LevelLabel
@onready var death_label: Label = $DeathLabel
@onready var killer_face: TextureRect = $KillerFace
@onready var death_cause: Label = $DeathCause
@onready var death_stats: Label = $DeathStats


func _ready() -> void:
	RunState.changed.connect(_update_run_info)
	_update_run_info()
	player.health_changed.connect(_on_health_changed)
	player.blocked.connect(_on_blocked)
	player.died.connect(_on_player_died)
	last_total = player.health + player.magic_hearts
	_rebuild_hearts(player.health, player.max_health, player.magic_hearts)
	# Every floor and every run opens with a fade in from black.
	screen_fade.color.a = 1.0
	create_tween().tween_property(screen_fade, "color:a", 0.0, FADE_IN_TIME)
	_show_level_card()


func _show_level_card() -> void:
	# The title card: mist across the screen, the level's name on it,
	# tinted in the floor's color language.
	level_label.text = RunState.floor_label(RunState.depth)
	var kind := RunState.floor_kind(RunState.depth)
	var card_tint := Color(0.8, 0.85, 0.95, 0.85)
	if kind == RunState.FloorKind.BOSS:
		card_tint = Color(0.72, 0.85, 1.0, 0.9)
	elif kind == RunState.FloorKind.ITEM:
		card_tint = Color(1.0, 0.82, 0.5, 0.9)
	level_mist.modulate = card_tint
	level_label.modulate.a = 1.0
	level_mist.visible = true
	level_label.visible = true
	var card := create_tween()
	card.tween_interval(1.6)
	card.tween_property(level_mist, "modulate:a", 0.0, 0.9)
	card.parallel().tween_property(level_label, "modulate:a", 0.0, 0.9)
	card.tween_callback(func() -> void:
		level_mist.visible = false
		level_label.visible = false)


func start_descent_fade() -> void:
	var tween := create_tween()
	tween.tween_property(screen_fade, "color:a", 1.0, DESCENT_FADE_TIME)
	tween.tween_callback(_go_down)


func _go_down() -> void:
	RunState.descend(player.health, player.max_health, player.magic_hearts)
	get_tree().reload_current_scene()


func show_victory() -> void:
	# Boss three is down. The run is won — and the dungeon continues
	# below for whoever wants to know how deep it goes.
	death_label.text = "YOU PREVAILED"
	death_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	death_stats.text = _build_death_stats()
	death_label.modulate.a = 0.0
	death_stats.modulate.a = 0.0
	death_label.visible = true
	death_stats.visible = true
	var tween := create_tween()
	tween.tween_property(death_label, "modulate:a", 1.0, 1.2)
	tween.parallel().tween_property(death_stats, "modulate:a", 1.0, 1.2)
	tween.tween_interval(6.0)
	tween.tween_property(death_label, "modulate:a", 0.0, 1.5)
	tween.parallel().tween_property(death_stats, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func() -> void:
		death_label.visible = false
		death_stats.visible = false)


func _on_player_died() -> void:
	death_label.text = "YOU DIED"
	death_label.add_theme_color_override("font_color", Color(0.85, 0.2, 0.25))
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
		"Level %s   ·   %d kills" % [RunState.floor_label(RunState.depth), RunState.kills],
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


func _on_blocked() -> void:
	# The armor turned the blow: a steel-blue flash instead of red.
	hurt_flash.color = Color(0.55, 0.7, 0.95, 0.35)
	var tween := create_tween()
	tween.tween_property(hurt_flash, "color:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		hurt_flash.color = Color(0.7, 0.08, 0.08, 0.0))


func _on_health_changed(current: int, maximum: int, magic: int) -> void:
	var total := current + magic
	if total < last_total:
		hurt_flash.color.a = 0.4
		create_tween().tween_property(hurt_flash, "color:a", 0.0, 0.4)
	last_total = total
	_rebuild_hearts(current, maximum, magic)


func _rebuild_hearts(current: int, maximum: int, magic: int) -> void:
	# Red containers (full then empty), magic hearts appended after.
	for child in hearts_box.get_children():
		child.queue_free()
	for i in maximum:
		hearts_box.add_child(_make_heart(HEART_FULL if i < current else HEART_EMPTY))
	for i in magic:
		hearts_box.add_child(_make_heart(HEART_MAGIC))


func _make_heart(tex: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = HEART_SIZE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	return icon


func _update_run_info() -> void:
	run_info.text = "%s   Kills %d" % [RunState.floor_label(RunState.depth), RunState.kills]
