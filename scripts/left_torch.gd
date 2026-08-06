extends TextureRect

# The off-hand torch is a MIRROR of the main-hand torch (viewmodel.gd): the
# same flame frames and the same drawn swing, flipped horizontally and pinned
# to the bottom-LEFT corner. It idles as a passive light while you hold a
# weapon, and plays the full torch swing on the right-click shove
# (player.torch_attacked). Swap in dedicated left-hand frames later under the
# same structure — flip_h off, new textures, nothing else changes.

const TORCH_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/torch/torch_idle1.png"),
	preload("res://assets/sprites/torch/torch_idle2.png"),
	preload("res://assets/sprites/torch/torch_idle3.png"),
]
const TORCH_SWING_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/torch/torch_attack1.png"),
	preload("res://assets/sprites/torch/torch_attack2.png"),
	preload("res://assets/sprites/torch/torch_attack3.png"),
]
# Windup / extended strike / follow-through — same three beats as the right hand.
const TORCH_SWING_TIMES: Array[float] = [0.06, 0.11, 0.10]
const FLICKER_TIME := 0.16
const SWAY_AMOUNT := 6.0
# Mirror of the main-hand torch's corner pin (viewmodel anchor_off = (12,12),
# from its -372 offset + 128*3 slot): the art's bottom-LEFT corner sits this
# far past the screen's bottom-left, so the two hands are symmetric.
const ANCHOR_OFF := Vector2(12.0, 12.0)

@onready var player: Player = get_tree().get_first_node_in_group("player")

var swinging := false
var flicker_clock := 0.0
var bob_time := 0.0
var swing_tween: Tween = null


func _ready() -> void:
	flip_h = true  # the exact horizontal mirror of the right hand
	texture = TORCH_FRAMES[0]
	player.torch_attacked.connect(_on_torch_attack)


func _process(delta: float) -> void:
	if player.health <= 0:
		# Dead hands hold nothing: the death report stands alone.
		visible = false
		return
	var ground_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if ground_speed > 0.1 and player.is_on_floor():
		bob_time += delta * ground_speed * 2.0
	# The flame always flickers, unless a swing owns the frame.
	if not swinging:
		flicker_clock += delta
		texture = TORCH_FRAMES[int(flicker_clock / FLICKER_TIME) % TORCH_FRAMES.size()]
	# Pin the art's bottom-LEFT corner to the corner (the mirror of the right
	# hand's bottom-right pin): force rect size to the texture, pivot at the
	# bottom-left so scale grows up-and-inward, X of the sway negated.
	var tsize := texture.get_size() if texture != null else size
	size = tsize
	pivot_offset = Vector2(0.0, tsize.y)
	position = Vector2(-ANCHOR_OFF.x, get_viewport_rect().size.y + ANCHOR_OFF.y - tsize.y) \
			+ Vector2(
				-sin(bob_time) * SWAY_AMOUNT,
				absf(cos(bob_time)) * SWAY_AMOUNT * 0.5
			)


func _on_torch_attack() -> void:
	# The same drawn arc as the main-hand torch, mirrored: windup → strike →
	# follow, pure frame swaps (no rotation to mirror). No embers yet — the
	# left hand has no Embers node.
	swinging = true
	if swing_tween != null and swing_tween.is_valid():
		swing_tween.kill()
	texture = TORCH_SWING_FRAMES[0]
	swing_tween = create_tween()
	swing_tween.tween_interval(TORCH_SWING_TIMES[0])
	swing_tween.tween_callback(func() -> void:
		texture = TORCH_SWING_FRAMES[1])
	swing_tween.tween_interval(TORCH_SWING_TIMES[1])
	swing_tween.tween_callback(func() -> void:
		texture = TORCH_SWING_FRAMES[2])
	swing_tween.tween_interval(TORCH_SWING_TIMES[2])
	swing_tween.tween_callback(func() -> void:
		texture = TORCH_FRAMES[0]
		swinging = false)
