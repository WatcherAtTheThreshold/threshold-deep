extends Node

## Autoload: ambient music that drifts in and out of the dungeon —
## long fades, random entrances, random segments of the track, long
## silences. Persists across floor reloads and deaths; the dungeon's
## music doesn't care about your run.

const VOLUME_DB := -8.0
const FADE_TIME := 5.0
const PLAY_MIN := 40.0
const PLAY_MAX := 90.0
const SILENCE_MIN := 10.0
const SILENCE_MAX := 40.0
# A boss fight OWNS the music: louder than the ambient drift, faded up on the
# consent plate, unbroken until the fight ends. The duck is the 3-3 floor drop
# — the boom gets the room to itself, then the track swells back on the rise.
const BOSS_VOLUME_DB := -5.0
const BOSS_FADE_IN := 1.5
const BOSS_FADE_OUT := 3.0
const DUCK_DB := -30.0
const DUCK_DOWN := 0.3
const DUCK_HOLD := 1.2
const DUCK_UP := 2.5

# --- Per-world track sets (mirrors dungeon.gd's WORLD_APPEARANCE) ---
# A world's music comes from a folder under assets/audio/music/, named for the
# same look its tiles wear — world 2 is "damp" in both its stone and its songs.
# The folders are organization; THESE ARRAYS ARE THE CONTRACT. Dropping an .ogg
# into a folder does nothing until it's preloaded here (runtime directory
# scanning of res:// doesn't survive an export, and this game ships to web).
const DRY_TRACKS: Array[AudioStream] = [  # world 1
	preload("res://assets/audio/music/dry/threshold-deep.ogg"),
]
const DAMP_TRACKS: Array[AudioStream] = [  # world 2
	preload("res://assets/audio/music/damp/AMinorLament.ogg"),
	preload("res://assets/audio/music/damp/AMurderOfCrows.ogg"),
	preload("res://assets/audio/music/damp/summersTale.mp3"),
]
const DEEP_TRACKS: Array[AudioStream] = [  # world 3
	preload("res://assets/audio/music/deep/threshold-deep-remix.mp3"),
]
# The one set keyed to a floor KIND rather than a look: every boss floor
# (1-3, 2-3, 3-3) pulls from here instead of its world's set, so "this music
# means a fight" reads the same way the cold mist does.
const BOSS_TRACKS: Array[AudioStream] = [
	preload("res://assets/audio/music/boss/dungeonBoss.mp3"),
]
const TRACK_SETS := {
	"dry": DRY_TRACKS,
	"damp": DAMP_TRACKS,
	"deep": DEEP_TRACKS,
}
# Index by world, exactly like WORLD_APPEARANCE: [0] is unused, and worlds past
# the demo (endless descent) clamp to the last built set.
const WORLD_SET := ["dry", "dry", "damp", "deep"]

var player := AudioStreamPlayer.new()
var started := false
var gen := 0  # bumped to invalidate a running drift loop
var world := 1  # which set the NEXT surfacing draws from
var boss := false  # on a boss floor the kind wins over the world
var owned := false  # true while a boss fight has claimed the track


func _ready() -> void:
	player.volume_db = -60.0
	player.bus = &"Music"  # so Options can move music without touching SFX
	add_child(player)
	# Boss tracks loop — a fight runs as long as it runs, and the music can't
	# be allowed to simply end mid-amalgam. Safe to set on the shared imported
	# resource because these streams are used for nothing else; `set` is a
	# no-op on a format that doesn't expose the property.
	for t: AudioStream in BOSS_TRACKS:
		t.set("loop", true)


func begin(w := 1, is_boss := false) -> void:
	# The dungeon starts the drift; the title screen stays silent so its
	# own composed track plays without a dungeon song fading in over it.
	# Guarded so floor reloads don't restart the drift.
	# The world is set BEFORE the guard, so descending updates the pool while
	# the drift keeps running: whatever is playing plays out, and the new
	# world's music arrives at the next surfacing. The handoff is a fade and a
	# silence, never a cut — you cross into world 2 and the songs have changed
	# by the time you notice.
	world = w
	boss = is_boss
	# A floor loaded while a fight still owned the music — cleared it, died in
	# it, quit to the title. However it ended, it ended: this one release
	# covers every exit, so no path needs its own hook.
	if owned:
		release()
	if started:
		return
	started = true
	gen += 1
	_drift(gen)


func hush() -> void:
	# Silence the dungeon drift (e.g. returning to the title, which owns
	# its own track) and stop it surfacing again. Bumping gen makes the
	# running loop bail at its next check; begin() can restart it later.
	if not started:
		return
	started = false
	owned = false  # a fight in progress loses its claim along with the drift
	gen += 1
	var t := create_tween()
	t.tween_property(player, "volume_db", -60.0, 1.2)
	t.tween_callback(player.stop)


func take_over() -> void:
	# The consent plate: the fight claims the music. The drift stops surfacing
	# (its loop bails on the bumped gen) and one looping track plays unbroken
	# until the fight ends — no random silence over the amalgam. Everywhere
	# else the dungeon's music ignores your run; here the fight IS the run.
	if owned or BOSS_TRACKS.is_empty():
		return
	owned = true
	gen += 1
	player.stop()
	player.stream = BOSS_TRACKS[randi_range(0, BOSS_TRACKS.size() - 1)]
	player.volume_db = -60.0
	player.play()  # from the top: a fight gets the whole shape of the piece
	create_tween().tween_property(player, "volume_db", BOSS_VOLUME_DB, BOSS_FADE_IN)


func release() -> void:
	# Fight over, either way it went. Fade out and hand the floor back to the
	# drift, which opens on a silence — the dungeon going indifferent again.
	if not owned:
		return
	owned = false
	var t := create_tween()
	t.tween_property(player, "volume_db", -60.0, BOSS_FADE_OUT)
	t.tween_callback(player.stop)
	if started:
		gen += 1
		_drift(gen)


func duck(depth_db := DUCK_DB) -> void:
	# One beat of near-silence for something louder than music — the 3-3 floor
	# giving way. Only meaningful while a fight owns the track; the drift's own
	# entrances are too incidental to be worth interrupting.
	if not owned:
		return
	var t := create_tween()
	t.tween_property(player, "volume_db", depth_db, DUCK_DOWN)
	t.tween_interval(DUCK_HOLD)
	t.tween_property(player, "volume_db", BOSS_VOLUME_DB, DUCK_UP)


func _tracks() -> Array[AudioStream]:
	# This world's set, or the first one if it isn't composed yet — the same
	# graceful fallback the tiles use, so a world can ship its look before it
	# ships its songs and nothing goes silent in between.
	if boss and not BOSS_TRACKS.is_empty():
		return BOSS_TRACKS
	var idx := clampi(world, 1, WORLD_SET.size() - 1)
	var picked: Array[AudioStream] = TRACK_SETS[WORLD_SET[idx]]
	return picked if not picked.is_empty() else DRY_TRACKS


func _drift(my_gen: int) -> void:
	# First entrance comes fairly soon; after that, its own rhythm.
	await get_tree().create_timer(randf_range(5.0, 15.0)).timeout
	while my_gen == gen:
		# Each surfacing picks a set (the world may have changed since the last
		# one), then a song, then a place within it.
		var tracks := _tracks()
		var track := tracks[randi_range(0, tracks.size() - 1)]
		player.stream = track
		var length := track.get_length()
		var start := randf_range(0.0, maxf(length - PLAY_MIN - FADE_TIME, 0.0))
		var play_time := randf_range(PLAY_MIN, PLAY_MAX)
		player.volume_db = -60.0
		player.play(start)
		var fade_in := create_tween()
		fade_in.tween_property(player, "volume_db", VOLUME_DB, FADE_TIME)
		await get_tree().create_timer(maxf(play_time - FADE_TIME, 1.0)).timeout
		var fade_out := create_tween()
		fade_out.tween_property(player, "volume_db", -60.0, FADE_TIME)
		await fade_out.finished
		player.stop()
		await get_tree().create_timer(
				randf_range(SILENCE_MIN, SILENCE_MAX)).timeout
