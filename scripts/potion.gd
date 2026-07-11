extends Area3D

const HEAL_AMOUNT := 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	# Only consumed if it actually healed — at full health it stays
	# on the floor for later, which rewards remembering where it was.
	if body is Player and body.heal(HEAL_AMOUNT):
		queue_free()
	elif body.is_in_group("slimes"):
		# Slimes dissolve what they slither over.
		queue_free()
