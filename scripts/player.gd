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
# Health is measured in half-hearts: 2 units = one heart on the HUD.
const BASE_MAX_HEALTH := 6
const MAX_HEALTH_CAP := 16
const MAGIC_CAP := 12
const ATTACK_COOLDOWN := 0.5
const ATTACK_RANGE := 2.2
const ATTACK_ARC_DEG := 55.0
# Wide Swing: the melee arc opens to catch the flanking tiles too.
const WIDESWING_RANGE := 2.6
const WIDESWING_ARC_DEG := 85.0
# The torch shoves harder than anything after it: taking the sword
# should feel like trading the shove away for damage. Distance goes
# with the SQUARE of this: 1.0 ≈ 0.6m skid, 1.8 ≈ 1.9m, 2.8 ≈ 4.7m.
const TORCH_KNOCKBACK := 1.8
const FALL_DEATH_Y := -1.5
const INVULN_TIME := 1.0
# Crystal tiers index these: none / tier 1 / tier 2.
const FLEET_MULTS: Array[float] = [1.0, 1.15, 1.28]
const HASTY_MULTS: Array[float] = [1.0, 1.3, 1.6]
const ARMOR_BLOCK_CHANCES: Array[float] = [0.0, 0.25, 0.4]
const ORB_SCENE := preload("res://scenes/orb.tscn")
const STAFF_ORB_TEXTURE := preload("res://assets/sprites/magic_staff_orb1.png")
const BOOMERANG_SCENE := preload("res://scenes/boomerang.tscn")
const TORCH_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/torch_hit1.wav"),
	preload("res://assets/audio/sfx/player/torch_hit2.wav"),
	preload("res://assets/audio/sfx/player/torch_hit3.wav"),
]
const SWORD_SLICE_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/sword_slice1.wav"),
	preload("res://assets/audio/sfx/player/sword_slice2.wav"),
	preload("res://assets/audio/sfx/player/sword_slice3.wav"),
]
const TAKE_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/player_take_hit1.wav"),
	preload("res://assets/audio/sfx/player/player_take_hit2.wav"),
	preload("res://assets/audio/sfx/player/player_take_hit3.wav"),
]
const STAFF_ORB_IMPACTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/magic_staff_orb_hit1.wav"),
	preload("res://assets/audio/sfx/player/magic_staff_orb_hit2.wav"),
	preload("res://assets/audio/sfx/player/magic_staff_orb_hit3.wav"),
]
const BOOMERANG_THROW_SOUND := preload("res://assets/audio/sfx/player/boomerang_throw.wav")

var max_health := BASE_MAX_HEALTH
var health := BASE_MAX_HEALTH
var magic_hearts := 0
var attack_damage := 1
var move_speed := SPEED
var attack_timer := 0.0
var invuln_timer := 0.0
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_charges := 1
var dash_dir := Vector3.ZERO
var boomerang_out := false
var controls_enabled := true
var gate_pull := false  # a mist gate's tween owns the body; physics stands down

@onready var camera: Camera3D = $Camera3D
@onready var step_sound: AudioStreamPlayer = $StepSound


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# The torch never stops burning; loop the crackle by hand.
	$TorchCrackle.finished.connect($TorchCrackle.play)
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


func pickup_fleetfoot() -> bool:
	if RunState.fleet_tier >= 1:
		return false
	RunState.fleet_tier = 1
	_apply_loadout()
	return true


func pickup_fleetfoot2() -> bool:
	if RunState.fleet_tier != 1:
		return false
	RunState.fleet_tier = 2
	_apply_loadout()
	return true


func pickup_rage() -> bool:
	if RunState.rage_tier >= 1:
		return false
	RunState.rage_tier = 1
	_apply_loadout()
	return true


func pickup_rage2() -> bool:
	if RunState.rage_tier != 1:
		return false
	RunState.rage_tier = 2
	_apply_loadout()
	return true


func pickup_hasty() -> bool:
	if RunState.hasty_tier >= 1:
		return false
	RunState.hasty_tier = 1
	return true


func pickup_hasty2() -> bool:
	if RunState.hasty_tier != 1:
		return false
	RunState.hasty_tier = 2
	return true


func pickup_luckyluck() -> bool:
	if RunState.lucky:
		return false
	RunState.lucky = true
	return true


func pickup_quickstep() -> bool:
	if RunState.quickstep:
		return false
	RunState.quickstep = true
	return true


func pickup_twicecut() -> bool:
	if RunState.twicecut:
		return false
	RunState.twicecut = true
	return true


func pickup_gapleaper() -> bool:
	if RunState.gapleaper:
		return false
	RunState.gapleaper = true
	return true


func pickup_wideswing() -> bool:
	if RunState.wideswing:
		return false
	RunState.wideswing = true
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
	attack_damage = (2 if weapon == "torch" else 4) + RunState.rage_tier
	move_speed = SPEED * FLEET_MULTS[RunState.fleet_tier]
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
	if gate_pull:
		return
	if controls_enabled and global_position.y < FALL_DEATH_Y:
		# Walked, dashed, or was shoved into the under-place.
		RunState.set_killer("the Dark Below", null)
		health = 0
		health_changed.emit(health, max_health, magic_hearts)
		controls_enabled = false
		$TorchCrackle.stop()
		died.emit()
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
	# Twice-Cut banks two charges; the cooldown refills the bank.
	if dash_cooldown_timer == 0.0:
		dash_charges = 2 if RunState.twicecut else 1
	if Input.is_action_just_pressed("dash") and dash_charges > 0:
		dash_dir = direction if direction else -global_transform.basis.z
		dash_dir.y = 0.0
		dash_dir = dash_dir.normalized()
		# Quickstep stretches the burst.
		dash_timer = DASH_TIME * (1.35 if RunState.quickstep else 1.0)
		dash_charges -= 1
		dash_cooldown_timer = DASH_COOLDOWN

	if dash_timer > 0.0:
		velocity.x = dash_dir.x * DASH_SPEED
		velocity.z = dash_dir.z * DASH_SPEED
		if RunState.gapleaper:
			# The Gapleaper: the dash flies level, so a one-cell gap
			# is a guarantee instead of a gamble.
			velocity.y = 0.0
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
	# The Hasty Little Stone quickens melee swings; ranged weapons
	# keep their rate and get their haste on the projectile instead.
	var melee := not (RunState.has_boomerang or RunState.has_staff)
	attack_timer = ATTACK_COOLDOWN \
			/ (HASTY_MULTS[RunState.hasty_tier] if melee else 1.0)
	attacked.emit()
	if not (RunState.has_boomerang or RunState.has_staff):
		# Melee swings: three takes each, rotated.
		var swings := SWORD_SLICE_SOUNDS if RunState.has_sword else TORCH_HIT_SOUNDS
		Sfx.play_at(swings[randi_range(0, swings.size() - 1)],
				global_position, -4.0)
	if RunState.has_boomerang:
		Sfx.play_at(BOOMERANG_THROW_SOUND, global_position, -4.0)
		var aim := -camera.global_transform.basis.z
		var boomerang := BOOMERANG_SCENE.instantiate()
		boomerang.thrower = self
		boomerang.damage = attack_damage
		boomerang.speed_scale = HASTY_MULTS[RunState.hasty_tier]
		if RunState.wideswing:
			# Wide Swing: a bigger blade sweeps a wider path.
			boomerang.scale = Vector3(1.5, 1.5, 1.5)
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
		orb.impact_sounds = STAFF_ORB_IMPACTS
		orb.damage = attack_damage
		orb.speed_scale = HASTY_MULTS[RunState.hasty_tier]
		orb.splash = RunState.wideswing
		orb.direction = aim
		orb.position = camera.global_position + aim * 0.9
		get_parent().add_child.call_deferred(orb)
	else:
		# Melee arc: hit every enemy close enough and roughly in front.
		# Enemies scale their shove by the push vector's length, so the
		# torch's extra knockback rides in on a longer vector.
		var push_scale := 1.0 if RunState.has_sword else TORCH_KNOCKBACK
		var reach := WIDESWING_RANGE if RunState.wideswing else ATTACK_RANGE
		var arc := WIDESWING_ARC_DEG if RunState.wideswing else ATTACK_ARC_DEG
		var forward := -global_transform.basis.z
		for enemy: Node3D in get_tree().get_nodes_in_group("enemies"):
			var to := enemy.global_position - global_position
			to.y = 0.0
			if to.length() <= reach \
					and forward.angle_to(to.normalized()) <= deg_to_rad(arc):
				enemy.take_damage(attack_damage, to.normalized() * push_scale, self)
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
	max_health += 2
	health = mini(health + 2, max_health)  # the new container comes filled
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
	Sfx.play_ui(TAKE_HIT_SOUNDS[randi_range(0, TAKE_HIT_SOUNDS.size() - 1)], -5.0)
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
		$TorchCrackle.stop()
		died.emit()


func toast(title: String, sub: String) -> void:
	$HUD.show_toast(title, sub)


func start_gate_crossing(through_dir := Vector3.ZERO) -> void:
	# Walking through pale mist to the next stage — no fall, the
	# world whitens into the next title card. The mist pulls you
	# through the doorway plane as it does: a portal, not a wall stop.
	if not controls_enabled:
		return
	controls_enabled = false
	gate_pull = true
	velocity = Vector3.ZERO
	step_sound.stop()
	if through_dir != Vector3.ZERO:
		var pull := global_position + through_dir.normalized() * 1.6
		create_tween().tween_property(self, "global_position", pull, 0.65) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	$HUD.start_gate_fade()


func start_descent(hatch_pos: Vector3) -> void:
	if not controls_enabled:
		return
	controls_enabled = false
	velocity = Vector3.ZERO
	# The fall: glide to the hatch's mouth, then the view sinks into
	# the shaft, gathering speed, as the dark closes over.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:x", hatch_pos.x, 0.25)
	tween.tween_property(self, "global_position:z", hatch_pos.z, 0.25)
	tween.tween_property(camera, "position:y", -1.4, 0.7) \
			.set_delay(0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	$HUD.start_descent_fade()
