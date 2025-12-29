extends AnimatableBody3D

@onready var prison_door_2_3: Node3D = $"Sketchfab_model/53f0619e2fd24161a81b09343f56a581_fbx/RootNode/Null/prison_door_2_3"
@export var open_angle := 90.0
var is_open := false

func interact():
	is_open = !is_open
	
	if is_open:
		# Quando aberta: Deixa apenas a Layer 2 ativa (Interação)
		# O Player (que olha a Layer 1) vai atravessar.
		collision_layer = 2 
	else:
		# Quando fechada: Ativa as Layers 1 e 2.
		# O Player vai bater na porta (Layer 1) e o RayCast ainda a vê (Layer 2).
		collision_layer = 1 + 2 

	# Animação da porta
	var tween = create_tween()
	var target_rot = deg_to_rad(open_angle) if is_open else 0.0
	tween.tween_property(prison_door_2_3, "rotation:y", target_rot, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
