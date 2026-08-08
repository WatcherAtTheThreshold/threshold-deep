class_name Player
extends CharacterBody3D

signal health_changed(current: int, maximum: int, magic: int)
signal attacked
signal torch_attacked  # the off-hand torch shove (drives the left-hand viewmodel)
signal blocked
signal died
signal poisoned(current: int, maximum: int, magic: int)
signal burned(current: int, maximum: int, magic: int)

const SPEED := 5.0
const DASH_SPEED := 16.0    # a punchier burst (was 14)
const DASH_TIME := 0.18
const DASH_COOLDOWN := 1.1
const DASH_FOV_KICK := 12.0  # degrees the view punches out on a dash (power-feel)
const MOUSE_SENSITIVITY := 0.002
# Health is measured in half-hearts: 2 units = one heart on the HUD.
const BASE_MAX_HEALTH := 6
const MAX_HEALTH_CAP := 16
const MAGIC_CAP := 12
const ATTACK_COOLDOWN := 0.5
const ATTACK_RANGE := 2.2
const ATTACK_ARC_DEG := 55.0
# Ranged fire is LOUD: it wakes enemies within this radius (through the
# dungeon's alert system) even ones you didn't hit — so shooting trades
# safety-per-hit for giving away your position, while melee stays quiet.
const NOISE_RADIUS := 9.0
# The halberd's whole pitch is reach; a longer haft than sword or torch.
const HALBERD_RANGE := 3.0
# Wide Swing: the melee arc opens to catch the flanking tiles too.
const WIDESWING_RANGE := 2.6
const WIDESWING_ARC_DEG := 85.0
# Melee recoil: a landed hit shoves YOU back a little, by the weapon's heft.
# Fires on CONNECT, never on a whiff — swinging at air must stay free. Metres
# per second, ADDED to your input velocity rather than replacing it, so it
# bends your movement instead of seizing it (a stagger on the player would
# read as losing control). Travel is v²/(2·friction): torch ~0.05 m, sword
# ~0.14 m, halberd ~0.37 m — all well under a 2 m cell, so your own swing
# can never shove you over a rim.
const MELEE_RECOIL := {"torch": 1.2, "sword": 2.0, "halberd": 3.2}
const RECOIL_FRICTION := 14.0
# Dash contact. A discrete, player-initiated impact — unlike a passive bump,
# which is continuous and would rattle the screen the whole time an enemy
# crowds you. Barrelstone's charge hits harder because it went THROUGH.
const DASH_BUMP_SHAKE := 0.04
const DASH_BUMP_SHAKE_TIME := 0.18
const BARREL_SHAKE := 0.08
const BARREL_SHAKE_TIME := 0.25
# The torch shoves harder than anything after it: taking the sword
# should feel like trading the shove away for damage. Distance goes
# with the SQUARE of this: 1.0 ≈ 0.6m skid, 1.8 ≈ 1.9m, 2.8 ≈ 4.7m.
const TORCH_KNOCKBACK := 1.8
# The off-hand torch (right-click once a weapon is in the main hand): a shove,
# not a swing. Base torch damage, full knockback, its own slower cadence so
# it's a deliberate spacing tool that weaves with the weapon rather than a
# second damage stream. No crystals/walls/dots — the value is the push.
const TORCH_OFFHAND_DAMAGE := 2
const TORCH_OFFHAND_COOLDOWN := 0.6
const FALL_DEATH_Y := -1.5  # default death plane, just under the floor
# The live death plane — the dungeon lowers it when a scripted drop (the
# boss floor cave-in) means the survivable ground is far below the usual one.
var fall_death_y := FALL_DEATH_Y
const INVULN_TIME := 1.0
const POISON_TICKS := 2           # delayed ticks after a slime touch / creep
const POISON_TICK_DAMAGE := 1     # half-heart per tick
const POISON_INTERVAL := 1.2      # seconds between ticks (matches the Rot Dot)
# Burn is poison's twin, deliberately kept as its own channel: a red
# necromancer's fireball can land on an already-poisoned player and both should
# run. Faster than the Rot, matching Dot.gd's 0.8s Ember interval.
const BURN_TICKS := 3
const BURN_TICK_DAMAGE := 1
const BURN_INTERVAL := 0.8
const CREEP_POISON_RANGE := 0.6   # horizontal metres to count as standing in it
const CREEP_SCAN_INTERVAL := 0.25 # throttle the creep proximity check
const LAND_DIP := 0.4       # camera crumple depth at impact (metres)
const LAND_HOLD := 1.5      # hold the crouch through the floor-start mist
							# (mist holds 1.6s then fades 0.9s — see hud.gd)
const LAND_RECOVER := 0.7   # then rise as the mist clears — the VISIBLE beat
const LAND_SOUND := preload("res://assets/audio/sfx/player/start_landing.ogg")
# Crystal tiers index these: none / tier 1 / tier 2.
const FLEET_MULTS: Array[float] = [1.0, 1.2, 1.4]  # Fleetfoot movement speed
const HASTY_MULTS: Array[float] = [1.0, 1.3, 1.6]
const QUICKSTEP_MULT := 1.5  # Quickstep: dash lasts/reaches this much further
const GAPLEAP_MULT := 1.7    # Gapleaper: a longer LEAP (stacks with Quickstep)
const ARMOR_BLOCK_CHANCES: Array[float] = [0.0, 0.25, 0.4]
const ORB_SCENE := preload("res://scenes/orb.tscn")
const STAFF_ORB_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/magic_staff/magic_staff_orb1.png"),
	preload("res://assets/sprites/magic_staff/magic_staff_orb2.png"),
	preload("res://assets/sprites/magic_staff/magic_staff_orb3.png"),
]
const BOOMERANG_SCENE := preload("res://scenes/boomerang.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/pause_menu.tscn")
const TORCH_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/torch_hit1.ogg"),
	preload("res://assets/audio/sfx/player/torch_hit2.ogg"),
	preload("res://assets/audio/sfx/player/torch_hit3.ogg"),
]
const SWORD_SLICE_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/sword_slice1.ogg"),
	preload("res://assets/audio/sfx/player/sword_slice2.ogg"),
	preload("res://assets/audio/sfx/player/sword_slice3.ogg"),
]
const HALBERD_SLICE_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/halberd_slice1.ogg"),
	preload("res://assets/audio/sfx/player/halberd_slice2.ogg"),
	preload("res://assets/audio/sfx/player/halberd_slice3.ogg"),
]
const TAKE_HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/player_take_hit1.ogg"),
	preload("res://assets/audio/sfx/player/player_take_hit2.ogg"),
	preload("res://assets/audio/sfx/player/player_take_hit3.ogg"),
]
const STAFF_ORB_IMPACTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/player/magic_staff_orb_hit1.ogg"),
	preload("res://assets/audio/sfx/player/magic_staff_orb_hit2.ogg"),
	preload("res://assets/audio/sfx/player/magic_staff_orb_hit3.ogg"),
]
const BOOMERANG_THROW_SOUND := preload("res://assets/audio/sfx/player/boomerang_throw.ogg")
const DASH_SOUND := preload("res://assets/audio/sfx/player/footsteps_player_dash1.ogg")
# The two weights of dash contact. The bump sits UNDER the dash swoosh (-3);
# the Barrelstone charge matches it (-1), so the relic is louder as well as
# meatier — the upgrade reads in the mix, not just the sample.
const DASH_BUMP_SOUND := preload("res://assets/audio/sfx/player/dash_bump1.ogg")
const BARREL_STRIKE_SOUND := preload("res://assets/audio/sfx/player/barrel_strike1.ogg")
const BARREL_RANGE := 1.2   # Barrelstone dash-strike contact reach (metres)
const BARREL_DAMAGE := 2    # a shove first, a hit second — mobility, not DPS
const BARREL_PUSH := 2.6    # hard shove (torch is 1.8) — the point is the pits
const BARREL_IFRAME_TAIL := 0.15  # i-frames linger this long after the charge ends
const BARREL_WALL_REACH := 1.5    # how far ahead the charge smashes a wooden wall
const BARREL_WALL_DAMAGE := 10    # enough to break a wooden wall in one barrel

var max_health := BASE_MAX_HEALTH
var health := BASE_MAX_HEALTH
var magic_hearts := 0
var attack_damage := 1
var move_speed := SPEED
var attack_timer := 0.0
var torch_attack_timer := 0.0  # off-hand torch shove cooldown, independent of the weapon
var invuln_timer := 0.0
var poison_ticks := 0
var poison_clock := 0.0
var burn_ticks := 0
var burn_clock := 0.0
var burn_killer := "the Ember"
var burn_killer_tex: Texture2D = null
var poison_killer := ""
var poison_killer_tex: Texture2D = null
var creep_scan := 0.0
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_charges := 1
var dash_dir := Vector3.ZERO
var barrel_hit := {}  # enemies the current dash has already struck (Barrelstone)
var dash_bumped := false  # this dash already thudded into a body (once per dash)
var recoil := Vector3.ZERO  # decaying self-knockback from a landed melee hit
# True while the cell underfoot is plank (dungeon.gd sets it on every cell
# change — it owns the tile ids). Drives the creak, which is a WARNING: the
# boards tell you the ground is temporary before you ever look down.
var on_wood := false
# Footstep level by surface. The creak and the steps share a frequency band, so
# past a point raising the creak just makes the mix louder instead of clearer —
# the punch comes from CONTRAST. Ducking the steps on planks opens ~8dB of
# space under the creak (which sits at -6 on $CreakSound), and it's honest
# besides: wood absorbs a footfall where stone rings.
# NOTE: these OVERWRITE $StepSound's scene volume every frame — tune here,
# not in player.tscn.
const STEP_DB_STONE := -10.0
const STEP_DB_WOOD := -14.0
var base_fov := 75.0  # camera's rest FOV, captured in _ready (for the dash kick)
var fov_tween: Tween  # the dash FOV recovery, killed on a fresh dash
var _shake_dur := 0.0     # camera-shake countdown (0 = still)
var _shake_elapsed := 0.0
var _shake_strength := 0.0
var _shake_base := Vector3.ZERO  # the camera rest pos the shake perturbs around
var boomerang_out := false
var controls_enabled := true
var gate_pull := false  # a mist gate's tween owns the body; physics stands down

@onready var camera: Camera3D = $Camera3D
@onready var step_sound: AudioStreamPlayer = $StepSound
@onready var creak_sound: AudioStreamPlayer = $CreakSound


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_fov = camera.fov
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
	RunState.weapon = "sword"
	_apply_loadout()


func pickup_staff() -> bool:
	if RunState.has_staff:
		return false
	RunState.has_staff = true
	RunState.weapon = "staff"
	_apply_loadout()
	return true


func pickup_boomerang() -> bool:
	if RunState.has_boomerang:
		return false
	RunState.has_boomerang = true
	RunState.weapon = "boomerang"
	_apply_loadout()
	return true


func pickup_halberd() -> bool:
	if RunState.has_halberd:
		return false
	RunState.has_halberd = true
	RunState.weapon = "halberd"
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


func pickup_barrelstone() -> bool:
	if RunState.barrelstone:
		return false
	RunState.barrelstone = true
	return true


func _dash_bump() -> void:
	# No Barrelstone: charging a body doesn't hurt it, but it isn't nothing —
	# a dull thud that says the dash stopped at something solid. Once per dash,
	# and deliberately weaker than the Barrelstone version, so the relic reads
	# as an upgrade to a feel the player already knows.
	if dash_bumped:
		return
	for node: Node3D in get_tree().get_nodes_in_group("enemies"):
		if node.get("dead") == true:
			continue
		if global_position.distance_to(node.global_position) <= BARREL_RANGE:
			dash_bumped = true
			shake(DASH_BUMP_SHAKE, DASH_BUMP_SHAKE_TIME)
			Sfx.play_ui(DASH_BUMP_SOUND, -3.0)
			return


func _barrel_strike() -> void:
	# Barrelstone: the dash is a shoulder-charge. Any enemy it barrels into
	# takes a hit and flies off your momentum — ideally over a rim (the whole
	# reason to run it). Once per enemy per dash; credited to you, so shoving
	# a creature into a pit counts as your kill.
	for node: Node3D in get_tree().get_nodes_in_group("enemies"):
		if barrel_hit.has(node.get_instance_id()) or node.get("dead") == true:
			continue
		if global_position.distance_to(node.global_position) <= BARREL_RANGE:
			node.take_damage(BARREL_DAMAGE, dash_dir * BARREL_PUSH, self)
			barrel_hit[node.get_instance_id()] = true
			RunState.record_damage_dealt(BARREL_DAMAGE)
			shake(BARREL_SHAKE, BARREL_SHAKE_TIME)
			if not dash_bumped:
				# The SOUND is once per dash, not per body: charging through
				# three skeletons is one event to the player, and three copies
				# of the same sample a frame apart machine-guns. The shake
				# still fires per hit — harmlessly, since shake() takes the max.
				dash_bumped = true
				Sfx.play_ui(BARREL_STRIKE_SOUND, -1.0)
	# Barrel THROUGH breakable walls: a short ray along the dash — the
	# dungeon smashes the cell if it's wooden (stone just stops you). It
	# breaks a hair before you reach it, so you charge through clean.
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(
			from, from + dash_dir * BARREL_WALL_REACH, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is GridMap:
		var scene := get_tree().current_scene
		if scene.has_method("damage_wall"):
			scene.damage_wall(hit.position, hit.normal, BARREL_WALL_DAMAGE)


func pickup_wideswing() -> bool:
	if RunState.wideswing:
		return false
	RunState.wideswing = true
	return true


func pickup_rotstone() -> bool:
	if RunState.rotstone:
		return false
	RunState.rotstone = true
	return true


func pickup_emberstone() -> bool:
	if RunState.emberstone:
		return false
	RunState.emberstone = true
	return true


func apply_dots(target: Node) -> void:
	# Every player-dealt hit carries the held afflictions.
	if RunState.weapon == "torch":
		# The torch is a flame, so it burns without a relic — but Cinder is a
		# lesser kind than Ember: one tick, no light, no plank charring, no
		# residue. It layers WITH Emberstone rather than being replaced by it,
		# so the relic is what turns the torch into a build. Main hand only;
		# the off-hand shove stays a control tool (see _torch_attack).
		Dot.attach(target, self, "Cinder")
	if RunState.rotstone:
		Dot.attach(target, self, "Rot")
	if RunState.emberstone:
		Dot.attach(target, self, "Ember")


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
	var weapon := RunState.weapon
	attack_damage = (2 if weapon == "torch" else 4) + RunState.rage_tier
	move_speed = SPEED * FLEET_MULTS[RunState.fleet_tier]
	$HUD/HandTorch.set_weapon(weapon)
	$HUD/LeftTorch.visible = weapon != "torch"


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Mouse X turns the whole body, mouse Y tilts only the camera.
		# MOUSE_SENSITIVITY is the baseline; MetaState carries the player's
		# multiplier from Options, so the const stays the thing to tune and
		# the slider stays a preference on top of it.
		var sens := MOUSE_SENSITIVITY * MetaState.mouse_sensitivity
		rotate_y(-event.relative.x * sens)
		camera.rotate_x(-event.relative.y * sens)
		camera.rotation.x = clampf(camera.rotation.x, -PI / 2.0, PI / 2.0)
	elif event.is_action_pressed("attack"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_attack()
		else:
			# Clicking back into the window recaptures instead of swinging.
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("torch_attack"):
		# The off-hand torch shove — live only once a weapon fills the main
		# hand (before that the torch IS the main hand, on left-click).
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED \
				and RunState.weapon != "torch":
			_torch_attack()
	elif event.is_action_pressed("ui_cancel"):
		# Esc opens the pause menu, which frees the mouse and takes over Esc
		# from there. It used to only toggle mouse capture — that left the
		# controls unlisted anywhere in-game and gave a stuck player nothing
		# but Alt-F4.
		_open_pause()


func _open_pause() -> void:
	# Never over the death report, the victory screen, or a floor transition:
	# those own the moment, and `controls_enabled` is already false for exactly
	# those states (it's what the boss-drop plunge uses too).
	if not controls_enabled or get_tree().paused:
		return
	var menu := PAUSE_MENU_SCENE.instantiate()
	# Parented to the SCENE, not the player — a pause menu that dies with the
	# body it hangs on is not a pause menu.
	get_tree().current_scene.add_child(menu)
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func shake(strength: float, duration: float) -> void:
	# A camera kick — the floor caving, a heavy landing. Perturbs the camera
	# around its rest pos and settles. Captures the rest pos only on a fresh
	# shake so re-triggers don't bake in an offset.
	if _shake_dur <= 0.0:
		_shake_base = camera.position
	_shake_strength = maxf(_shake_strength, strength)
	_shake_dur = duration
	_shake_elapsed = 0.0


func _apply_shake(delta: float) -> void:
	if _shake_dur <= 0.0:
		return
	_shake_elapsed += delta
	if _shake_elapsed >= _shake_dur:
		camera.position = _shake_base
		_shake_dur = 0.0
		return
	# Decay to nothing over the duration; jitter X/Y, leave depth alone.
	var amp := _shake_strength * (1.0 - _shake_elapsed / _shake_dur)
	camera.position = _shake_base + Vector3(
			randf_range(-amp, amp), randf_range(-amp, amp), 0.0)


func _physics_process(delta: float) -> void:
	if gate_pull:
		return
	_apply_shake(delta)
	if controls_enabled and global_position.y < fall_death_y:
		# Walked, dashed, or was shoved into the under-place.
		RunState.set_killer("the Dark Below", null)
		health = 0
		health_changed.emit(health, max_health, magic_hearts)
		controls_enabled = false
		$TorchCrackle.stop()
		died.emit()
	attack_timer = maxf(attack_timer - delta, 0.0)
	torch_attack_timer = maxf(torch_attack_timer - delta, 0.0)
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

	# Poison runs OUTSIDE the hit path: no i-frames, no knock-pop, no melee
	# sound — a quiet green drain from a slime's touch or a stretch spent in
	# fresh creep (which keeps it topped up while you linger).
	creep_scan -= delta
	if creep_scan <= 0.0:
		creep_scan = CREEP_SCAN_INTERVAL
		_check_creep()
	if poison_ticks > 0:
		poison_clock += delta
		if poison_clock >= POISON_INTERVAL:
			poison_clock -= POISON_INTERVAL
			poison_ticks -= 1
			_apply_poison_tick()
		if poison_ticks == 0:
			poison_clock = 0.0
	if burn_ticks > 0:
		burn_clock += delta
		if burn_clock >= BURN_INTERVAL:
			burn_clock -= BURN_INTERVAL
			burn_ticks -= 1
			_apply_burn_tick()
		if burn_ticks == 0:
			burn_clock = 0.0

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
		# Quickstep and Gapleaper each stretch the burst — and they stack
		# multiplicatively, so both together is a room-crossing bound.
		dash_timer = DASH_TIME \
				* (QUICKSTEP_MULT if RunState.quickstep else 1.0) \
				* (GAPLEAP_MULT if RunState.gapleaper else 1.0)
		dash_charges -= 1
		dash_cooldown_timer = DASH_COOLDOWN
		# The dash swoosh.
		Sfx.play_ui(DASH_SOUND, -1.0)
		barrel_hit.clear()  # a fresh dash can strike each enemy once
		dash_bumped = false
		# Power-feel: the view punches out on the burst, then eases back over
		# the dash — the classic first-person sense of speed.
		camera.fov = base_fov + DASH_FOV_KICK
		if fov_tween and fov_tween.is_valid():
			fov_tween.kill()
		fov_tween = create_tween()
		fov_tween.tween_property(camera, "fov", base_fov, dash_timer) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if RunState.barrelstone:
			# Barrelstone: untouchable through the charge and a beat after —
			# dash INTO danger, shove it off a rim, and come out clean.
			invuln_timer = maxf(invuln_timer, dash_timer + BARREL_IFRAME_TAIL)

	if dash_timer > 0.0:
		velocity.x = dash_dir.x * DASH_SPEED
		velocity.z = dash_dir.z * DASH_SPEED
		if RunState.gapleaper:
			# The Gapleaper: a longer leap (GAPLEAP_MULT, set above) that
			# flies DEAD level — clears a two-cell gap outright instead of
			# just barely making one, and the level flight means no fall to
			# gamble on at the far lip.
			velocity.y = 0.0
		if RunState.barrelstone:
			_barrel_strike()
		else:
			_dash_bump()
	elif direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	# Melee recoil rides ON TOP of whatever the movement branch decided, so a
	# hit nudges you without ever taking the controls away — walk into it and
	# you barely move; stand still and you drift back off your own swing.
	if recoil.length_squared() > 0.0:
		velocity.x += recoil.x
		velocity.z += recoil.z
		recoil = recoil.move_toward(Vector3.ZERO, RECOIL_FRICTION * delta)

	move_and_slide()
	_update_step_audio()


func _update_step_audio() -> void:
	# The step file is a walking loop: run it while walking, cut it
	# when airborne, still, or dead.
	var walking := controls_enabled and is_on_floor() \
			and Vector2(velocity.x, velocity.z).length() > 0.5
	step_sound.volume_db = STEP_DB_WOOD if on_wood else STEP_DB_STONE
	if walking and not step_sound.playing:
		step_sound.play()
	elif not walking and step_sound.playing:
		step_sound.stop()
	# Planks complain under your weight. Layered OVER the footstep loop rather
	# than replacing it — you still hear yourself walking, the wood just
	# objects. Same loop-while-moving rule as the steps.
	var creaking := walking and on_wood
	if creaking and not creak_sound.playing:
		creak_sound.play()
	elif not creaking and creak_sound.playing:
		creak_sound.stop()


func _attack() -> void:
	if attack_timer > 0.0:
		return
	if RunState.weapon == "boomerang" and boomerang_out:
		# The hand is empty until the boomerang comes home.
		return
	# The Hasty Little Stone quickens melee swings; ranged weapons
	# keep their rate and get their haste on the projectile instead.
	var melee := RunState.weapon == "torch" or RunState.weapon == "sword" \
			or RunState.weapon == "halberd"
	attack_timer = ATTACK_COOLDOWN \
			/ (HASTY_MULTS[RunState.hasty_tier] if melee else 1.0)
	attacked.emit()
	if melee:
		# Melee swings: three takes each, rotated.
		var swings := TORCH_HIT_SOUNDS
		if RunState.weapon == "sword":
			swings = SWORD_SLICE_SOUNDS
		elif RunState.weapon == "halberd":
			swings = HALBERD_SLICE_SOUNDS
		Sfx.play_at(swings[randi_range(0, swings.size() - 1)],
				global_position, -4.0)
	if RunState.weapon == "boomerang":
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
		_make_noise(NOISE_RADIUS)  # the throw is loud — nearby sleepers wake
	elif RunState.weapon == "staff":
		# The staff's verb: a bolt where you're looking, pitch and all.
		var aim := -camera.global_transform.basis.z
		var orb := ORB_SCENE.instantiate()
		orb.shooter = self
		# Three frames, not the necromancers' two-beat — orb.gd's `frames`
		# array takes over when it's non-empty.
		orb.frames = STAFF_ORB_FRAMES
		orb.impact_sounds = STAFF_ORB_IMPACTS
		orb.damage = attack_damage
		orb.speed_scale = HASTY_MULTS[RunState.hasty_tier]
		orb.splash = RunState.wideswing
		orb.direction = aim
		orb.position = camera.global_position + aim * 0.9
		get_parent().add_child.call_deferred(orb)
		_make_noise(NOISE_RADIUS)  # the bolt is loud — nearby sleepers wake
	else:
		# Melee arc: hit every enemy close enough and roughly in front.
		# Enemies scale their shove by the push vector's length, so the
		# torch's extra knockback rides in on a longer vector.
		var push_scale := TORCH_KNOCKBACK if RunState.weapon == "torch" else 1.0
		# Wide Swing adds its bonus on top of whatever reach the weapon
		# already has, rather than overriding it — so it can never
		# shrink the halberd's longer haft.
		var reach := HALBERD_RANGE if RunState.weapon == "halberd" else ATTACK_RANGE
		var arc := ATTACK_ARC_DEG
		if RunState.wideswing:
			reach += WIDESWING_RANGE - ATTACK_RANGE
			arc = WIDESWING_ARC_DEG
		var forward := -global_transform.basis.z
		var landed := false
		for enemy: Node3D in get_tree().get_nodes_in_group("enemies"):
			var to := enemy.global_position - global_position
			to.y = 0.0
			if to.length() <= reach \
					and forward.angle_to(to.normalized()) <= deg_to_rad(arc):
				enemy.take_damage(attack_damage, to.normalized() * push_scale, self)
				apply_dots(enemy)
				RunState.record_damage_dealt(attack_damage)
				landed = true
		if landed:
			# Straight back, not away from the body — one swing gives one kick
			# no matter how many it caught, and the push can never come at you
			# sideways and walk you off a rim you weren't looking at.
			var kick: float = MELEE_RECOIL.get(RunState.weapon, 0.0)
			recoil = -forward * kick
	# The swing also lands on whatever wall you're facing — the
	# dungeon decides if that cell is breakable. Matches the melee
	# reach above so a halberd pokes walls as far as it pokes enemies.
	var wall_reach := HALBERD_RANGE if RunState.weapon == "halberd" else ATTACK_RANGE
	var from := camera.global_position
	var ray_to := from - camera.global_transform.basis.z * (wall_reach + 0.2)
	var query := PhysicsRayQueryParameters3D.create(from, ray_to, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is GridMap:
		var scene := get_tree().current_scene
		if scene.has_method("damage_wall"):
			scene.damage_wall(hit.position, hit.normal, attack_damage)


func _make_noise(radius: float) -> void:
	# A loud action (ranged fire) carries: the dungeon wakes enemies within
	# radius of us — hit or not. No-op outside the dungeon (title/test room).
	var scene := get_tree().current_scene
	if scene and scene.has_method("_alert_around"):
		scene._alert_around(global_position, radius, null)


func _torch_attack() -> void:
	# The torch as a shield: a shove that barely scratches (base torch
	# damage) but keeps its full knockback — spacing, interrupts, and
	# pit-work while the main weapon does the killing. Its own cooldown, so
	# it weaves freely with the weapon. It DOES break wooden walls, same as
	# the main-hand torch (two shoves), so the off-hand can open a way in.
	#
	# The dividing line is INTRINSIC vs ACQUIRED, not main hand vs off. No
	# crystals and no relic dots here — Rot and Ember are earned, and letting
	# a free second attack carry them is how weapon choice stops mattering.
	# Cinder is different: it isn't a relic, it's what a torch IS, and a
	# burning brand that stops setting things alight in your other hand is
	# the odd rule. It also teaches the shove exists — before Cinder the
	# off-hand gave no feedback a bump didn't. That's why this doesn't call
	# apply_dots (which would drag the relics along) and attaches directly.
	# Any FUTURE torch upgrades stay main-hand: the off-hand gets the taste,
	# the main hand is where fire scales — hence the shorter tick count here
	# than a held torch lays (Dot's fire ladder: shove 1, hold 2, Ember 3).
	if torch_attack_timer > 0.0:
		return
	torch_attack_timer = TORCH_OFFHAND_COOLDOWN
	torch_attacked.emit()
	Sfx.play_at(TORCH_HIT_SOUNDS[randi_range(0, TORCH_HIT_SOUNDS.size() - 1)],
			global_position, -4.0)
	var forward := -global_transform.basis.z
	for enemy: Node3D in get_tree().get_nodes_in_group("enemies"):
		var to := enemy.global_position - global_position
		to.y = 0.0
		if to.length() <= ATTACK_RANGE \
				and forward.angle_to(to.normalized()) <= deg_to_rad(ATTACK_ARC_DEG):
			enemy.take_damage(
					TORCH_OFFHAND_DAMAGE, to.normalized() * TORCH_KNOCKBACK, self)
			Dot.attach(enemy, self, "Cinder", Dot.CINDER_OFFHAND_TICKS)
			RunState.record_damage_dealt(TORCH_OFFHAND_DAMAGE)
	# The shove also smacks whatever wall you're facing — breaks a wooden
	# wall in two, matching the main torch's bite (damage_wall counts each
	# point as a hit).
	var from := camera.global_position
	var ray_to := from - camera.global_transform.basis.z * (ATTACK_RANGE + 0.2)
	var query := PhysicsRayQueryParameters3D.create(from, ray_to, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is GridMap:
		var scene := get_tree().current_scene
		if scene.has_method("damage_wall"):
			scene.damage_wall(hit.position, hit.normal, TORCH_OFFHAND_DAMAGE)


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


func take_poison(source_label := "the Rot", source_tex: Texture2D = null) -> void:
	# A festering wound: delayed ticks that refresh (never stack). Runs
	# outside take_damage on purpose. The clock is NOT reset on refresh, so
	# continuous creep contact keeps ticking rather than postponing forever.
	if not controls_enabled or health <= 0:
		return
	poison_ticks = POISON_TICKS
	poison_killer = source_label
	poison_killer_tex = source_tex


func _apply_poison_tick() -> void:
	# Magic hearts soak poison first, same as any damage; the spill hits
	# red. No i-frames granted or checked — the wound just works.
	var remaining := POISON_TICK_DAMAGE
	var absorbed := mini(magic_hearts, remaining)
	magic_hearts -= absorbed
	remaining -= absorbed
	health = maxi(health - remaining, 0)
	RunState.record_damage_taken(POISON_TICK_DAMAGE)
	poisoned.emit(health, max_health, magic_hearts)
	if health == 0:
		RunState.set_killer(poison_killer, poison_killer_tex)
		controls_enabled = false
		$TorchCrackle.stop()
		died.emit()


func take_burn(source_label := "the Ember", source_tex: Texture2D = null) -> void:
	# The red necromancer's fireball keeps working after it lands. Runs OUTSIDE
	# take_damage for the same reason poison does: i-frames would swallow ticks
	# at random and each tick would fire the hit sound like a fresh blow.
	# Refresh, never stack — the clock is not reset, so standing in fire keeps
	# burning rather than postponing the next tick forever.
	if not controls_enabled or health <= 0:
		return
	burn_ticks = BURN_TICKS
	burn_killer = source_label
	burn_killer_tex = source_tex


func _apply_burn_tick() -> void:
	# Magic hearts soak the burn first, same as poison and any other damage.
	# No i-frames granted or checked.
	var remaining := BURN_TICK_DAMAGE
	var absorbed := mini(magic_hearts, remaining)
	magic_hearts -= absorbed
	remaining -= absorbed
	health = maxi(health - remaining, 0)
	RunState.record_damage_taken(BURN_TICK_DAMAGE)
	burned.emit(health, max_health, magic_hearts)
	if health == 0:
		RunState.set_killer(burn_killer, burn_killer_tex)
		controls_enabled = false
		$TorchCrackle.stop()
		died.emit()


func _check_creep() -> void:
	# Standing in a still-wet creep patch re-poisons. Dried creep (faded
	# past the threshold) is inert, so old trails go safe and only the
	# fresh path a slime just laid is a hazard — readable and dodgeable.
	for node: Node3D in get_tree().get_nodes_in_group("creep"):
		var patch := node as Sprite3D
		if patch == null or patch.modulate.a <= 0.3:
			continue
		var flat := Vector2(global_position.x - node.global_position.x,
				global_position.z - node.global_position.z).length()
		if flat <= CREEP_POISON_RANGE:
			take_poison("Creep")
			return


func toast(title: String, sub: String) -> void:
	$HUD.show_toast(title, sub)


func land_hard() -> void:
	# The hard arrival: you fell onto this x-1 floor. The camera CRUMPLES at
	# impact and the thud plays now (mostly hidden by the floor-start mist),
	# HOLDS the crouch through the mist, then RISES as it clears — so the
	# readable beat (standing up out of the landing) happens when you can
	# actually see it. Movement is held until you're on your feet; mouselook
	# stays live, so you can look around the room revealing itself.
	controls_enabled = false
	velocity = Vector3.ZERO
	var rest_y := camera.position.y
	camera.position.y = rest_y - LAND_DIP
	Sfx.play_ui(LAND_SOUND, -3.0)
	var tw := create_tween()
	tw.tween_interval(LAND_HOLD)
	tw.tween_property(camera, "position:y", rest_y, LAND_RECOVER) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: controls_enabled = true)


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
