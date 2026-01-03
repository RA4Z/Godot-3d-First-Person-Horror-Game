extends Node

var being_jumpscared := false
var umbra_active := false
var mannequin_active := false

func jumpscare_video(jumpscareUI):
	being_jumpscared = true
	get_tree().paused = true
	await jumpscareUI.start_jumpscare()
	inventory.set_default_values()
	get_tree().reload_current_scene()
	get_tree().paused = false
	AudioPlayer.update_chase_music()
	reset_utils()

func reset_utils():
	being_jumpscared = false
	umbra_active = false
	mannequin_active = false
