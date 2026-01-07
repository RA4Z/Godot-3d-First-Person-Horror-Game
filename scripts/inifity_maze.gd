extends Node3D

@onready var start: Marker3D = $Start


func _on_teleporter_body_entered(body: Node3D) -> void:
	if body.is_in_group('player'):
		body.global_position = start.global_position
