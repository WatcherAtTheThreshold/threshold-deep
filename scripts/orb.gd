extends Area3D

const FRAME_A := preload("res://assets/sprites/wizard_orb1.png")
const FRAME_B := preload("res://assets/sprites/wizard_orb2.png")
const SPEED := 6.0
const LIFETIME := 4.0
const FRAME_TIME := 0.15

var direction := Vector3.FORWARD
var time := 0.0

@onready var sprite: Sprite3D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	time += delta
	if time > LIFETIME:
		queue_free()
		return
	position += direction * SPEED * delta
	sprite.texture = FRAME_A if int(time / FRAME_TIME) % 2 == 0 else FRAME_B


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.take_damage(1, direction)
		queue_free()
	elif not body.is_in_group("enemies"):
		# Walls stop orbs; fellow monsters don't (they pass through).
		queue_free()
