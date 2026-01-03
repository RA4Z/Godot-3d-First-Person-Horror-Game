extends Area3D

@export var activate_utils := ""
@export var pause_main_music : bool = true

@onready var sfx: AudioStreamPlayer3D = $SFX


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		AudioPlayer.get_node("Musics/MapMusic").stream_paused = pause_main_music
		sfx.play()
		set_deferred("monitoring", false)
		if activate_utils != "":
			utils.set(activate_utils, true)
		await sfx.finished
		AudioPlayer.get_node("Musics/MapMusic").stream_paused = false
		queue_free()
