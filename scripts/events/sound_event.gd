extends Area3D

@onready var sfx: AudioStreamPlayer3D = $SFX


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		AudioPlayer.get_node("Musics/MapMusic").stream_paused = true
		sfx.play()
		set_deferred("monitoring", false)
		await sfx.finished
		AudioPlayer.get_node("Musics/MapMusic").stream_paused = false
		queue_free()
