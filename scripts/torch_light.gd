extends OmniLight3D

# The carried torch's LIGHT flickers the way its flame sprite does, so the
# room breathes with the fire instead of sitting under a steady lamp. The
# brightness drifts toward a new random target every few hundredths of a
# second — smooth, not stepped, since a stepped light reads as a strobe.
# Energy only: range stays fixed so the edge of what you can see doesn't
# twitch. The scene's light_energy is the centre the flicker wobbles around.

const FLICKER_AMOUNT := 0.10   # ±10% of the scene energy
const RETARGET_MIN := 0.06     # seconds between new flicker targets
const RETARGET_MAX := 0.16
const FLICKER_SPEED := 14.0    # how fast energy chases its target

var base_energy := 1.0
var target := 1.0
var retarget_timer := 0.0


func _ready() -> void:
	base_energy = light_energy


func _process(delta: float) -> void:
	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = randf_range(RETARGET_MIN, RETARGET_MAX)
		target = 1.0 + randf_range(-FLICKER_AMOUNT, FLICKER_AMOUNT)
	var level := lerpf(light_energy / base_energy, target, 1.0 - exp(-FLICKER_SPEED * delta))
	light_energy = base_energy * level
