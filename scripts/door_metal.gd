extends AnimatableBody3D

@onready var open_door: AudioStreamPlayer3D = $OpenDoor
@onready var close_door: AudioStreamPlayer3D = $CloseDoor
@onready var prison_door_2_3: Node3D = $"Sketchfab_model/53f0619e2fd24161a81b09343f56a581_fbx/RootNode/Null/prison_door_2_3"

@export var open_angle := 90.0

var is_open := false

func interact():
	is_open = !is_open
	
	if is_open:
		collision_layer = 2
		open_door.pitch_scale = randf_range(0.8, 1.2)
		open_door.play()
	else:
		collision_layer = 1 + 2 

	var tween = create_tween()
	var target_rot = deg_to_rad(open_angle) if is_open else 0.0
	tween.tween_property(prison_door_2_3, "rotation:y", target_rot, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if not is_open:
		close_door.pitch_scale = randf_range(0.8, 1.2)
		close_door.play()
