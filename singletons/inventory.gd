extends Node

@onready var player_battery : int

func _ready():
	set_default_values()

func set_default_values():
	player_battery = 100
