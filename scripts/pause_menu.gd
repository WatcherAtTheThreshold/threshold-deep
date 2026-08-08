extends CanvasLayer

## The pause menu — RESUME / OPTIONS / QUIT TO TITLE, plus the control list.
##
## It carries the web-demo checklist's "controls surfaced somewhere in-game",
## which is why the list is here and not buried in Options: pausing is the one
## thing a confused player already knows how to do.
##
## It is also the first UI in the game that sits OVER live gameplay rather than
## over black (docs/ui-language.md). The scrim is what makes the plates read on
## an arbitrary dungeon frame; without it they compete with whatever the torch
## happens to be lighting.

const OPTIONS_SCENE := preload("res://scenes/options_panel.tscn")

signal resumed

var options: CanvasLayer = null

@onready var menu: VBoxContainer = $Menu
## A CenterContainer wrapping a 4-column grid, not a Label — one Label can only
## hold one colour, and the grid also does the column alignment that manual
## monospace padding was doing badly.
@onready var controls: CenterContainer = $Controls
@onready var resume_button: TextureButton = $Menu/Resume
@onready var options_button: TextureButton = $Menu/Options
@onready var quit_button: TextureButton = $Menu/Quit


func _ready() -> void:
	# The whole point is to run while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(resume)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit_to_title)
	Sfx.wire_buttons(self)


func _unhandled_input(event: InputEvent) -> void:
	# Esc closes the menu — but only when Options isn't up, or one press would
	# close both and dump you back into a fight you can't see yet.
	if options != null:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		resume()


func _on_options() -> void:
	if options != null:
		return
	# Hide the pause menu rather than letting the Options panel sit on top of
	# it — the plates and the control list read straight through the panel's
	# scrim and the whole thing looks like two screens fighting.
	menu.hide()
	controls.hide()
	options = OPTIONS_SCENE.instantiate()
	options.closed.connect(func() -> void:
		options = null
		menu.show()
		controls.show())
	add_child(options)


func resume() -> void:
	get_tree().paused = false
	# Back to the fight: the mouse goes away again. Without this you resume
	# with a visible cursor and a camera that won't turn.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	resumed.emit()
	queue_free()


func _on_quit_to_title() -> void:
	# Unpause BEFORE changing scene — a tree left paused would load the title
	# frozen, with an unclickable menu and no way back.
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/title.tscn")
