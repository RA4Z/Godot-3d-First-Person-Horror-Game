extends Control

@onready var battery_bar: ProgressBar = $MarginContainer/BatteryBar

func _process(_delta):
	var battery_value = inventory.player_battery 
	update_battery_ui(battery_value)

func update_battery_ui(value):
	battery_bar.value = value
	var tween = create_tween()
	tween.tween_property(battery_bar, "value", value, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var sb = battery_bar.get_theme_stylebox("fill").duplicate()
	var main_color : Color
	if value > 70:
		main_color = Color.DARK_GREEN # Use tons mais escuros/saturados para terror
	elif value > 30:
		main_color = Color.GOLDENROD
	else:
		main_color = Color.DARK_RED
		
	sb.bg_color = main_color
	
	sb.shadow_color = main_color.darkened(0.1)
	sb.shadow_size = 6
	battery_bar.add_theme_stylebox_override("fill", sb)
