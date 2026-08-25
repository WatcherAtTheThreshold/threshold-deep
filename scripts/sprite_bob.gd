extends Sprite3D

## Idle breathing for billboard creatures: the body SQUASHES AND STRETCHES with
## its feet pinned to the floor. Rides on the Sprite, not the body, and touches
## no creature logic — a scene opts in by giving its Sprite this script, and out
## by deleting that one line.
##
## IT IS NOT A BOB, and that was the first attempt's bug. Moving the sprite up
## and down on a sine sends it BELOW its resting position for half the cycle,
## and creature art is bottom-anchored with the feet on the floor — so every
## creature sank into the ground twice a second. Biasing the sine upward only
## fixes the clipping but replaces it with hovering, which is wrong for
## anything that walks. Stretching from a fixed base is the animation actually
## wanted: the feet stay planted and the body rises and settles.
##
## HOW THE BASE IS PINNED. A Sprite3D quad spans `offset.y ± h/2` texture
## pixels, and node scale multiplies that, so scaling alone would drag the feet
## down as the body grew. Compensating:
##
##     bottom = (offset.y - h/2) * s   ==   -h/2      (its unscaled position)
##     offset.y = (h/2) * (1 - 1/s)
##
## which is exactly zero at s = 1, so a creature at rest is untouched.
##
## WHY `scale.y` IS SAFE UNDER BILLBOARDING: billboard mode rewrites the model
## basis to face the camera and can discard scale with it — but these are
## BILLBOARD_FIXED_Y, which preserves the Y axis, and dot.gd already scales a
## FIXED_Y overlay per host and has always rendered correctly. If a sprite ever
## does refuse to scale, the fallback is `pixel_size` (baked into the quad
## geometry rather than the transform), at the cost of growing both axes.
##
## WHAT IT'S FOR: the walk cycles are two frames, and a standing creature has
## NO motion at all — an unnoticed skeleton across a room, a caged specimen, a
## necromancer posted at its bench are all frozen images. The posted wizard is
## the clearest case: a photograph of someone working reads very differently
## from someone actually working, and that beat is why stations exist.

## Fraction of its own height, so it scales with the creature: 0.03 breathes
## between 97% and 103%. Subtle on purpose — this should register as alive,
## never as inflating.
@export var stretch := 0.03
@export var idle_speed := 1.6
## 1.0 keeps walkers at their idle rate, which is right for anything that
## STRIDES: pump a skeleton faster and it reads as hopping, which is comic
## rather than threatening. Blobs are the opposite — raise it for slimes and
## mushes, where the squash IS the locomotion.
@export var walk_multiplier := 1.0
## Metres/sec, matched to the animation blocks' own `moving` test.
@export var move_threshold := 0.3

## THE GAIT: a lift on top of the breath while moving, in texture pixels.
## Strictly UPWARD — `absf(sin())` never goes negative — because that is both
## what stops the sink-into-the-floor bug and what a real stride does: the body
## rises as it swings through and settles as the foot plants. It never dips
## below where it stands.
@export var walk_bob := 0.8
## Humps per second, ON ITS OWN CLOCK rather than the breath's. Walk frames
## flip every ~0.3 s (a 0.6 s two-frame cycle), so driving the gait from
## `idle_speed` would need a multiplier near 6 and would whip the breathing
## into a flutter. 1.7 puts one rise and settle per full walk cycle.
@export var walk_bob_hz := 1.7
## Seconds to blend the gait in and out, so starting and stopping doesn't pop
## the body up or drop it.
@export var gait_blend := 6.0

var clock := 0.0
var gait_clock := 0.0
var gait := 0.0
var half_px := 0.0

@onready var body: Node3D = get_parent()


func _ready() -> void:
	# Desynced from birth, the same way `wander_wait` is: a room of skeletons
	# breathing in phase reads as machinery rather than as bodies.
	clock = randf() * TAU


func _process(delta: float) -> void:
	if body == null:
		return
	if body.get("dead") == true:
		# Corpses don't breathe — and this must RESET rather than freeze. Mush
		# and slime corpses get laid flat on death, and a leftover stretch
		# would smear the splat across the floor along its own axis.
		scale.y = 1.0
		offset.y = 0.0
		gait = 0.0
		return
	# NOT set_process(false) above: a restless skeleton and a respawning slime
	# both clear `dead` and come back, and a body that rose without its breath
	# would be the only still thing in the room.
	var speed := 0.0
	var vel: Variant = body.get("velocity")
	if vel is Vector3:
		# Caged specimens are Node3D and have no velocity at all — `get`
		# returns null, they hold the idle rate, and need no special case.
		speed = Vector2(vel.x, vel.z).length()
	var moving := speed > move_threshold
	var rate := idle_speed
	if moving:
		rate *= walk_multiplier
	# Accumulate rather than sample absolute time: changing the RATE mid-stride
	# then never produces a jump, because the phase carries across.
	clock += delta * rate
	# The gait runs whether or not it's showing, so it's never caught mid-hump
	# when the blend brings it in; `gait` is what fades, not the wave.
	gait_clock += delta * PI * walk_bob_hz
	gait = move_toward(gait, 1.0 if moving else 0.0, delta * gait_blend)
	if texture != null:
		half_px = texture.get_height() * 0.5
	var s := 1.0 + sin(clock) * stretch
	scale.y = s
	# Pin the feet, then lift off that pinned base. absf() keeps the lift at or
	# above zero, so the stride can never push the body back into the floor.
	offset.y = half_px * (1.0 - 1.0 / s) + absf(sin(gait_clock)) * walk_bob * gait
