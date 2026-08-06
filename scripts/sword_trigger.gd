extends Area3D

## Step on the plate and the sword appears somewhere else on the
## floor. Find the plate but not the sword, and the hunt continues
## on the next level.

signal activated

## The plate stands proud of the floor and goes flush when stepped on —
## the commit is a movement, not a recolor. Sprite and rim travel
## together; the Area3D never moves, so the trigger volume is unchanged.
## The rim lands a hair BELOW the floor surface rather than level with
## it: coplanar faces z-fight, and its top face is the one you'd see.
##
## SINK_TIME matches the press sound's length and the easing runs IN,
## not out: the sound is two bricks sliding that seat with a thunk at
## the very end, so the plate must still be moving when the thunk lands.
## Ease out would have parked it a full second early.
const PRESSED_SPRITE_Y := 0.02
const PRESSED_RIM_Y := -0.035
const SINK_TIME := 1.2

## Stone grinding as the plate goes down. Deliberately NOT the secret
## room's grind: the magic-heart plate already triggers that one for the
## wall slide, and the two would stack.
const PRESS_SOUND := preload(
		"res://assets/audio/sfx/environment/plate_press_grind1.ogg")
const PRESS_DB := -8.0

## If set, the plate swaps to this art when stepped on instead of just
## dimming — a dedicated pressed state (the magic-heart trigger uses it;
## the boss plate leaves it null and keeps the spent-decor dim).
@export var pressed_texture: Texture2D

## How long `activated` waits after the press, so what the plate sets off
## answers the seating thunk instead of talking over it. The secret plate
## sets this to the sound's length — its wall grind is the same family of
## sound and the two used to start together. The BOSS plate deliberately
## leaves it at 0: its seal has to drop the instant you commit, or you
## could step back out of the arena before the mists close.
@export var activate_delay := 0.0

var used := false

@onready var sprite: Sprite3D = $Sprite
@onready var rim: MeshInstance3D = $Rim


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if used or not body is Player:
		return
	used = true
	$CollisionShape3D.set_deferred("disabled", true)
	Sfx.play_at(PRESS_SOUND, global_position, PRESS_DB)
	var sink := create_tween().set_parallel()
	sink.tween_property(sprite, "position:y", PRESSED_SPRITE_Y, SINK_TIME) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	sink.tween_property(rim, "position:y", PRESSED_RIM_Y, SINK_TIME) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var glow: OmniLight3D = get_node_or_null("Glow")
	if glow != null:
		# Bleeds out as the plate goes down rather than snapping dark the
		# instant it's touched — the sink is long enough now to see it.
		sink.tween_property(glow, "light_energy", 0.0, SINK_TIME)
	if pressed_texture == null:
		# No pressed drawing: the plate just drains to spent decor as it
		# settles, instead of snapping dim under your foot.
		sink.tween_property(sprite, "modulate",
				Color(0.55, 0.55, 0.55), SINK_TIME)
	else:
		# A dedicated pressed-state drawing shows the plate ALREADY down,
		# so it can only land on the seating thunk — swapping it at the
		# touch would read as depressed while still visibly descending.
		sink.chain().tween_callback(sprite.set_texture.bind(pressed_texture))
	if activate_delay > 0.0:
		# A tween, not a timer: it dies with the plate, so a reroll or a
		# death mid-wait can never fire the trigger into a dead floor.
		var wait := create_tween()
		wait.tween_interval(activate_delay)
		wait.tween_callback(activated.emit)
	else:
		activated.emit()
