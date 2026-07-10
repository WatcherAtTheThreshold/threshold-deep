extends CanvasLayer

## Hearts are placeholder red squares until a real 16x16 heart
## sprite exists — then each ColorRect becomes a TextureRect.
const HEART_SIZE := Vector2(30, 30)
const FULL_COLOR := Color(0.88, 0.25, 0.33)
const EMPTY_COLOR := Color(0.2, 0.2, 0.25)

var last_health := 0
var heart_rects: Array[ColorRect] = []

@onready var player: CharacterBody3D = get_parent()
@onready var hearts_box: HBoxContainer = $Hearts
@onready var hurt_flash: ColorRect = $HurtFlash


func _ready() -> void:
	for i in player.MAX_HEALTH:
		var rect := ColorRect.new()
		rect.custom_minimum_size = HEART_SIZE
		hearts_box.add_child(rect)
		heart_rects.append(rect)
	player.health_changed.connect(_on_health_changed)
	last_health = player.health
	_refresh(player.health)


func _on_health_changed(current: int, _maximum: int) -> void:
	if current < last_health:
		hurt_flash.color.a = 0.4
		create_tween().tween_property(hurt_flash, "color:a", 0.0, 0.4)
	last_health = current
	_refresh(current)


func _refresh(current: int) -> void:
	for i in heart_rects.size():
		heart_rects[i].color = FULL_COLOR if i < current else EMPTY_COLOR
