extends Node

func jumpscare_video(jumpscareUI):
	get_tree().paused = true
	await jumpscareUI.start_jumpscare()
	inventory.set_default_values()
	get_tree().reload_current_scene()
	get_tree().paused = false
