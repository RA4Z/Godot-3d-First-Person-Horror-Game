extends RigidBody3D

@onready var collect_sound: AudioStreamPlayer3D = $CollectSound

var is_collected := false
var exploding := false

func interact():
	if is_collected or exploding: return
	is_collected = true
	collect_sound.play()
	
	var scene_path = self.scene_file_path 
	inventory.add_hotbar_item("Wooden Mannequin", scene_path, preload("uid://djkr1mnlnui3r"))
	
	self.visible = false
	self.freeze = true
	
	await collect_sound.finished
	queue_free()

func use_item():
	if exploding: return
	exploding = true
	var total_duration = 30.0
	await get_tree().create_timer(total_duration).timeout
	print("Manequim de madeira quebrou!")
	queue_free()
