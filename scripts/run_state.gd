extends Node

## Autoload singleton: the state of the current run. Scene reloads
## (new floors, death) rebuild the whole world tree, so anything that
## must survive them lives here.

signal changed

enum FloorKind { REGULAR, BOSS, ITEM }

var depth := 1
var bosses_defeated := 0
var victory_shown := false
var kills := 0
var carried_health := -1  # -1 = fresh run, spawn with full hearts
var carried_max_health := -1  # -1 = fresh run, base containers
var carried_magic := 0
# Weapons are pool items, once each per run; the hand holds the one
# claimed LAST. Crystals apply to whatever is held.
var weapon := "torch"
var has_sword := false
var has_staff := false
var has_boomerang := false
var has_halberd := false
var armor_tier := 0  # 0 none, 1 leather (25% block), 2 steel (40%)
# Crystals (docs/item-plan.md). Tiers: 0 none, 1, 2.
var fleet_tier := 0  # cyan: move speed
var rage_tier := 0   # red: +attack damage in half-heart units
var hasty_tier := 0  # violet: projectile speed + melee rate
var lucky := false   # gold: the deep is generous
var quickstep := false  # cyan: dash goes further
var twicecut := false   # cyan: two dash charges
var gapleaper := false  # cyan: dashes fly level over gaps
var barrelstone := false  # cyan: the dash bowls enemies over (shove into pits)
var wideswing := false  # orange: strikes spread
var rotstone := false   # green: wounds fester (poison ticks)
var emberstone := false # red rough: wounds burn (fire ticks + chars planks)

var damage_dealt := 0
var damage_taken := 0
var kills_by_type := {}
var run_seconds := 0.0   # wall-clock for the whole descent; dungeon.gd feeds it
var secrets_found := 0   # commoner chambers opened — the pale-plank reward
var killer_name := ""
var killer_texture: Texture2D = null


func floor_kind(d: int) -> FloorKind:
	# The run cadence: each world is explore → item → boss.
	# 1-1 regular, 1-2 item, 1-3 BOSS, then world 2... and the
	# pattern continues below the victory floor for endless descent.
	if d % 3 == 2:
		return FloorKind.ITEM
	if d % 3 == 0:
		return FloorKind.BOSS
	return FloorKind.REGULAR


func stage(d: int) -> int:
	return ((d - 1) % 3) + 1


func world(d: int) -> int:
	# The first number in the world-stage label: 1-x → 1, 4-x → 2... every
	# three depths is a new world (three worlds to an act).
	@warning_ignore("integer_division")
	return (d + 2) / 3


func floor_label(d: int) -> String:
	# Depth rendered as world - stage: 1-1, 1-2, 1-3, 2-1...
	return "%d - %d" % [world(d), stage(d)]


func record_kill(label: String) -> void:
	kills += 1
	kills_by_type[label] = kills_by_type.get(label, 0) + 1
	changed.emit()


func record_damage_dealt(amount: int) -> void:
	damage_dealt += amount


func record_damage_taken(amount: int) -> void:
	damage_taken += amount


func record_secret() -> void:
	secrets_found += 1
	changed.emit()


func time_text() -> String:
	var t := int(run_seconds)
	@warning_ignore("integer_division")
	var mins := t / 60  # discarding the remainder IS the point — it's the seconds
	return "%d:%02d" % [mins, t % 60]


func score() -> int:
	# A run SUMMARY, not an arcade meter. It rewards what the design already
	# values — going deep, meeting the whole roster, finding what's hidden,
	# and not getting hit — and none of it can be farmed by grinding one room.
	#
	# TIME IS DELIBERATELY NOT SCORED. These levels reward slowing down and
	# looking: bone piles that stir when you linger, a secret whose only tell
	# is a pale plank, item rooms that respect you for leaving empty-handed. A
	# speed bonus would score the opposite of what the levels are built for.
	# The clock is shown, never rewarded.
	#
	# Kills stay a COMPONENT, not the headline, and they're weighted low on
	# purpose: the dungeon fights itself constantly (slime creep, infight
	# rallies), and only player kills count. Leaning on kills would quietly
	# punish letting the deep do the work — the best thing it does.
	var s := 100 * depth
	s += 250 * bosses_defeated
	s += 10 * kills
	s += 25 * kills_by_type.size()  # variety: meet the roster, don't grind one
	s += 150 * secrets_found
	s += 50 * trophy_count()
	s -= 5 * damage_taken
	return maxi(s, 0)


func trophy_count() -> int:
	# Build-defining pickups claimed, counted off the flags that already exist
	# — no new bookkeeping. Tiered stones count once per tier.
	var n := armor_tier + fleet_tier + rage_tier + hasty_tier
	for flag: bool in [lucky, quickstep, twicecut, gapleaper, barrelstone,
			wideswing, rotstone, emberstone,
			has_sword, has_staff, has_boomerang, has_halberd]:
		if flag:
			n += 1
	return n


func set_killer(label: String, texture: Texture2D) -> void:
	killer_name = label
	killer_texture = texture


func descend(current_health: int, current_max: int, current_magic: int) -> void:
	depth += 1
	carried_health = current_health
	carried_max_health = current_max
	carried_magic = current_magic
	changed.emit()


func reset() -> void:
	print("Run over: reached depth %d in %s with %d kills (dealt %d, took %d) — SCORE %d." \
			% [depth, time_text(), kills, damage_dealt, damage_taken, score()])
	depth = 1
	kills = 0
	run_seconds = 0.0
	secrets_found = 0
	bosses_defeated = 0
	victory_shown = false
	carried_health = -1
	carried_max_health = -1
	carried_magic = 0
	weapon = "torch"
	has_sword = false
	has_staff = false
	has_boomerang = false
	has_halberd = false
	armor_tier = 0
	fleet_tier = 0
	rage_tier = 0
	hasty_tier = 0
	lucky = false
	quickstep = false
	twicecut = false
	gapleaper = false
	barrelstone = false
	wideswing = false
	rotstone = false
	emberstone = false
	damage_dealt = 0
	damage_taken = 0
	kills_by_type = {}
	killer_name = ""
	killer_texture = null
	changed.emit()
