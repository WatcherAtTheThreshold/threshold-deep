extends Area3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		RunState.descend(body.health)
		get_tree().reload_current_scene.call_deferred()
