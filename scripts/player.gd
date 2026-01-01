extends CharacterBody3D

# Constantes para evitar "números mágicos" no meio do código
const SPEED_NORMAL = 2.5
const SPEED_SNEAK = 1.0
const SNEAK_STEP_INTERVAL = 1.1
const NORMAL_STEP_INTERVAL = 0.75

@export_group("Settings")
@export var camera_sensitivity = 0.15 # Valor menor para mouse motion direto
@export var jump_force = 5.0
@export var gravity = 10.0
@export var battery_consumption_rate = 2.0 # Segundos por 1% de carga

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var interaction_ray = $Head/Camera3D/InteractionRay
@onready var flashlight = $Head/Camera3D/Hand/Flashlight
@onready var hand = $Head/Camera3D/Hand

# Audio
@onready var footstep_sound = $FootstepSound
@onready var flashlight_sound = $FlashlightSound
@onready var reload_sound = $InsertBattery

var battery_timer := 0.0
var step_timer := 0.0
var reloading := false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	# Rotação de Câmera (Mais limpo)
	if event is InputEventMouseMotion:
		head.rotate_y(deg_to_rad(-event.relative.x * camera_sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * camera_sensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
		# Sway simples aplicado na rotação da mão
		hand.rotation.y = lerp(hand.rotation.y, deg_to_rad(-event.relative.x * 0.2), 0.1)
		hand.rotation.x = lerp(hand.rotation.x, deg_to_rad(event.relative.y * 0.2), 0.1)

	# Ações de clique único (Eventos)
	if event.is_action_pressed("flashlight"): toggle_flashlight()
	if event.is_action_pressed("reload"): reload_battery()
	if event.is_action_pressed("interact"): try_interact()
	if event.is_action_pressed("ui_cancel"): get_tree().quit()

func _physics_process(delta):
	handle_movement(delta)
	handle_battery(delta)
	handle_sway_reset(delta)
	move_and_slide()

func handle_movement(delta):
	var is_sneaking = Input.is_action_pressed("sneak")
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var target_speed = SPEED_SNEAK if is_sneaking else SPEED_NORMAL
	
	if direction:
		velocity.x = direction.x * target_speed
		velocity.z = direction.z * target_speed
		play_footstep_logic(delta, is_sneaking)
	else:
		velocity.x = move_toward(velocity.x, 0, target_speed)
		velocity.z = move_toward(velocity.z, 0, target_speed)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_force

func handle_battery(delta):
	if flashlight.visible and not reloading:
		battery_timer += delta
		if battery_timer >= battery_consumption_rate:
			inventory.player_battery -= 1
			battery_timer = 0.0
			if inventory.player_battery <= 0:
				set_flashlight(false)

func toggle_flashlight():
	if reloading: return
	if not flashlight.visible and inventory.player_battery <= 0: return
	
	flashlight_sound.play()
	set_flashlight(!flashlight.visible)

func set_flashlight(on: bool):
	flashlight.visible = on

func reload_battery():
	if inventory.player_items.get('Battery', 0) > 0 and not reloading:
		reloading = true
		set_flashlight(false)
		reload_sound.play()
		
		inventory.player_items['Battery'] -= 1
		inventory.player_battery = 100
		
		await reload_sound.finished
		reloading = false
		set_flashlight(true)

func try_interact():
	if interaction_ray.is_colliding():
		var obj = interaction_ray.get_collider()
		if obj.has_method("interact"):
			obj.interact()
		elif obj.name == "Interaction" and obj.get_parent().has_method("interact"):
			obj.get_parent().interact()

func play_footstep_logic(delta, is_sneaking):
	step_timer += delta
	var interval = SNEAK_STEP_INTERVAL if is_sneaking else NORMAL_STEP_INTERVAL
	
	if step_timer >= interval:
		footstep_sound.pitch_scale = randf_range(0.8, 1.2)
		footstep_sound.volume_db = -15.0 if is_sneaking else 0.0
		footstep_sound.play()
		
		var radius = 2.0 if is_sneaking else 10.0
		GameEvents.noise_made.emit(global_position, radius)
		step_timer = 0.0

func handle_sway_reset(delta):
	hand.rotation.x = lerp_angle(hand.rotation.x, 0.0, 5.0 * delta)
	hand.rotation.y = lerp_angle(hand.rotation.y, 0.0, 5.0 * delta)
