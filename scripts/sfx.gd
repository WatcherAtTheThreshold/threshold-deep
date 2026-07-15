extends Node

## Autoload: fire-and-forget sounds that must survive scene reloads —
## a pickup grabbed beside the hatch shouldn't be cut off mid-chime
## by the descent.


func play_at(stream: AudioStream, position: Vector3, volume_db := 0.0, pitch := 1.0) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	add_child(p)
	p.global_position = position
	p.finished.connect(p.queue_free)
	p.play()


func play_ui(stream: AudioStream, volume_db := -6.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
