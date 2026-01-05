extends CharacterBody3D

@export var playerSpeed = 2.5
@export var playerSneak = 1.0
@export var playerAcceleration = 7.0
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
@onready var player_skin: Node3D = $PlayerSkin
@onready var anim_player: AnimationPlayer = $PlayerSkin/AnimationPlayer

var battery_timer := 0.0
var step_timer = 0.0
var step_interval = 0.5
var mesh_rotation_target = 0.0
var reloading := false
var is_sneaking := false
var lights_on := true
var head_y_axis = 0.0
var camera_x_axis = 0.0
var sway_amount = 0.01
var sway_lerp_speed = 5.0
var smoothed_input := Vector2.ZERO
var last_head_y = 0.0
var rotation_velocity = 0.0

func _ready():
	inventory.current_player = self
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
	
	# Kick Obstacles
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody3D:
			var kick_direction = -collision.get_normal()
			collider.apply_central_impulse(kick_direction * velocity.length() * 0.5)
			
	# 2. Pulo
	var current_snap = 0.5 
	#if is_on_floor():
		#if Input.is_action_just_pressed("jump"):
			#velocity.y = jumpForce
			#current_snap = 0.0 # Desativa o snap para permitir a subida do pulo
		#else:
			#current_snap = 0.5 # Mantém o snap se estiver apenas andando
	#else:
		#current_snap = 0.0

	# 3. Direção e Velocidade
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
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
	update_animations(input_dir)

func _process(delta):
	# Rotação da Câmera (Visual)
	self.rotation.y = lerp_angle(self.rotation.y, -deg_to_rad(head_y_axis), 0.5)
	
	# 2. Rotação Vertical (Gira apenas a cabeça/câmera para cima e para baixo)
	camera.rotation.x = -deg_to_rad(camera_x_axis)
	
	# Resetar a rotação Y da Head para 0 (já que o corpo todo está girando)
	head.rotation.y = 0 
	
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
		
	if Input.is_action_just_pressed("use_item"):
		var slot_index = inventory.hotbar_current_slot
		var item_data = inventory.player_hotbar[slot_index]
		
		if item_data != null:
			var look_dir = -camera.global_transform.basis.z
			var horizontal_dir = Vector3(look_dir.x, 0, look_dir.z).normalized()
			
			var ideal_pos = global_position + (horizontal_dir * 1.5)
			
			var map_rid = get_world_3d().get_navigation_map()
			var final_pos = NavigationServer3D.map_get_closest_point(map_rid, ideal_pos)
			
			# Instantiate Item
			var item_path = item_data["id"]
			if not utils.item_cache.has(item_path):
				utils.item_cache[item_path] = load(item_path)
			var item_scene = utils.item_cache[item_path]
			var item_instance = item_scene.instantiate()
			get_tree().current_scene.add_child(item_instance)
			
			item_instance.global_position = final_pos + Vector3(0, 0.2, 0)
			if item_instance.has_method("use_item"):
				item_instance.use_item()
			
			inventory.remove_hotbar_item(slot_index)
	
	# Drop Item
	if Input.is_action_just_pressed("drop"):
		if inventory.player_hotbar[inventory.hotbar_current_slot]:
			inventory.drop_item(inventory.player_hotbar[inventory.hotbar_current_slot]["id"])
			inventory.remove_hotbar_item(inventory.hotbar_current_slot)
	
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

func update_animations(input_vector: Vector2):
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	# Calcula o quanto a camera girou desde o último frame
	# Usamos lerp para suavizar esse valor e evitar que a animação "pisque"
	var current_rot_diff = head_y_axis - last_head_y
	rotation_velocity = lerp(rotation_velocity, current_rot_diff, 0.1)
	last_head_y = head_y_axis
	
	smoothed_input = smoothed_input.lerp(input_vector, 0.3)
	
	if is_on_floor():
		if horizontal_speed > 0.2:
			# --- LÓGICA DE CAMINHADA (Igual à anterior) ---
			var anim_name = ""
			mesh_rotation_target = 0.0
			
			if abs(smoothed_input.x) > 0.4 and abs(smoothed_input.y) > 0.4:
				anim_name = "Player/forward" if smoothed_input.y < 0 else "Player/backward"
				var angle = deg_to_rad(30)
				if smoothed_input.x > 0:
					mesh_rotation_target = -angle if smoothed_input.y < 0 else angle
				else:
					mesh_rotation_target = angle if smoothed_input.y < 0 else -angle
			elif abs(smoothed_input.x) > 0.5:
				anim_name = "Player/left" if smoothed_input.x < 0 else "Player/right"
			elif abs(smoothed_input.y) > 0.1:
				anim_name = "Player/forward" if smoothed_input.y < 0 else "Player/backward"
			
			if anim_name != "":
				anim_player.speed_scale = 0.7 if is_sneaking else 1.0
				anim_player.play(anim_name, 0.6)
				
		elif abs(rotation_velocity) > 1.0: 
			# --- LÓGICA DE GIRAR PARADO ---
			# Se o mouse está se movendo rápido o suficiente para os lados
			if rotation_velocity > 0:
				anim_player.play("Player/right_turn", 0.4)
			else:
				anim_player.play("Player/left_turn", 0.4)
			anim_player.speed_scale = 1.0
			mesh_rotation_target = 0.0
			
		else:
			# --- IDLE ---
			anim_player.play("Player/idle", 0.6)
			anim_player.speed_scale = 1.0
			mesh_rotation_target = 0.0

	# Rotação do modelo (PlayerSkin)
	var rotation_offset = deg_to_rad(180)
	player_skin.rotation.y = lerp_angle(player_skin.rotation.y, mesh_rotation_target + rotation_offset, 0.1)
