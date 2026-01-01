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

func _input(event):
	if event.is_action_pressed("ui_cancel") and not utils.being_jumpscared:
		toggle_pause()

func toggle_pause():
	var is_paused = !get_tree().paused
	get_tree().paused = is_paused
	
	if is_paused:
		menu_content.visible = true
		anim_player.play("open")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		bg_song.play()
	else:
		if !get_tree().paused:
			menu_content.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			bg_song.stop()

func _on_button_resume_pressed() -> void:
	toggle_pause()

func _on_button_reset_button_down() -> void:
	get_tree().paused = false
	inventory.set_default_values()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()

func _on_button_quit_button_down() -> void:
	get_tree().quit()
