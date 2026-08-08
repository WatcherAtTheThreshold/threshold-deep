extends CanvasLayer

## The settings panel, shared by the title menu and the pause menu — one scene
## instanced by both, so the two can never drift apart.
##
## Sliders are the one place the plate rule bends (docs/ui-language.md): a
## slider can't be a drawn word. Kept deliberately plain so the plates around
## it carry the identity instead.
##
## Only MOUSE gets tick marks, and they mark the DEFAULT, not a recommendation.
## Volume has no correct value — it depends on the player's speakers and their
## room, and their ears are the readout. Sensitivity is different: 1.0 is the
## multiplier the game was actually tuned at, and without a notch a player who
## drags it has no way back to it. Range is 0.5–2.0 rather than the old
## 0.3–2.5 so the useful zone gets the resolution instead of the extremes.
##
## Everything writes straight through to MetaState and applies live — you hear
## a volume change while dragging, which is the only way to set one honestly.

signal closed

@onready var master: HSlider = $Panel/Margin/Box/Grid/Master
@onready var music: HSlider = $Panel/Margin/Box/Grid/Music
@onready var sfx: HSlider = $Panel/Margin/Box/Grid/Sfx
@onready var sens: HSlider = $Panel/Margin/Box/Grid/Sens
@onready var fullscreen: CheckButton = $Panel/Margin/Box/Fullscreen
@onready var back_button: TextureButton = $Panel/Margin/Box/BackRow/Back


func _ready() -> void:
	# Runs while the tree is paused — this panel is reachable FROM the pause
	# menu, and a paused panel can't move its own sliders.
	process_mode = Node.PROCESS_MODE_ALWAYS
	master.value = MetaState.master_volume
	music.value = MetaState.music_volume
	sfx.value = MetaState.sfx_volume
	sens.value = MetaState.mouse_sensitivity
	fullscreen.button_pressed = MetaState.fullscreen
	if OS.has_feature("web"):
		# The browser owns the viewport; a fullscreen toggle here fights the
		# itch embed rather than filling the screen.
		fullscreen.hide()
	back_button.pressed.connect(close)
	master.value_changed.connect(_on_master)
	music.value_changed.connect(_on_music)
	sfx.value_changed.connect(_on_sfx)
	sens.value_changed.connect(_on_sens)
	fullscreen.toggled.connect(_on_fullscreen)
	Sfx.wire_buttons(self)


func _on_master(v: float) -> void:
	MetaState.master_volume = v
	MetaState.apply_audio()


func _on_music(v: float) -> void:
	MetaState.music_volume = v
	MetaState.apply_audio()


func _on_sfx(v: float) -> void:
	MetaState.sfx_volume = v
	MetaState.apply_audio()


func _on_sens(v: float) -> void:
	MetaState.mouse_sensitivity = v


func _on_fullscreen(on: bool) -> void:
	MetaState.fullscreen = on
	MetaState.apply_window()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Swallow it: without this the Esc that closes the panel also reaches
		# whatever opened it, and the pause menu would toggle straight back off.
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	# Written on the way out rather than on every slider tick — dragging a
	# slider would otherwise hit the disk a hundred times.
	MetaState.save_settings()
	closed.emit()
	queue_free()
