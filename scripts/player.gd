class_name Player
extends CharacterBody3D

signal health_changed(current: int, maximum: int)
signal attacked

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.002
const MAX_HEALTH := 5
const ATTACK_COOLDOWN := 0.5
const ATTACK_RANGE := 2.2
const ATTACK_ARC_DEG := 55.0
const INVULN_TIME := 1.0

var health := MAX_HEALTH
var attack_timer := 0.0
var invuln_timer := 0.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Mouse X turns the whole body, mouse Y tilts only the camera.
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x, -PI / 2.0, PI / 2.0)
	elif event.is_action_pressed("attack"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_attack()
		else:
			# Clicking back into the window recaptures instead of swinging.
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		# Esc toggles the mouse in and out of capture.
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)
	invuln_timer = maxf(invuln_timer - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()


func _attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = ATTACK_COOLDOWN
	attacked.emit()
	# Melee arc: hit every enemy close enough and roughly in front.
	var forward := -global_transform.basis.z
	for enemy: Node3D in get_tree().get_nodes_in_group("enemies"):
		var to := enemy.global_position - global_position
		to.y = 0.0
		if to.length() <= ATTACK_RANGE \
				and forward.angle_to(to.normalized()) <= deg_to_rad(ATTACK_ARC_DEG):
			enemy.take_damage(1, to.normalized())


func take_damage(amount: int, push_dir: Vector3) -> void:
	if invuln_timer > 0.0 or health <= 0:
		return
	invuln_timer = INVULN_TIME
	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)
	velocity += push_dir * 5.0 + Vector3.UP * 2.5
	if health == 0:
		print("You died. The dungeon reshuffles its bones...")
		get_tree().reload_current_scene.call_deferred()
