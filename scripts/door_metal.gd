extends AnimatableBody3D

@onready var open_door_audio: AudioStreamPlayer3D = $OpenDoor
@onready var close_door_audio: AudioStreamPlayer3D = $CloseDoor
@onready var locked_door_audio: AudioStreamPlayer3D = $LockedDoor

@onready var prison_door_2_3: Node3D = $"Sketchfab_model/53f0619e2fd24161a81b09343f56a581_fbx/RootNode/Null/prison_door_2_3"
@onready var interaction_collision: CollisionShape3D = $Interaction/InteractionCollision
@onready var navigation_link_3d: NavigationLink3D = $NavigationLink3D
@onready var label_3d: Label3D = $"Sketchfab_model/53f0619e2fd24161a81b09343f56a581_fbx/RootNode/Null/prison_door_2_3/prison_door_2_3_prison door_0/Label3D"

@export var keyID := "":
	set(value):
		keyID = value.left(4)
		$"Sketchfab_model/53f0619e2fd24161a81b09343f56a581_fbx/RootNode/Null/prison_door_2_3/prison_door_2_3_prison door_0/Label3D".text = keyID
		
@export var open_angle := 90.0
var is_open := false

func _ready():
	navigation_link_3d.enabled = is_open
	interaction_collision.disabled = !is_open

func interact():
	if keyID in inventory.player_keys:
		is_open = !is_open
		interaction_collision.set_deferred("disabled", !is_open)
		
		if is_open:
			collision_layer = 2
			open_door_audio.pitch_scale = randf_range(0.8, 1.2)
			open_door_audio.play()
		else:
			collision_layer = 1 + 2 

		var tween = create_tween()
		var target_rot = deg_to_rad(open_angle) if is_open else 0.0
		tween.tween_property(prison_door_2_3, "rotation:y", target_rot, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		if not is_open:
			close_door_audio.pitch_scale = randf_range(0.8, 1.2)
			close_door_audio.play()
		else:
			await get_tree().create_timer(1.5).timeout
			navigation_link_3d.enabled = is_open
			
	else:
		locked_door_audio.pitch_scale = randf_range(0.9, 1.1)
		locked_door_audio.play()
		
		var shake_tween = create_tween()
		var intensity = deg_to_rad(1.5)
		var duration = 0.05
		
		shake_tween.tween_property(prison_door_2_3, "rotation:y", intensity, duration)
		shake_tween.tween_property(prison_door_2_3, "rotation:y", -intensity, duration)
		shake_tween.tween_property(prison_door_2_3, "rotation:y", intensity * 0.5, duration)
		shake_tween.tween_property(prison_door_2_3, "rotation:y", 0.0, duration)
