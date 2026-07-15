class_name Player
extends CharacterBody3D

signal health_changed(current: int, maximum: int, magic: int)
signal attacked
signal blocked
signal died

const SPEED := 5.0
const DASH_SPEED := 14.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 1.1
const MOUSE_SENSITIVITY := 0.002
const BASE_MAX_HEALTH := 3
const MAX_HEALTH_CAP := 8
const MAGIC_CAP := 6
const ATTACK_COOLDOWN := 0.5
const ATTACK_RANGE := 2.2
const ATTACK_ARC_DEG := 55.0
const INVULN_TIME := 1.0
const BOOTS_SPEED_MULT := 1.15
const ARMOR_BLOCK_CHANCES: Array[float] = [0.0, 0.25, 0.4]
const ORB_SCENE := preload("res://scenes/orb.tscn")
const STAFF_ORB_TEXTURE := preload("res://assets/sprites/magic_staff_orb1.png")
const BOOMERANG_SCENE := preload("res://scenes/boomerang.tscn")

var max_health := BASE_MAX_HEALTH
var health := BASE_MAX_HEALTH
var magic_hearts := 0
var attack_damage := 1
var move_speed := SPEED
var attack_timer := 0.0
var invuln_timer := 0.0
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_dir := Vector3.ZERO
var boomerang_out := false
var controls_enabled := true

@onready var camera: Camera3D = $Camera3D
@onready var step_sound: AudioStreamPlayer = $StepSound


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if RunState.carried_max_health > 0:
		max_health = RunState.carried_max_health
	if RunState.carried_health > 0:
		health = RunState.carried_health
	magic_hearts = RunState.carried_magic
	health_changed.emit(health, max_health, magic_hearts)
	_apply_loadout()


func pickup_sword() -> void:
	RunState.has_sword = true
	_apply_loadout()


func pickup_staff() -> bool:
	if RunState.has_staff:
		return false
	RunState.has_staff = true
	_apply_loadout()
	return true


func pickup_boomerang() -> bool:
	if RunState.has_boomerang:
		return false
	RunState.has_boomerang = true
	_apply_loadout()
	return true


func boomerang_returned() -> void:
	boomerang_out = false


func pickup_boots() -> bool:
	if RunState.has_boots:
		return false
	RunState.has_boots = true
	_apply_loadout()
	return true


func pickup_armor() -> bool:
	if RunState.armor_tier >= 1:
		return false
	RunState.armor_tier = 1
	_apply_loadout()
	return true


func pickup_armor2() -> bool:
	if RunState.armor_tier >= 2:
		return false
	RunState.armor_tier = 2
	_apply_loadout()
	return true


func _apply_loadout() -> void:
	var weapon := "torch"
	if RunState.has_boomerang:
		weapon = "boomerang"
	elif RunState.has_staff:
		weapon = "staff"
	elif RunState.has_sword:
		weapon = "sword"
	attack_damage = 1 if weapon == "torch" else 2
	move_speed = SPEED * (BOOTS_SPEED_MULT if RunState.has_boots else 1.0)
	$HUD/HandTorch.set_weapon(weapon)
	$HUD/LeftTorch.visible = weapon != "torch"


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
	dash_timer = maxf(dash_timer - delta, 0.0)
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if not controls_enabled:
		# Dead or descending: coast to a stop, no input.
		velocity.x = move_toward(velocity.x, 0.0, SPEED * delta * 4.0)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * delta * 4.0)
		move_and_slide()
		_update_step_audio()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	# Space: short forward burst on a cooldown. Dashes toward your
	# movement direction, or straight ahead when standing still.
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer == 0.0:
		dash_dir = direction if direction else -global_transform.basis.z
		dash_dir.y = 0.0
		dash_dir = dash_dir.normalized()
		dash_timer = DASH_TIME
		dash_cooldown_timer = DASH_COOLDOWN

	if dash_timer > 0.0:
		velocity.x = dash_dir.x * DASH_SPEED
		velocity.z = dash_dir.z * DASH_SPEED
	elif direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

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
	if RunState.has_boomerang and boomerang_out:
		# The hand is empty until the boomerang comes home.
		return
	attack_timer = ATTACK_COOLDOWN
	attacked.emit()
	if RunState.has_boomerang:
		var aim := -camera.global_transform.basis.z
		var boomerang := BOOMERANG_SCENE.instantiate()
		boomerang.thrower = self
		boomerang.direction = aim
		boomerang.position = camera.global_position + aim * 0.9
		get_parent().add_child.call_deferred(boomerang)
		boomerang_out = true
	elif RunState.has_staff:
		# The staff's verb: a bolt where you're looking, pitch and all.
		var aim := -camera.global_transform.basis.z
		var orb := ORB_SCENE.instantiate()
		orb.shooter = self
		orb.frame_a = STAFF_ORB_TEXTURE
		orb.frame_b = STAFF_ORB_TEXTURE
		orb.damage = attack_damage
		orb.direction = aim
		orb.position = camera.global_position + aim * 0.9
		get_parent().add_child.call_deferred(orb)
	else:
		# Melee arc: hit every enemy close enough and roughly in front.
		var forward := -global_transform.basis.z
		for enemy: Node3D in get_tree().get_nodes_in_group("enemies"):
			var to := enemy.global_position - global_position
			to.y = 0.0
			if to.length() <= ATTACK_RANGE \
					and forward.angle_to(to.normalized()) <= deg_to_rad(ATTACK_ARC_DEG):
				enemy.take_damage(attack_damage, to.normalized(), self)
				RunState.record_damage_dealt(attack_damage)
	# The swing also lands on whatever wall you're facing — the
	# dungeon decides if that cell is breakable.
	var from := camera.global_position
	var ray_to := from - camera.global_transform.basis.z * (ATTACK_RANGE + 0.2)
	var query := PhysicsRayQueryParameters3D.create(from, ray_to, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is GridMap:
		var scene := get_tree().current_scene
		if scene.has_method("damage_wall"):
			scene.damage_wall(hit.position, hit.normal, attack_damage)


func heal(amount: int) -> bool:
	# Potions restore red hearts only — magic hearts are temporary.
	if health >= max_health:
		return false
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health, magic_hearts)
	return true


func add_magic_hearts(amount: int) -> bool:
	if magic_hearts >= MAGIC_CAP:
		return false
	magic_hearts = mini(magic_hearts + amount, MAGIC_CAP)
	health_changed.emit(health, max_health, magic_hearts)
	return true


func add_heart_container() -> bool:
	if max_health >= MAX_HEALTH_CAP:
		return false
	max_health += 1
	health = mini(health + 1, max_health)  # the new container comes filled
	health_changed.emit(health, max_health, magic_hearts)
	return true


func take_damage(amount: int, push_dir: Vector3, attacker: PhysicsBody3D = null) -> void:
	if not controls_enabled or invuln_timer > 0.0 or health <= 0:
		return
	if randf() < ARMOR_BLOCK_CHANCES[RunState.armor_tier]:
		# The armor turns the blow — a glancing shove, nothing more.
		blocked.emit()
		velocity += push_dir * 2.5
		return
	invuln_timer = INVULN_TIME
	# Magic hearts absorb damage first; the spill hits red hearts.
	var remaining := amount
	var absorbed := mini(magic_hearts, remaining)
	magic_hearts -= absorbed
	remaining -= absorbed
	health = maxi(health - remaining, 0)
	RunState.record_damage_taken(amount)
	health_changed.emit(health, max_health, magic_hearts)
	velocity += push_dir * 5.0 + Vector3.UP * 2.5
	if health == 0:
		# Remember who did this — name and face — for the death screen.
		var killer_label := "the Dungeon"
		var killer_tex: Texture2D = null
		if attacker != null and is_instance_valid(attacker):
			if attacker.has_method("kill_label"):
				killer_label = attacker.kill_label()
			var attacker_sprite: Sprite3D = attacker.get_node_or_null("Sprite")
			if attacker_sprite != null:
				killer_tex = attacker_sprite.texture
		RunState.set_killer(killer_label, killer_tex)
		controls_enabled = false
		died.emit()


func start_descent() -> void:
	if not controls_enabled:
		return
	controls_enabled = false
	$HUD.start_descent_fade()
