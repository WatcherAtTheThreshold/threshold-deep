extends Node

## Meta / session state — survives scene changes AND run resets (unlike
## RunState, which is wiped when a run is born). Tracks whether the title
## flythrough has already played this session, so returning from a death drops
## straight to the settled menu instead of replaying the 16 s walk.
##
## It is ALSO where player settings live, and unlike `intro_seen` those are
## written to disk: `user://settings.cfg`. That path is the browser's IndexedDB
## on a web build, so it survives a reload there too.
##
## Later: the home for banked meta-progression. Settings landing here first is
## deliberate — the save/load plumbing an unlock system needs is the same
## plumbing, already working and already exercised every run.

const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
## Below this the slider reads as "off" and we mute the bus outright — -60 dB
## is inaudible but still costs a voice, and a slider that never truly silences
## is a bad slider.
const MUTE_FLOOR := 0.001

var intro_seen := false

# --- Settings (persisted) ---------------------------------------------------
# Volumes are LINEAR 0..1 because that's what a slider should be; the buses
# want dB, so every write converts. Storing dB instead would make the slider
# feel wrong at the quiet end.
var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 1.0
var mouse_sensitivity := 1.0
var fullscreen := false


func _ready() -> void:
	load_settings()


func apply_audio() -> void:
	_set_bus(&"Master", master_volume)
	_set_bus(MUSIC_BUS, music_volume)
	_set_bus(SFX_BUS, sfx_volume)


func _set_bus(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return  # bus layout missing — fail quiet rather than crash the menu
	AudioServer.set_bus_mute(idx, linear <= MUTE_FLOOR)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, MUTE_FLOOR)))


func apply_window() -> void:
	# Never touch the window mode on web: the browser owns the viewport, and
	# forcing it there fights the itch embed rather than filling the screen.
	if OS.has_feature("web"):
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN \
			if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	# A missing file is the normal first-run case, not an error — the defaults
	# above stand and get written the first time anything is changed.
	if cfg.load(SETTINGS_PATH) == OK:
		master_volume = cfg.get_value("audio", "master", master_volume)
		music_volume = cfg.get_value("audio", "music", music_volume)
		sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
		mouse_sensitivity = cfg.get_value("input", "mouse_sensitivity", mouse_sensitivity)
		fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	apply_audio()
	apply_window()
