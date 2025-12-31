# Script do Inimigo
extends CharacterBody3D

@export var hearing_sensitivity = 1.0 # Multiplicador de audição do inimigo

func _ready():
	GameEvents.noise_made.connect(_on_noise_heard)

func _on_noise_heard(noise_pos: Vector3, radius: float):
	var distance = global_position.distance_to(noise_pos)
	
	if distance <= (radius * hearing_sensitivity):
		react_to_noise(noise_pos)

func react_to_noise(pos: Vector3):
	print("Inimigo ouviu algo em: ", pos)
	
