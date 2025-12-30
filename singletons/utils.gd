extends Node

func jumpscare_video(audio_stream_player: AudioStreamPlayer, video_player: VideoStreamPlayer, anim_player: AnimationPlayer):
	get_tree().paused = true
	audio_stream_player.play()
	video_player.show()
	video_player.play()
	anim_player.play("shake")
	await video_player.finished
	inventory.set_default_values()
	get_tree().paused = false
	get_tree().reload_current_scene()
