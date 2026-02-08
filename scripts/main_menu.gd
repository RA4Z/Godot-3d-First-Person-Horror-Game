extends CanvasLayer

@onready var anim_player = $AnimationPlayer
@onready var sfx_hover = $SfxHover
@onready var bg_song: AudioStreamPlayer = $BGSong

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	get_tree().paused = true
	bg_song.play()
	if anim_player.has_animation("intro"):
		anim_player.play("intro")
	
	# Conecta o som de hover automaticamente a todos os botões
	_connect_buttons()

func _connect_buttons():
	var buttons = $MenuContent/CenterContainer/VBoxContainer.get_children()
	for button in buttons:
		if button is Button:
			button.mouse_entered.connect(_play_hover_sound)

func _play_hover_sound():
	sfx_hover.play()

func _on_button_play_pressed() -> void:
	if has_node("/root/inventory"): # Verifica se o autoload existe
		inventory.set_default_values()
	
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_button_quit_pressed() -> void:
	get_tree().quit()

func _on_itch_button_pressed() -> void:
	OS.shell_open("https://ra4z.itch.io")

func _on_github_button_pressed() -> void:
	OS.shell_open("https://github.com/ra4z")

func _on_linkedin_button_pressed() -> void:
	OS.shell_open("https://www.linkedin.com/in/robert-aron-zimmermann-dev/")
