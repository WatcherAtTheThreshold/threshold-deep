extends Sprite3D

## Caustic residue a slime leaves as it moves. Cosmetic for now — it lies
## flat, lingers, then dries (fades) and frees itself. Parented to the
## dungeon rather than the slime, so a dead slime's trail still fades on
## its own. Phase 3 can promote this into an active poison field.

const LINGER := 4.0    # full-strength seconds before it begins to dry
const FADE := 3.0      # seconds to fade out
const FULL_ALPHA := 0.8


func _ready() -> void:
	# Lie flat with a random spin and a hair of height jitter, so
	# overlapping patches layer into a smear instead of z-fighting.
	rotation_degrees = Vector3(-90.0, randf() * 360.0, 0.0)
	position.y += randf() * 0.02
	modulate.a = FULL_ALPHA
	var tw := create_tween()
	tw.tween_interval(LINGER)
	tw.tween_property(self, "modulate:a", 0.0, FADE)
	tw.tween_callback(queue_free)
