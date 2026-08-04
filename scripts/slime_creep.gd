extends Sprite3D

## Caustic residue a slime leaves as it moves. It lies flat, lingers, then
## dries (fades) and frees itself. Parented to the dungeon rather than the
## slime, so a dead slime's trail still fades — and still bites — on its own.
##
## ACTIVE WHILE WET (promoted from cosmetic 2026-08-02): any creature standing
## in a fresh patch starts to rot, credited to the slime that laid it, so the
## victim turns on the slime under the normal infighting rule. Blobs no longer
## only seed brawls where they stand — they seed them everywhere they've been.
##
## The PLAYER is deliberately NOT handled here: player damage-over-time runs on
## its own channel (`player.take_poison`, outside `take_damage`), swept from
## `player._check_creep` against the same wetness gate. Two paths, one rule.

const LINGER := 4.0    # full-strength seconds before it begins to dry
const FADE := 3.0      # seconds to fade out
const FULL_ALPHA := 0.8
const WET_ALPHA := 0.3      # dried past this and the patch is inert
const TOUCH_RANGE := 0.6    # horizontal metres that count as standing in it
const SCAN_INTERVAL := 0.4  # throttle; patches desync themselves on spawn

var source: CharacterBody3D = null  # the slime that laid it, for Dot credit
var scan := 0.0


func _ready() -> void:
	# Lie flat with a random spin and a hair of height jitter, so
	# overlapping patches layer into a smear instead of z-fighting.
	rotation_degrees = Vector3(-90.0, randf() * 360.0, 0.0)
	position.y += randf() * 0.02
	modulate.a = FULL_ALPHA
	# Stagger the sweeps: a long trail is many patches, and they must not all
	# scan on the same frame.
	scan = randf() * SCAN_INTERVAL
	var tw := create_tween()
	tw.tween_interval(LINGER)
	tw.tween_property(self, "modulate:a", 0.0, FADE)
	tw.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	# Only a WET patch bites. Dried trails go inert on the same alpha gate the
	# player's sweep uses, so the hazard is the path a slime just laid — it
	# reads on screen, and it disarms itself without any bookkeeping.
	if modulate.a <= WET_ALPHA:
		return
	scan -= delta
	if scan > 0.0:
		return
	scan = SCAN_INTERVAL
	for e: Node3D in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.get("dead") == true:
			continue
		if e.is_in_group("slimes"):
			continue  # kin wade through their own
		var flat := Vector2(e.global_position.x - global_position.x,
				e.global_position.z - global_position.z).length()
		if flat <= TOUCH_RANGE:
			# Credited to the slime that laid it, exactly like the caustic
			# touch — so the victim turns on the slime. An orphaned patch (its
			# slime already dead) still burns, just with nothing to blame.
			Dot.attach(e, source if is_instance_valid(source) else null, "Rot")
