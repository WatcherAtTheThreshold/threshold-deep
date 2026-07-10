extends CanvasLayer

const HEART_FULL := preload("res://assets/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/ui/heart_empty.png")
const HEART_SIZE := Vector2(48, 48)

var last_health := 0
var heart_icons: Array[TextureRect] = []

@onready var player: Player = get_parent()
@onready var hearts_box: HBoxContainer = $Hearts
@onready var hurt_flash: ColorRect = $HurtFlash


func _ready() -> void:
	for i in player.MAX_HEALTH:
		var icon := TextureRect.new()
		icon.texture = HEART_FULL
		icon.custom_minimum_size = HEART_SIZE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		hearts_box.add_child(icon)
		heart_icons.append(icon)
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
	for i in heart_icons.size():
		heart_icons[i].texture = HEART_FULL if i < current else HEART_EMPTY
