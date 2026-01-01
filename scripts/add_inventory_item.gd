extends StaticBody3D

@export var item_name: String = ""
@export var amount: int = 1
@onready var collect_sound: AudioStreamPlayer3D = $Collect

func interact():
	collect_sound.play()
	if not inventory.player_items.get(item_name):
		inventory.player_items[item_name] = amount
	else:
		inventory.player_items[item_name] += amount
	self.visible = false
	await collect_sound.finished
	queue_free()
	
