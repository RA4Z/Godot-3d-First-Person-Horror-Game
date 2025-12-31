extends MeshInstance3D

@export var keyID := "":
	set(value):
		keyID = value.left(4)
		if has_node("Label3D"):
			$Label3D.text = keyID
			
@onready var grab_keys_audio: AudioStreamPlayer3D = $GrabKeys

func interact():
	grab_keys_audio.pitch_scale = randf_range(0.9, 1.1)
	grab_keys_audio.play()
	inventory.player_keys.append(keyID)
	self.visible = false
	await grab_keys_audio.finished
	self.queue_free()
