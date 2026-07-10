extends Area3D

const HEAL_AMOUNT := 1
const BOB_HEIGHT := 0.08
const BOB_SPEED := 2.0

var time := 0.0
var base_y := 0.0

@onready var sprite: Sprite3D = $Sprite


func _ready() -> void:
	base_y = sprite.position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# The universal "I am a pickup" hover. (No spin — billboards
	# already rotate to face the camera, so a spin would be invisible.)
	time += delta
	sprite.position.y = base_y + sin(time * BOB_SPEED) * BOB_HEIGHT


func _on_body_entered(body: Node3D) -> void:
	# Only consumed if it actually healed — at full health it stays
	# on the floor for later, which rewards remembering where it was.
	if body is Player and body.heal(HEAL_AMOUNT):
		queue_free()
