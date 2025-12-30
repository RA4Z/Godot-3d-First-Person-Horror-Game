extends CharacterBody3D

@export var playerSpeed = 2.0
@export var playerAcceleration = 5.0
@export var cameraSensitivity = 0.25
@export var cameraAcceleration = 2.0
@export var jumpForce = 5.0
@export var gravity = 10.0
@export var battery_consumption = .5

@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var hand: Node3D = $Head/Camera3D/Hand
@onready var flashlight: SpotLight3D = $Head/Camera3D/Hand/Flashlight
@onready var footstep_sound: AudioStreamPlayer3D = $FootstepSound

var battery_timer := 0.0
var step_timer = 0.0
var step_interval = 0.75

var lights_on := true
var direction = Vector3.ZERO
var head_y_axis = 0.0
var camera_x_axis = 0.0
var sway_amount = 0.01
var sway_lerp_speed = 5.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		head_y_axis += event.relative.x * cameraSensitivity
		camera_x_axis += event.relative.y * cameraSensitivity
		camera_x_axis = clamp(camera_x_axis, -90.0, 90.0)
		
		hand.rotation.y -= event.relative.x * sway_amount
		hand.rotation.x -= event.relative.y * sway_amount
		
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _physics_process(delta):
	if is_on_floor() and velocity.length() > 0.1:
		step_timer += delta
		if step_timer >= step_interval:
			play_footstep()
			step_timer = 0.0
	else:
		step_timer = 0.0

func _process(delta):
	direction = Input.get_axis("left", "right") * head.basis.x + Input.get_axis("forward", "backward") * head.basis.z
	velocity = velocity.lerp(direction.normalized() * playerSpeed + velocity.y * Vector3.UP, playerAcceleration * delta)
	
	head.rotation.y = -deg_to_rad(head_y_axis)
	camera.rotation.x = -deg_to_rad(camera_x_axis)
	
	hand.rotation.x = lerp_angle(hand.rotation.x, 0.0, sway_lerp_speed * delta)
	hand.rotation.y = lerp_angle(hand.rotation.y, 0.0, sway_lerp_speed * delta)
	
	hand.rotation.x = clamp(hand.rotation.x, deg_to_rad(-15), deg_to_rad(15))
	hand.rotation.y = clamp(hand.rotation.y, deg_to_rad(-15), deg_to_rad(15))
	
	actions(delta)
	move_and_slide()

func actions(delta):
	if lights_on and inventory.player_battery > 0:
		battery_timer += delta
		if battery_timer >= battery_consumption:
			inventory.player_battery -= 1
			battery_timer = 0.0
			print("Bateria restante: ", inventory.player_battery)
			
			if inventory.player_battery <= 0:
				lights_on = false
				flashlight.visible = false

	if Input.is_action_just_pressed("interact"):
		if interaction_ray.is_colliding():
			var object = interaction_ray.get_collider()
			if object.has_method("interact"):
				object.interact()
		
	if Input.is_action_just_pressed("flashlight"):
		if lights_on:
			lights_on = false
			flashlight.visible = false
		elif inventory.player_battery > 0:
			lights_on = true
			flashlight.visible = true
			
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jumpForce
	else:
		velocity.y -= gravity * delta

func play_footstep():
	footstep_sound.pitch_scale = randf_range(0.8, 1.2) 
	footstep_sound.play()
