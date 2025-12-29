extends Node3D

@export var lamp_color: Color = Color("857a1d")
@onready var light: SpotLight3D = $Lamp/Light

var next_blink_time = 0.0
var timer = 0.0

func _ready() -> void:
	light.light_color = lamp_color
	set_random_next_time()

func _process(delta: float) -> void:
	timer += delta
	
	if timer >= next_blink_time:
		execute_glitch()
		timer = 0.0
		set_random_next_time()

func set_random_next_time():
	next_blink_time = randf_range(3.0, 10.0)

func execute_glitch():
	var blink_count = randi_range(3, 7)
	
	for i in range(blink_count):
		light.visible = false
		await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
		light.visible = true
		await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
