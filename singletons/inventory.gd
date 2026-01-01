extends Node

@onready var player_battery : int
@onready var player_keys : Array
@onready var player_items : Dictionary

func _ready():
	set_default_values()

func set_default_values():
	player_items = {"Battery": 0}
	player_battery = 100
	player_keys = [""]
