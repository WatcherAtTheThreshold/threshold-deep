class_name Player
extends CharacterBody3D

signal health_changed(current: int, maximum: int)
signal attacked
signal died

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.002
const MAX_HEALTH := 5
const ATTACK_COOLDOWN := 0.5
const ATTACK_RANGE := 2.2
const ATTACK_ARC_DEG := 55.0
const INVULN_TIME := 1.0

var health := MAX_HEALTH
var attack_damage := 1
var attack_timer := 0.0
var invuln_timer := 0.0
var controls_enabled := true

@onready var camera: Camera3D = $Camera3D
@onready var step_sound: AudioStreamPlayer = $StepSound


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if RunState.carried_health > 0:
		health = RunState.carried_health
		health_changed.emit(health, MAX_HEALTH)
	_apply_loadout()


func pickup_sword() -> void:
	RunState.has_sword = true
	_apply_loadout()


func _apply_loadout() -> void:
	attack_damage = 2 if RunState.has_sword else 1
	$HUD/HandTorch.set_sword(RunState.has_sword)
	$HUD/LeftTorch.visible = RunState.has_sword


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
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

	if not controls_enabled:
		# Dead or descending: coast to a stop, no input.
		velocity.x = move_toward(velocity.x, 0.0, SPEED * delta * 4.0)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * delta * 4.0)
		move_and_slide()
		_update_step_audio()
		return

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
	_update_step_audio()


func _update_step_audio() -> void:
	# The step file is a walking loop: run it while walking, cut it
	# when airborne, still, or dead.
	var walking := controls_enabled and is_on_floor() \
			and Vector2(velocity.x, velocity.z).length() > 0.5
	if walking and not step_sound.playing:
		step_sound.play()
	elif not walking and step_sound.playing:
		step_sound.stop()


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
			enemy.take_damage(attack_damage, to.normalized(), self)
	# The swing also lands on whatever wall you're facing — the
	# dungeon decides if that cell is breakable.
	var from := camera.global_position
	var ray_to := from - camera.global_transform.basis.z * (ATTACK_RANGE + 0.2)
	var query := PhysicsRayQueryParameters3D.create(from, ray_to, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is GridMap:
		var scene := get_tree().current_scene
		if scene.has_method("damage_wall"):
			scene.damage_wall(hit.position, hit.normal)


func heal(amount: int) -> bool:
	if health >= MAX_HEALTH:
		return false
	health = mini(health + amount, MAX_HEALTH)
	health_changed.emit(health, MAX_HEALTH)
	return true


func take_damage(amount: int, push_dir: Vector3, _attacker: PhysicsBody3D = null) -> void:
	if not controls_enabled or invuln_timer > 0.0 or health <= 0:
		return
	invuln_timer = INVULN_TIME
	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)
	velocity += push_dir * 5.0 + Vector3.UP * 2.5
	if health == 0:
		controls_enabled = false
		died.emit()


func start_descent() -> void:
	if not controls_enabled:
		return
	controls_enabled = false
	$HUD.start_descent_fade()
