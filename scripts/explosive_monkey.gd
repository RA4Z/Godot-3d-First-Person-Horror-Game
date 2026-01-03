extends RigidBody3D # Mudamos de CharacterBody3D para RigidBody3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var monkey_sound: AudioStreamPlayer3D = $MonkeySound
@onready var collect_sound: AudioStreamPlayer3D = $CollectSound

var is_collected := false
var exploding := false

func interact():
	if is_collected: return
	is_collected = true
	collect_sound.play()
	
	var scene_path = self.scene_file_path 
	inventory.add_hotbar_item("Explosive Monkey", scene_path, preload("uid://b20hfu8kyh4vp"))
	
	# Esconde e remove colisão para não interferir enquanto toca o som de coleta
	self.visible = false
	self.freeze = true # Congela a física antes de deletar
	
	await collect_sound.finished
	queue_free()

func use_item():
	exploding = true
	animation_player.play("Take 001")
	monkey_sound.play()

func kick(direction: Vector3, force: float = 5.0):
	apply_central_impulse(direction * force)
	
