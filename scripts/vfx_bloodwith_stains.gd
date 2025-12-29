extends Node3D


func _delete_myself():
	self.queue_free()
	
