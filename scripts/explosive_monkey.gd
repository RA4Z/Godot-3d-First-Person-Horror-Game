extends RigidBody3D # Mudamos de CharacterBody3D para RigidBody3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var monkey_sound: AudioStreamPlayer3D = $MonkeySound
@onready var collect_sound: AudioStreamPlayer3D = $CollectSound

var is_collected := false
var exploding := false

func interact():
	if is_collected or exploding: return
	is_collected = true
	collect_sound.play()
	
	var scene_path = self.scene_file_path 
	print(scene_path)
	inventory.add_hotbar_item("Explosive Monkey", scene_path, preload("uid://b20hfu8kyh4vp"))
	
	self.visible = false
	self.freeze = true
	
	await collect_sound.finished
	queue_free()

func use_item():
	if exploding: return
	exploding = true
	
	var noise_radius = 30.0
	var total_duration = 30.0
	var noise_interval = 0.5
	
	animation_player.play("Take 001")
	
	if not monkey_sound.playing:
		monkey_sound.play()

	var elapsed_time = 0.0
	
	while elapsed_time < total_duration:
		GameEvents.noise_made.emit(global_position, noise_radius)
		await get_tree().create_timer(noise_interval).timeout
		elapsed_time += noise_interval

	print("Macaco parou de funcionar e sumiu")
	queue_free()

func kick(direction: Vector3, force: float = 5.0):
	apply_central_impulse(direction * force)
	
