extends CanvasLayer

@export var video_resource: VideoStream
@export var audio_resource: AudioStream
@export var duration: float = 5

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var anim_player: AnimationPlayer = $AnimPlayer

func _ready():
	hide()
	# Garante que o player de vídeo preencha a tela se necessário
	video_player.expand = true 

func start_jumpscare():
	show()
	
	if video_resource:
		video_player.stream = video_resource
	if audio_resource:
		audio_player.stream = audio_resource
	
	video_player.show()
	video_player.play()
	audio_player.play()
	
	if anim_player.has_animation("shake"):
		anim_player.play("shake")
	
	# ESSENCIAL: Espera o vídeo terminar antes de fechar a função
	await get_tree().create_timer(duration).timeout
	video_player.stop()
	audio_player.stop()
	hide()
	return
