extends Control

@onready var battery_bar: ProgressBar = $MarginContainer/BatteryBar

func _process(_delta):
	var battery_value = inventory.player_battery 
	update_battery_ui(battery_value)

func update_battery_ui(value):
	battery_bar.value = value
	var sb = battery_bar.get_theme_stylebox("fill")
	
	if value > 70:
		sb.bg_color = "#459b48"
	elif value > 30:
		sb.bg_color = "#968705"
	else:
		sb.bg_color = "#710005"
