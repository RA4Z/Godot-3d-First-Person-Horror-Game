extends Node3D

@onready var finish_menu = $FinishMenu

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		finish_menu.show_menu()
