extends CharacterBody3D

# =========================
# ENUMS / ESTADOS
# =========================
enum EnemyState {
	IDLE,      # Fora do raio de 50m
	STALKING,  # Dentro do raio, tentando se aproximar
	CATCHING   # No meio do jumpscare
}

# =========================
# EXPORTS
# =========================
@export_category("Movement")
@export var chase_speed := 1.0
@export var rotation_speed := 10.0
@export var model_y_rotation_fix_deg := 0.0

@export_category("AI")
@export var activation_radius := 50.0 
@export var fov_threshold := 0.4 # Quão "no centro da tela" o monstro deve estar (0.4 é generoso)

@export_category("Animation")
@export var walk_animation := "Walk_4"
@export var walk_anim_speed := 1.2

# =========================
# NODES
# =========================
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var kill_zone: Area3D = $Killzone
@onready var jumpscare_ui: CanvasLayer = $JumpscareUI

# =========================
# VARIÁVEIS INTERNAS
# =========================
var state := EnemyState.IDLE
var player: Node3D = null
var is_watched := false
var path_update_timer := 0.0
var using_link := false
var link_end_position: Vector3

# =========================
# READY
# =========================
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	nav_agent.navigation_layers = 1 | 2 
	nav_agent.link_reached.connect(_on_navigation_link_reached)
	
	_set_state(EnemyState.IDLE)

# =========================
# PHYSICS PROCESS
# =========================
func _physics_process(delta: float) -> void:
	if not utils.mannequin_active: return
	if state == EnemyState.CATCHING or not is_instance_valid(player): 
		return

	# --- GRAVIDADE ---
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.1

	var dist_to_player = global_position.distance_to(player.global_position)
	
	if dist_to_player <= activation_radius:
		if state == EnemyState.IDLE: _set_state(EnemyState.STALKING)
	else:
		if state == EnemyState.STALKING: _set_state(EnemyState.IDLE)

	if state == EnemyState.STALKING:
		is_watched = _check_if_player_is_looking()
		
		if not is_watched:
			# --- PLAYER NÃO ESTÁ OLHANDO ---
			set_collision_layer_value(1, false)
			kill_zone.monitoring = true # Ativa a morte
			
			# CHECAGEM DE MORTE IMEDIATA:
			# Se o player já estiver dentro da área no frame que você desviou o olhar
			for body in kill_zone.get_overlapping_bodies():
				if body.is_in_group("player"):
					_trigger_death()
					return # Para o processamento aqui

			_process_movement_logic(delta)
			
			if not anim_player.is_playing() or anim_player.current_animation != walk_animation:
				anim_player.play(walk_animation)
				anim_player.speed_scale = walk_anim_speed
		else:
			# --- PLAYER ESTÁ OLHANDO ---
			set_collision_layer_value(1, true)
			kill_zone.monitoring = false # Fica inofensivo
			velocity.x = 0
			velocity.z = 0
			anim_player.stop() 
	else:
		velocity.x = 0
		velocity.z = 0
		anim_player.stop()

	move_and_slide()

# =========================
# LÓGICA DE MOVIMENTO
# =========================
func _process_movement_logic(delta: float) -> void:
	if using_link:
		_process_navigation_link(delta)
		return

	path_update_timer += delta
	if path_update_timer >= 0.2:
		nav_agent.set_target_position(player.global_position)
		path_update_timer = 0.0

	if nav_agent.is_navigation_finished():
		velocity.x = 0
		velocity.z = 0
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	
	# Mudamos apenas X e Z. O Y permanece o que a gravidade calculou no physics_process
	velocity.x = direction.x * chase_speed
	velocity.z = direction.z * chase_speed
	
	_rotate_to_direction(direction, delta)
	# O move_and_slide() já é chamado no _physics_process, não precisa aqui.
	
# =========================
# VISIBILIDADE (DOT PRODUCT + RAYCAST)
# =========================
func _check_if_player_is_looking() -> bool:
	var camera = get_viewport().get_camera_3d()
	if not camera: return false
	
	var to_me = (global_position - camera.global_position).normalized()
	var forward = -camera.global_transform.basis.z
	var dot = forward.dot(to_me)
	
	# Se o monstro estiver no campo de visão (FOV)
	if dot > fov_threshold:
		# Raycast para ver se não há paredes no caminho
		var space_state = get_world_3d().direct_space_state
		# Miramos um pouco acima do chão (altura do peito do monstro)
		var query = PhysicsRayQueryParameters3D.create(camera.global_position, global_position + Vector3(0, 1.3, 0))
		query.exclude = [player.get_rid(), self.get_rid()]
		
		var result = space_state.intersect_ray(query)
		
		# Se o raio estiver limpo, o player está vendo o monstro
		return result.is_empty()
		
	return false

# =========================
# ROTATION
# =========================
func _rotate_to_direction(direction: Vector3, delta: float) -> void:
	if direction.length() > 0.1:
		var target_yaw := atan2(-direction.x, -direction.z)
		target_yaw += deg_to_rad(model_y_rotation_fix_deg)
		rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)

# =========================
# NAVIGATION LINKS
# =========================
func _on_navigation_link_reached(details: Dictionary) -> void:
	using_link = true
	link_end_position = details["link_exit_position"]

func _process_navigation_link(delta: float) -> void:
	var direction := (link_end_position - global_position).normalized()
	velocity = direction * chase_speed
	_rotate_to_direction(direction, delta)
	move_and_slide()
	
	if global_position.distance_to(link_end_position) < 0.5:
		using_link = false

# =========================
# ESTADOS & MORTE
# =========================
func _set_state(new_state: EnemyState) -> void:
	state = new_state
	match state:
		EnemyState.IDLE, EnemyState.CATCHING:
			kill_zone.monitoring = false
			set_collision_layer_value(1, true) # Fica sólido se estiver IDLE
		EnemyState.STALKING:
			kill_zone.monitoring = true # Garante que a detecção ligue

func _on_killzone_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_watched:
		_trigger_death()

func _trigger_death() -> void:
	if state == EnemyState.CATCHING: return
	state = EnemyState.CATCHING
	velocity = Vector3.ZERO
	anim_player.stop()
	kill_zone.set_deferred("monitoring", false)
	utils.jumpscare_video(jumpscare_ui)
