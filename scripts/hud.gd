extends CanvasLayer

const HEART_FULL := preload("res://assets/ui/heart_full.png")
const HEART_HALF := preload("res://assets/ui/heart_half.png")
const HEART_EMPTY := preload("res://assets/ui/heart_empty.png")
const HEART_MAGIC := preload("res://assets/ui/heart_magic.png")
const HEART_MAGIC_HALF := preload("res://assets/ui/heart_magic_half.png")
const HEART_SIZE := Vector2(48, 48)

# Item-strip icons (the bottom-left run summary). Tiered relics index by
# tier (1/2); the [0] slot is unused padding.
const ICON_LUCKY := preload("res://assets/items/crystals/crystal_luckyluck1.png")
const ICON_QUICKSTEP := preload("res://assets/items/crystals/crystal_quickstep1.png")
const ICON_TWICECUT := preload("res://assets/items/crystals/crystal_twicecut1.png")
const ICON_GAPLEAPER := preload("res://assets/items/crystals/crystal_gapleaper1.png")
const ICON_WIDESWING := preload("res://assets/items/crystals/crystal_wideswing1.png")
const ICON_ROTSTONE := preload("res://assets/items/crystals/crystal_rotstone1.png")
const ICON_EMBERSTONE := preload("res://assets/items/crystals/crystal_emberstone1.png")
const ICON_RAGE := [null,
	preload("res://assets/items/crystals/crystal_rage1.png"),
	preload("res://assets/items/crystals/crystal_rage2.png")]
const ICON_HASTY := [null,
	preload("res://assets/items/crystals/crystal_hasty1.png"),
	preload("res://assets/items/crystals/crystal_hasty2.png")]
const ICON_FLEET := [null,
	preload("res://assets/items/crystals/crystal_fleetfoot1.png"),
	preload("res://assets/items/crystals/crystal_fleetfoot2.png")]
const ICON_TURNING := [null,
	preload("res://assets/items/crystals/crystal_turningstone1.png"),
	preload("res://assets/items/crystals/crystal_turningstone2.png")]
const ICON_SWORD := preload("res://assets/items/weapon_sword.png")
const ICON_STAFF := preload("res://assets/items/magic_staff.png")
const ICON_BOOMERANG := preload("res://assets/items/weapon_boomerang.png")
const ICON_HALBERD := preload("res://assets/items/weapon_halberd.png")

const FADE_IN_TIME := 0.7
const DESCENT_FADE_TIME := 0.8
const DEATH_HOLD_TIME := 5.0

var last_total := 0

@onready var player: Player = get_parent()
@onready var hearts_box: HBoxContainer = $Hearts
@onready var item_strip: VBoxContainer = $ItemStrip
@onready var hurt_flash: ColorRect = $HurtFlash
@onready var run_info: Label = $RunInfo
@onready var screen_fade: ColorRect = $ScreenFade
@onready var level_mist: TextureRect = $LevelMist
@onready var level_label: Label = $LevelLabel
@onready var death_label: Label = $DeathLabel
@onready var killer_face: TextureRect = $KillerFace
@onready var death_cause: Label = $DeathCause
@onready var death_stats: Label = $DeathStats
@onready var toast_name: Label = $ToastName
@onready var toast_desc: Label = $ToastDesc

var toast_tween: Tween = null


func _ready() -> void:
	RunState.changed.connect(_update_run_info)
	_update_run_info()
	player.health_changed.connect(_on_health_changed)
	player.blocked.connect(_on_blocked)
	player.died.connect(_on_player_died)
	last_total = player.health + player.magic_hearts
	_rebuild_hearts(player.health, player.max_health, player.magic_hearts)
	_rebuild_items()
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


func show_toast(title: String, sub: String) -> void:
	# The pickup toast (docs/item-plan.md): the name is the mnemonic,
	# the descriptor is the one-time teach. No numbers, two lines,
	# gone in two seconds. A new pickup replaces a fading one.
	toast_name.text = title
	toast_desc.text = sub
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	toast_name.visible = true
	toast_desc.visible = true
	toast_name.modulate.a = 1.0
	toast_desc.modulate.a = 1.0
	toast_tween = create_tween()
	toast_tween.tween_interval(3.0)
	toast_tween.tween_property(toast_name, "modulate:a", 0.0, 0.6)
	toast_tween.parallel().tween_property(toast_desc, "modulate:a", 0.0, 0.6)
	# Every build-defining pickup toasts, and those are exactly the strip
	# items — so the toast is the one hook that catches them all. RunState
	# is already updated by the grant that triggered this.
	_rebuild_items()


func start_gate_fade() -> void:
	# Through the mist: the world whitens into the next stage's
	# title card — one continuous veil, no black cut.
	level_mist.modulate = Color(0.88, 0.92, 1.0, 0.0)
	level_mist.visible = true
	# 0.5s against the pull's 0.65: the reload lands just as the
	# camera reaches the doorway plane, so the veil never shows the
	# wall's interior.
	var tween := create_tween()
	tween.tween_property(level_mist, "modulate:a", 0.97, 0.5)
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
	# Units are half-hearts: 2 units = one heart icon. Red containers
	# (full/half/empty), magic hearts appended after.
	for child in hearts_box.get_children():
		child.queue_free()
	@warning_ignore("integer_division")
	var containers := maximum / 2
	@warning_ignore("integer_division")
	var full := current / 2
	var has_half := current % 2 == 1
	for i in containers:
		var tex := HEART_EMPTY
		if i < full:
			tex = HEART_FULL
		elif i == full and has_half:
			tex = HEART_HALF
		hearts_box.add_child(_make_heart(tex))
	@warning_ignore("integer_division")
	var magic_full := magic / 2
	for i in magic_full:
		hearts_box.add_child(_make_heart(HEART_MAGIC))
	if magic % 2 == 1:
		hearts_box.add_child(_make_heart(HEART_MAGIC_HALF))


func _make_heart(tex: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = HEART_SIZE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	return icon


func _make_item_icon(tex: Texture2D) -> TextureRect:
	# Same treatment as a heart: fixed 48px slot, nearest, scaled to fit.
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = HEART_SIZE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	return icon


func _rebuild_items() -> void:
	# The run's relics and weapons drawn top-to-bottom; weapons come
	# LAST so they sit at the base of the column, nearest the hand.
	# Tiered crystals show the current tier's cut, never stack. Driven
	# straight from RunState, which persists across floors.
	for child in item_strip.get_children():
		child.queue_free()
	if RunState.lucky:
		item_strip.add_child(_make_item_icon(ICON_LUCKY))
	if RunState.rage_tier > 0:
		item_strip.add_child(_make_item_icon(ICON_RAGE[RunState.rage_tier]))
	if RunState.emberstone:
		item_strip.add_child(_make_item_icon(ICON_EMBERSTONE))
	if RunState.rotstone:
		item_strip.add_child(_make_item_icon(ICON_ROTSTONE))
	if RunState.hasty_tier > 0:
		item_strip.add_child(_make_item_icon(ICON_HASTY[RunState.hasty_tier]))
	if RunState.wideswing:
		item_strip.add_child(_make_item_icon(ICON_WIDESWING))
	if RunState.fleet_tier > 0:
		item_strip.add_child(_make_item_icon(ICON_FLEET[RunState.fleet_tier]))
	if RunState.quickstep:
		item_strip.add_child(_make_item_icon(ICON_QUICKSTEP))
	if RunState.twicecut:
		item_strip.add_child(_make_item_icon(ICON_TWICECUT))
	if RunState.gapleaper:
		item_strip.add_child(_make_item_icon(ICON_GAPLEAPER))
	if RunState.armor_tier > 0:
		item_strip.add_child(_make_item_icon(ICON_TURNING[RunState.armor_tier]))
	if RunState.has_sword:
		item_strip.add_child(_make_item_icon(ICON_SWORD))
	if RunState.has_staff:
		item_strip.add_child(_make_item_icon(ICON_STAFF))
	if RunState.has_boomerang:
		item_strip.add_child(_make_item_icon(ICON_BOOMERANG))
	if RunState.has_halberd:
		item_strip.add_child(_make_item_icon(ICON_HALBERD))


func _update_run_info() -> void:
	run_info.text = "%s   Kills %d" % [RunState.floor_label(RunState.depth), RunState.kills]
