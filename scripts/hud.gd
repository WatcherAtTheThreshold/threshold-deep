extends CanvasLayer

const TALLY_PER_ROW := 3  # creature entries per line of the death-report tally
const HEART_FULL := preload("res://assets/ui/heart_full.png")
const HEART_HALF := preload("res://assets/ui/heart_half.png")
const HEART_EMPTY := preload("res://assets/ui/heart_empty.png")
const HEART_MAGIC := preload("res://assets/ui/heart_magic.png")
const HEART_MAGIC_HALF := preload("res://assets/ui/heart_magic_half.png")
const HEART_SIZE := Vector2(48, 48)

## Boss effigies, in the order the bosses are fought. `RunState.bosses_defeated`
## is a plain 0-3 and the order is fixed (slime, mush, amalgam), so the COUNT
## alone says which were earned — no new bookkeeping, the same trick
## `trophy_count()` plays with the relic flags.
##
## 48x48 on purpose: everything the HUD draws lands in a fixed 48 px slot, and
## only a canvas 48 divides evenly stays crisp. The 64x64 crystals borrowed as
## strip icons are quietly downscaled 0.75x; these aren't.
## Report icon slots. These MUST be integer multiples or divisors of the SOURCE
## canvas or nearest filtering shreds them — effigies are 48 px (clean at 48 /
## 96 / 144), the crystals 64 px (clean at 32 / 64 / 128). See _make_item_icon.
##
## Victory goes large because it IS the celebration and always shows all three
## effigies; death stays at the strip's own 48 because its stats block has the
## least headroom of anything on either screen. Note the victory item row at 64
## is the only place the crystals draw 1:1 — everywhere else they're squeezed
## into a 48 slot at 0.75x.
const DEATH_EFFIGY_PX := 48.0
const DEATH_ITEM_PX := 48.0
const VICTORY_EFFIGY_PX := 96.0
const VICTORY_ITEM_PX := 64.0

const EFFIGIES: Array[Texture2D] = [
	preload("res://assets/ui/effigies/effigy_slime.png"),
	preload("res://assets/ui/effigies/effigy_mush.png"),
	preload("res://assets/ui/effigies/effigy_skeletal_wizard.png"),
]

# Item-strip icons (the bottom-left run summary). Tiered relics index by
# tier (1/2); the [0] slot is unused padding.
const ICON_LUCKY := preload("res://assets/items/crystals/crystal_luckyluck1.png")
const ICON_QUICKSTEP := preload("res://assets/items/crystals/crystal_quickstep1.png")
const ICON_TWICECUT := preload("res://assets/items/crystals/crystal_twicecut1.png")
const ICON_GAPLEAPER := preload("res://assets/items/crystals/crystal_gapleaper1.png")
const ICON_BARRELSTONE := preload("res://assets/items/crystals/crystal_barrelstone1.png")
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
## The CLOSE plate is the intended way out of the death report; this interval
## is only the net for a player who walked away. It was 5 s when the timer WAS
## the only exit — long enough now to read the tally without feeling trapped.
const DEATH_HOLD_TIME := 20.0

var last_total := 0
# Death-report state: the pending tween (so CLOSE can cancel its auto-advance),
# what to fade out, and a guard so the button and the timer can't both fire.
var death_tween: Tween = null
var death_elements: Array[CanvasItem] = []
var death_closing := false

@onready var player: Player = get_parent()
@onready var hearts_box: HBoxContainer = $Hearts
@onready var item_strip: HFlowContainer = $ItemStrip
@onready var hurt_flash: ColorRect = $HurtFlash
@onready var run_info: Label = $RunInfo

var _shown_second := -1  # last whole second painted into run_info
@onready var screen_fade: ColorRect = $ScreenFade
@onready var level_mist: TextureRect = $LevelMist
@onready var level_label: Label = $LevelLabel
@onready var death_label: Label = $DeathLabel
@onready var killer_face: TextureRect = $KillerFace
@onready var death_cause: Label = $DeathCause
@onready var death_stats: Label = $DeathStats
@onready var death_close: TextureButton = $DeathClose
@onready var effigy_row: HBoxContainer = $EffigyRow
@onready var item_report: HBoxContainer = $ItemReport
@onready var toast_name: Label = $ToastName
@onready var toast_desc: Label = $ToastDesc

var toast_tween: Tween = null


func _ready() -> void:
	RunState.changed.connect(_update_run_info)
	_update_run_info()
	player.health_changed.connect(_on_health_changed)
	player.blocked.connect(_on_blocked)
	player.died.connect(_on_player_died)
	death_close.pressed.connect(close_death_report)
	Sfx.wire_buttons(self)
	player.poisoned.connect(_on_poisoned)
	player.burned.connect(_on_burned)
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
	# The DESCENT is what ends the run, not the kill. Every floor ends by
	# taking the hatch; making the last one end the same way turns eight
	# repetitions of a habit into a ceremony, and it lets you claim the boss
	# reward and catch your breath before you choose to finish.
	#
	# Intercepted HERE rather than in hatch.gd because the fade has already
	# run by the time this fires — so the report resolves on the black instead
	# of over the chamber. You step down, the world goes out, and the account
	# of the run arrives.
	if RunState.bosses_defeated >= 3 and not RunState.victory_shown:
		RunState.victory_shown = true
		show_victory()
		return
	RunState.descend(player.health, player.max_health, player.magic_hearts)
	get_tree().reload_current_scene()


func show_victory() -> void:
	# The win report. Deliberately the death report's BONES with a different
	# frame — same score-first stats, same CLOSE plate, same exit to the title.
	# structure.md: "the last thing anyone builds and the first thing anyone
	# screenshots", which a banner that fades while you keep walking could
	# never be.
	#
	# Reached only from _go_down (the 3-3 hatch), so `screen_fade` is already
	# opaque — no darkening pass here, the report just arrives on the black.
	# No killer portrait and no cause line: nothing killed you.
	# The ending gets its own piece. Started FIRST so its fade-in runs under the
	# report's, and reached only through the 3-3 hatch where the screen is already
	# black — so the cut away from the deep drift is covered by the transition.
	# Death calls this too; the piece is written to carry either outcome.
	MusicDrift.play_end()
	death_label.text = "YOU PREVAILED"
	death_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	death_stats.text = _build_death_stats()
	# Victory reclaims the two bands a death report spends on the killer
	# portrait and the "slain by" line — nothing killed you — so everything
	# below the title rises into that space instead of stranding itself at the
	# bottom under an empty gap. All three effigies are guaranteed here
	# (`bosses_defeated >= 3` is what triggered this screen), which makes the
	# spoils row the widest it ever gets.
	_fill_report_rows(VICTORY_EFFIGY_PX, VICTORY_ITEM_PX)
	# The title drops off the top edge — at 0 it read as pinned rather than
	# placed — and the two picture bands grow into the room that death spends
	# on the portrait and the cause line.
	death_label.offset_top = 38.0
	death_label.offset_bottom = -534.0
	effigy_row.offset_top = 124.0
	effigy_row.offset_bottom = 220.0
	item_report.offset_top = 232.0
	item_report.offset_bottom = 296.0
	# Stats keep a deliberate 53 px of slack above the CLOSE plate: this block
	# is the one thing on the screen that GROWS with the run, since the tally
	# gains a row per three creature types met.
	death_stats.offset_top = 310.0
	death_stats.offset_bottom = -166.0
	var elements: Array[CanvasItem] = [death_label, death_stats]
	elements.append_array(_report_rows())
	death_elements = elements
	for e in elements:
		e.modulate.a = 0.0
		e.visible = true
	# The mouse is still captured from the fight; the CLOSE plate needs it.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	death_tween = create_tween()
	death_tween.tween_property(death_label, "modulate:a", 1.0, 1.2)
	for row in _report_rows():
		death_tween.tween_property(row, "modulate:a", 1.0, 0.45)
	death_tween.tween_property(death_stats, "modulate:a", 1.0, 0.6)
	death_tween.tween_callback(_show_death_close)
	death_tween.tween_interval(DEATH_HOLD_TIME)
	death_tween.tween_callback(close_death_report)


func _on_player_died() -> void:
	death_label.text = "YOU DIED"
	death_label.add_theme_color_override("font_color", Color(0.85, 0.2, 0.25))
	death_cause.text = "Slain by %s" % _killer_phrase()
	death_stats.text = _build_death_stats()
	killer_face.texture = RunState.killer_texture
	_fill_report_rows(DEATH_EFFIGY_PX, DEATH_ITEM_PX)
	var elements: Array[CanvasItem] = [death_label, death_cause, death_stats]
	if RunState.killer_texture != null:
		elements.append(killer_face)
	elements.append_array(_report_rows())
	for e in elements:
		e.modulate.a = 0.0
		e.visible = true
	death_elements = elements
	# BOTH endings get the ending piece (2026-08-16). It sits in A minor like the
	# rest of the score, so it reads trepidatious rather than triumphant and
	# carries a death as well as a win — a separate, brighter track for victory
	# is the eventual plan, not a correction to this.
	#
	# play_end() SUPERSEDES the hush that used to be here: it bumps the drift's
	# gen so the loop bails and stops the player, exactly as hush did, and then
	# brings the ending track up instead of leaving silence. Returning to the
	# title still clears it, because title.gd's hush() covers an owned track as
	# well as a running drift.
	#
	# It fires HERE and not on the way out the door. It used to hush in
	# _restart_run, one line before the scene change — a 1.2s fade against a
	# title track starting at full, so every death overlapped the two. It only
	# sounded wrong SOMETIMES because the drift plays random passages with long
	# silences between: die in a gap and there was nothing to collide.
	MusicDrift.play_end()
	# The mouse is still CAPTURED from the fight — free it or the CLOSE plate
	# is visible and unclickable, which is worse than having no plate at all.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	death_tween = create_tween()
	# Half-darken the world, bring in the verdict and the culprit...
	death_tween.tween_property(screen_fade, "color:a", 0.55, 0.5)
	death_tween.parallel().tween_property(death_label, "modulate:a", 1.0, 0.7)
	death_tween.parallel().tween_property(killer_face, "modulate:a", 1.0, 0.7)
	death_tween.parallel().tween_property(death_cause, "modulate:a", 1.0, 0.7)
	# ...then the spoils, one band at a time — what you beat, then what you
	# carried — before the numbers land under them.
	for row in _report_rows():
		death_tween.tween_property(row, "modulate:a", 1.0, 0.35)
	death_tween.tween_property(death_stats, "modulate:a", 1.0, 0.4)
	# The plate arrives with the report and is the way out. The interval after
	# it is a safety net for someone who walked away, not the intended path —
	# hence long enough to actually read the tally rather than the old 5 s.
	death_tween.tween_callback(_show_death_close)
	death_tween.tween_interval(DEATH_HOLD_TIME)
	death_tween.tween_callback(close_death_report)


func _killer_phrase() -> String:
	var who := RunState.killer_name
	if who == "" or who == "the Dungeon":
		return "the Dungeon"
	# A name that already carries its own article takes no second one: the
	# fall records "the Dark Below", and "a the Dark Below" is not a sentence.
	if who.begins_with("the ") or who.begins_with("The "):
		return who
	# "an Amalgam", not "a Amalgam".
	return "%s %s" % ["an" if who[0] in "AEIOUaeiou" else "a", who]


func _build_death_stats() -> String:
	var lines: Array[String] = [
		"SCORE %d" % RunState.score(),
		"Level %s   ·   %s   ·   %d kills" % [
			RunState.floor_label(RunState.depth), RunState.time_text(), RunState.kills],
		"Damage dealt %d   ·   taken %d   ·   %d relics" \
				% [RunState.damage_dealt, RunState.damage_taken, RunState.trophy_count()],
	]
	if RunState.secrets_found > 0:
		# Only shown when earned — a line reading "0 secrets" would advertise
		# the commoner chamber to someone who never found the pale plank.
		lines.append("Secrets found %d" % RunState.secrets_found)
	var by_type := RunState.kills_by_type
	if by_type.size() > 0:
		var labels := by_type.keys()
		labels.sort_custom(func(a: String, b: String) -> bool:
			return by_type[a] > by_type[b])
		# Chunked into short rows rather than one line. The roster keeps
		# growing — three necromancer variants, four mush tiers, three slime
		# sizes — and a single joined line outran the screen entirely.
		var row: Array[String] = []
		for label: String in labels:
			row.append("%s ×%d" % [label, by_type[label]])
			if row.size() == TALLY_PER_ROW:
				lines.append("   ".join(row))
				row.clear()
		if row.size() > 0:
			lines.append("   ".join(row))
	return "\n".join(lines)


func _fill_report_rows(effigy_px: float, item_px: float) -> void:
	# The report's two picture bands. Both reuse `_make_item_icon` — the same
	# 48 px slot the HUD strip uses — so an effigy and a relic read as the same
	# CLASS of thing, which is what makes the row scan as a row.
	#
	# Effigies come from the boss count; the kit comes from `item_order`, so
	# the report tells the run's story in the order it happened rather than in
	# a tidy fixed layout that could only show what you already knew.
	var effigy_size := Vector2(effigy_px, effigy_px)
	var item_size := Vector2(item_px, item_px)
	for child in effigy_row.get_children():
		child.queue_free()
	for i in mini(RunState.bosses_defeated, EFFIGIES.size()):
		effigy_row.add_child(_make_item_icon(EFFIGIES[i], effigy_size))
	for child in item_report.get_children():
		child.queue_free()
	for key: StringName in RunState.item_order:
		var icon := _strip_icon(key)
		if icon != null:
			item_report.add_child(_make_item_icon(icon, item_size))


func _report_rows() -> Array[CanvasItem]:
	# Only the bands that HAVE something. An empty row would still fade in and
	# occupy its gap, and a torch-only run that beat nothing would show two
	# blank stripes where the spoils should be.
	var rows: Array[CanvasItem] = []
	if RunState.bosses_defeated > 0:
		rows.append(effigy_row)
	if not RunState.item_order.is_empty():
		rows.append(item_report)
	return rows


func _show_death_close() -> void:
	death_close.modulate.a = 0.0
	death_close.visible = true
	create_tween().tween_property(death_close, "modulate:a", 1.0, 0.5)


func close_death_report() -> void:
	# Reached two ways: the player pressing CLOSE, or the safety-net interval
	# running out. Guarded, because both can land in the same frame.
	if death_closing:
		return
	death_closing = true
	# The waiting tween still holds a queued call to this function — kill it
	# or the auto-advance fires again behind the manual one.
	if death_tween != null and death_tween.is_valid():
		death_tween.kill()
	var outro := create_tween()
	outro.tween_property(screen_fade, "color:a", 1.0, 0.9)
	outro.parallel().tween_property(death_close, "modulate:a", 0.0, 0.9)
	for e in death_elements:
		outro.parallel().tween_property(e, "modulate:a", 0.0, 0.9)
	outro.tween_callback(_restart_run)


func _restart_run() -> void:
	# Death returns to the title — the hub where the next run is born.
	# RunState.reset() now lives on the title's START (so a completed run
	# can still be read here); MetaState keeps the flythrough from replaying.
	# The drift was hushed back at _on_player_died — by now it's long silent,
	# so the title's own track opens on nothing.
	get_tree().change_scene_to_file("res://scenes/title.tscn")


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


func _on_poisoned(current: int, maximum: int, magic: int) -> void:
	# Poison pulses green — distinct from the red hit-flash — then resets
	# to the red base for the next real blow. Keeps last_total in sync so
	# the next genuine hit still reads its own drop.
	hurt_flash.color = Color(0.35, 0.75, 0.3, 0.4)
	var tween := create_tween()
	tween.tween_property(hurt_flash, "color:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		hurt_flash.color = Color(0.7, 0.08, 0.08, 0.0))
	last_total = current + magic
	_rebuild_hearts(current, maximum, magic)


func _on_burned(current: int, maximum: int, magic: int) -> void:
	# Burn pulses ORANGE — its own colour, so a fireball's afterburn is never
	# mistaken for the slime's green rot or the red hit-flash. Same reset to
	# the red base afterward, and last_total stays in sync so the next genuine
	# blow still reads its own drop.
	hurt_flash.color = Color(1.0, 0.5, 0.15, 0.4)
	var tween := create_tween()
	tween.tween_property(hurt_flash, "color:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		hurt_flash.color = Color(0.7, 0.08, 0.08, 0.0))
	last_total = current + magic
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


func _make_item_icon(tex: Texture2D, size := HEART_SIZE) -> TextureRect:
	# Same treatment as a heart: fixed slot, nearest, scaled to fit.
	#
	# THE SLOT SIZE IS NOT A FREE CHOICE. Nearest filtering only stays crisp on
	# an integer scale, so a slot has to be a whole multiple or divisor of the
	# SOURCE canvas: 48 px effigies are clean at 48 / 96 / 144, and the 64 px
	# crystals at 32 / 64 / 128. The HUD strip's 48 slot puts a 64 px crystal
	# at 0.75x and drops a quarter of its rows — which is why the report's item
	# row is 64, the size where they finally draw 1:1.
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = size
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	return icon


func _rebuild_items() -> void:
	# The run's kit drawn left-to-right in a top band, wrapping into new
	# rows as it fills (HFlowContainer), in the ORDER IT WAS COLLECTED.
	#
	# It used to draw in source order — weapons then crystals — which looked
	# tidy and told you nothing: a fixed layout can only show what you already
	# knew. Collection order makes the rightmost icon the thing you most
	# recently claimed, which is what you're checking for on an item floor
	# ("did I already take it, or am I still looking?"), and it reads back as
	# the run's story on the way down.
	#
	# Tiered crystals still show the current tier's cut and never stack; the
	# upgrade just moves the family to the end (see RunState.record_item).
	for child in item_strip.get_children():
		child.queue_free()
	for key: StringName in RunState.item_order:
		var icon := _strip_icon(key)
		if icon != null:
			item_strip.add_child(_make_item_icon(icon))


func _strip_icon(key: StringName) -> Texture2D:
	# Tiered families read their tier from RunState at DRAW time, so an
	# upgrade repaints the existing slot rather than needing its own entry.
	# An unknown key returns null and is skipped — a new relic that forgets to
	# be listed here leaves a gap, it doesn't crash the HUD.
	match key:
		&"sword": return ICON_SWORD
		&"staff": return ICON_STAFF
		&"boomerang": return ICON_BOOMERANG
		&"halberd": return ICON_HALBERD
		&"luckyluck": return ICON_LUCKY
		&"quickstep": return ICON_QUICKSTEP
		&"twicecut": return ICON_TWICECUT
		&"gapleaper": return ICON_GAPLEAPER
		&"barrelstone": return ICON_BARRELSTONE
		&"wideswing": return ICON_WIDESWING
		&"rotstone": return ICON_ROTSTONE
		&"emberstone": return ICON_EMBERSTONE
		&"rage": return ICON_RAGE[RunState.rage_tier]
		&"hasty": return ICON_HASTY[RunState.hasty_tier]
		&"fleetfoot": return ICON_FLEET[RunState.fleet_tier]
		&"armor": return ICON_TURNING[RunState.armor_tier]
	return null


func _process(_delta: float) -> void:
	# The clock has to tick on its own — RunState.changed only fires on real
	# events. Refresh only when the displayed second actually rolls over, so
	# this isn't rebuilding a string 60 times a second.
	var secs := int(RunState.run_seconds)
	if secs != _shown_second:
		_shown_second = secs
		_update_run_info()


func _update_run_info() -> void:
	# Floor · clock · score. Score replaces the raw kill count: kills reward
	# clearing rooms, and the design is explicitly "you don't clear rooms, you
	# follow a trail deeper" (docs/acts.md). Kills survive as a component of
	# the score and in full on the death report.
	run_info.text = "%s   ·   %s   ·   Score %d" % [
		RunState.floor_label(RunState.depth),
		RunState.time_text(),
		RunState.score(),
	]
