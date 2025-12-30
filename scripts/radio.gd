extends MeshInstance3D

@export_group("Audio Configuration")
@export var audio_stream : AudioStream
@export var auto_play : bool = false
@export var loop : bool = true

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var is_playing : bool = false

func _ready():
	if audio_stream:
		audio_player.stream = audio_stream
	
	if auto_play:
		is_playing = true
		play_radio()

func interact():
	if is_playing:
		stop_radio()
	else:
		play_radio()

func play_radio():
	if audio_stream:
		audio_player.play()
		is_playing = true
		print("Rádio tocando...")

func stop_radio():
	audio_player.stop()
	is_playing = false
	print("Rádio desligado.")

func _on_audio_stream_player_3d_finished():
	if loop and is_playing:
		audio_player.play()
