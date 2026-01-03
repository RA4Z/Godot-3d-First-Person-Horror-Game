extends Node

@onready var player_battery : int
@onready var player_keys : Array
@onready var player_items : Dictionary
@onready var player_hotbar : Array

@onready var hotbar_current_slot := 0

var current_player: CharacterBody3D

signal hotbar_updated

func _ready():
	set_default_values()

func set_default_values():
	player_items = {"Battery": 0}
	player_battery = 100
	player_keys = ["664"]
	player_hotbar = [null, null, null, null]

func remove_hotbar_item(position: int):
	player_hotbar[position] = null
	hotbar_updated.emit()

func add_hotbar_item(name: String, id, icon: CompressedTexture2D):
	var item = {"name": name, "id": id, "icon": icon}
	
	var old_item = player_hotbar[hotbar_current_slot]
	
	if old_item != null:
		print('Trocando Item: ', old_item["name"])
		drop_item(old_item["id"])
		
	player_hotbar[hotbar_current_slot] = item
	hotbar_updated.emit()

func drop_item(item_data):
	if current_player == null:
		return

	var ideal_pos = current_player.global_position + (-current_player.global_transform.basis.z * 1.5)
	var map_rid = current_player.get_world_3d().get_navigation_map()
	var final_pos = NavigationServer3D.map_get_closest_point(map_rid, ideal_pos)

	if item_data is String:
		var scene = load(item_data)
		var instance = scene.instantiate()
		get_tree().current_scene.add_child(instance)
		instance.global_position = final_pos
		
	elif item_data is Node:
		get_tree().current_scene.add_child(item_data)
		item_data.visible = true
		item_data.global_position = final_pos
