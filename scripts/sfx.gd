extends Node

## Autoload: fire-and-forget sounds that must survive scene reloads —
## a pickup grabbed beside the hatch shouldn't be cut off mid-chime
## by the descent.
##
## Everything spawned here rides the SFX bus so Options can move it without
## touching the music. Scene-embedded players (creature StepSound, the enemy
## Creak, orb FlightSound) set their own bus in their .tscn — if a sound ever
## ignores the slider, grep for `bus = ` and check it was given one.

const SFX_BUS := &"SFX"
const CLICK_SOUND := preload("res://assets/audio/sfx/ui/button_click1.ogg")
## Measured, not guessed: the file averages -34.9 dB where the rest of the mix
## sits around -26, so it already carries its own restraint and wants no
## attenuation on top. play_ui's -6 default would have buried it.
const CLICK_DB := 0.0


func _ready() -> void:
	# One-shots keep playing through a pause. This is what lets a menu click
	# be audible AT ALL from the pause screen — a paused Sfx node means paused
	# children, and every sound it spawns is a child. Scene-embedded players
	# (footsteps, torch crackle) are not ours and still halt with the game.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Connect every button under `root` to the click, once. One call per menu
## scene beats nine hand-wired connections plus the tenth that gets forgotten —
## the same leverage dot.gd takes by living off the host instead of the
## creatures. Sliders are Ranges, not BaseButtons, so dragging volume stays
## silent; the fullscreen CheckButton IS a BaseButton and does click, which is
## what you want from a toggle.
func wire_buttons(root: Node) -> void:
	for node in root.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if button != null and not button.pressed.is_connected(_on_ui_button):
			button.pressed.connect(_on_ui_button)


func _on_ui_button() -> void:
	play_ui(CLICK_SOUND, CLICK_DB)


func play_at(stream: AudioStream, position: Vector3, volume_db := 0.0, pitch := 1.0) -> void:
	var p := AudioStreamPlayer3D.new()
	p.bus = SFX_BUS
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	add_child(p)
	p.global_position = position
	p.finished.connect(p.queue_free)
	p.play()


func play_ui(stream: AudioStream, volume_db := -6.0) -> void:
	var p := AudioStreamPlayer.new()
	p.bus = SFX_BUS
	p.stream = stream
	p.volume_db = volume_db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
