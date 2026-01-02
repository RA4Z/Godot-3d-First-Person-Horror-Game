extends CharacterBody3D

@export var playerSpeed = 2.5
@export var playerSneak = 1.0
@export var playerAcceleration = 5.0
@export var cameraSensitivity = 0.25
@export var jumpForce = 5.0
@export var gravity = 10.0
@export var battery_consumption = 2

@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var hand: Node3D = $Head/Camera3D/Hand
@onready var flashlight: SpotLight3D = $Head/Camera3D/Hand/Flashlight
@onready var footstep_sound: AudioStreamPlayer3D = $FootstepSound
@onready var flashlight_sound: AudioStreamPlayer3D = $FlashlightSound

var battery_timer := 0.0
var step_timer = 0.0
var step_interval = 0.5

var reloading := false
var is_sneaking := false
var lights_on := true
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
		
		# Sway visual (pode ficar no _input ou _process)
		hand.rotation.y -= event.relative.x * sway_amount
		hand.rotation.x -= event.relative.y * sway_amount

func _physics_process(delta):
	# 1. Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# 2. Pulo
	var current_snap = 0.5 
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jumpForce
			current_snap = 0.0 # Desativa o snap para permitir a subida do pulo
		else:
			current_snap = 0.5 # Mantém o snap se estiver apenas andando
	else:
		current_snap = 0.0

	# 3. Direção e Velocidade
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	is_sneaking = Input.is_action_pressed("sneak")
	var target_speed = playerSneak if is_sneaking else playerSpeed
	step_interval = 0.8 if is_sneaking else 0.5
	
	if direction:
		velocity.x = lerp(velocity.x, direction.x * target_speed, playerAcceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * target_speed, playerAcceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, playerAcceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, playerAcceleration * delta)

	# 4. Executa o movimento
	floor_snap_length = current_snap
	
	move_and_slide()
	
	# 5. Sons de passos
	if is_on_floor() and velocity.length() > 0.1:
		step_timer += delta
		if step_timer >= step_interval:
			play_footstep()
			step_timer = 0.0
	else:
		step_timer = 0.0

func _process(delta):
	# Rotação da Câmera (Visual)
	head.rotation.y = lerp_angle(head.rotation.y, -deg_to_rad(head_y_axis), 0.5) # Suavizado
	camera.rotation.x = -deg_to_rad(camera_x_axis)
	
	# Hand Sway (Visual)
	hand.rotation.x = lerp_angle(hand.rotation.x, 0.0, sway_lerp_speed * delta)
	hand.rotation.y = lerp_angle(hand.rotation.y, 0.0, sway_lerp_speed * delta)
	hand.rotation.x = clamp(hand.rotation.x, deg_to_rad(-15), deg_to_rad(15))
	hand.rotation.y = clamp(hand.rotation.y, deg_to_rad(-15), deg_to_rad(15))
	
	# Ações de inventário e lanterna
	actions(delta)

func actions(delta):
	# Consumo de bateria
	if lights_on and inventory.player_battery > 0:
		battery_timer += delta
		if battery_timer >= battery_consumption:
			inventory.player_battery -= 1
			battery_timer = 0.0
			if inventory.player_battery <= 0:
				lights_on = false
				flashlight.visible = false

	# Interação
	if Input.is_action_just_pressed("interact"):
		if interaction_ray.is_colliding():
			var object = interaction_ray.get_collider()
			if object.has_method("interact"):
				object.interact()
			elif object.name == "Interaction":
				object.get_parent().interact()
		
	# Lanterna
	if Input.is_action_just_pressed("flashlight") and not reloading:
		flashlight_sound.play()
		lights_on = !lights_on
		flashlight.visible = (lights_on and inventory.player_battery > 0)
			
	# Reload
	if Input.is_action_just_pressed("reload"):
		if inventory.player_items['Battery'] > 0:
			perform_reload()

func perform_reload():
	reloading = true
	flashlight.visible = false
	lights_on = false
	$InsertBattery.play()
	inventory.player_items['Battery'] -= 1
	inventory.player_battery = 101
	await $InsertBattery.finished 
	lights_on = true
	flashlight.visible = true
	reloading = false

func play_footstep():
	footstep_sound.pitch_scale = randf_range(0.8, 1.2) 
	var noise_radius = 2.0 if is_sneaking else 10.0
	footstep_sound.volume_db = -15.0 if is_sneaking else 0.0
	footstep_sound.play()
	GameEvents.noise_made.emit(global_position, noise_radius)
