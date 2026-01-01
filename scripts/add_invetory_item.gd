extends StaticBody3D

@export var item_name: String = ""
@export var amount: int = 1

func interact():
	if not inventory.player_items.get(item_name):
		inventory.player_items[item_name] = amount
	else:
		inventory.player_items[item_name] += amount
	queue_free()
	
