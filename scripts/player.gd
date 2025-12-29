extends CharacterBody3D

@export var playerSpeed = 2.0
@export var playerAcceleration = 5.0
@export var cameraSensitivity = 0.25
@export var cameraAcceleration = 2.0
@export var jumpForce = 8.0
@export var gravity = 10.0

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var hand: Node3D = $Head/Camera3D/Hand
@onready var flashlight: SpotLight3D = $Head/Camera3D/Hand/Flashlight

var direction = Vector3.ZERO
var head_y_axis = 0.0
var camera_x_axis = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		# Visão do jogador (imediata)
		head_y_axis += event.relative.x * cameraSensitivity
		camera_x_axis += event.relative.y * cameraSensitivity
		camera_x_axis = clamp(camera_x_axis, -90.0, 90.0)
		
		# Faz a lanterna "ficar para trás" um pouco (Efeito Sway)
		# O valor 0.01 controla o quanto ela se desloca.
		hand.rotation.y -= deg_to_rad(event.relative.x * 0.01)
		hand.rotation.x -= deg_to_rad(event.relative.y * 0.01)
		
		# Trava a lanterna para ela não fugir da tela (Ex: no máximo 10 graus)
		hand.rotation.y = clamp(hand.rotation.y, deg_to_rad(-10), deg_to_rad(10))
		hand.rotation.x = clamp(hand.rotation.x, deg_to_rad(-10), deg_to_rad(10))
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _process(delta):
	direction = Input.get_axis("left", "right") * head.basis.x + Input.get_axis("forward", "backward") * head.basis.z
	velocity = velocity.lerp(direction.normalized() * playerSpeed + velocity.y * Vector3.UP, playerAcceleration * delta)
	
	head.rotation.y = -deg_to_rad(head_y_axis)
	camera.rotation.x = -deg_to_rad(camera_x_axis)
	
	hand.rotation.y = lerp_angle(hand.rotation.y, 0.0, cameraAcceleration * delta)
	hand.rotation.x = lerp_angle(hand.rotation.x, 0.0, cameraAcceleration * delta)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jumpForce
	else:
		velocity.y -= gravity * delta
	
	move_and_slide()
