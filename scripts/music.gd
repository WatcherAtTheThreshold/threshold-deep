extends Node

## Autoload: ambient music that drifts in and out of the dungeon —
## long fades, random entrances, random segments of the track, long
## silences. Persists across floor reloads and deaths; the dungeon's
## music doesn't care about your run.

const VOLUME_DB := -16.0
const FADE_TIME := 8.0
const PLAY_MIN := 40.0
const PLAY_MAX := 80.0
const SILENCE_MIN := 30.0
const SILENCE_MAX := 90.0

const TRACKS: Array[AudioStream] = [
	preload("res://assets/audio/music/threshold-deep.ogg"),
	preload("res://assets/audio/music/AMinorLament.ogg"),
	preload("res://assets/audio/music/AMurderOfCrows.ogg"),
]

var player := AudioStreamPlayer.new()
var started := false


func _ready() -> void:
	player.volume_db = -60.0
	add_child(player)


func begin() -> void:
	# The dungeon starts the drift; the title screen stays silent so its
	# own composed track plays without a dungeon song fading in over it.
	# Guarded so floor reloads don't restart the drift.
	if started:
		return
	started = true
	_drift()


func _drift() -> void:
	# First entrance comes fairly soon; after that, its own rhythm.
	await get_tree().create_timer(randf_range(5.0, 15.0)).timeout
	while true:
		# Each surfacing picks a song, then a place within it.
		var track := TRACKS[randi_range(0, TRACKS.size() - 1)]
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
