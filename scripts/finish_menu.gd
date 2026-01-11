extends CanvasLayer

@onready var menu_content = $MenuContent
@onready var anim_player = $AnimationPlayer
@onready var sfx_hover = $SfxHover
@onready var bg_song: AudioStreamPlayer = $BGSong

func _ready():
	menu_content.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var buttons = $MenuContent/CenterContainer/VBoxContainer.get_children()
	
	for button in buttons:
		if button is Button:
			button.mouse_entered.connect(_play_hover_sound)

func _play_hover_sound():
	if menu_content.visible:
		sfx_hover.play()

func show_menu():
	get_tree().paused = true
	menu_content.visible = true
	anim_player.play("open")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	bg_song.play()

func _on_button_reset_button_down() -> void:
	get_tree().paused = false
	inventory.set_default_values()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()
	AudioPlayer.update_chase_music()

func _on_button_quit_button_down() -> void:
	get_tree().quit()
