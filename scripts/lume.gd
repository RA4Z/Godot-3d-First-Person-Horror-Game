extends CharacterBody3D

# =========================
# ENUMS / ESTADOS
# =========================
enum EnemyState { WANDERING, CHASING, CATCHING }

# =========================
# EXPORTS (Mantendo suas velocidades)
# =========================
@export_category("Movement")
@export var walk_speed := 0.5
@export var chase_speed := 1.0
@export var rotation_speed := 6.0
@export var model_y_rotation_fix_deg := 180.0 # Ajuste se ela andar de costas

@export_category("AI")
@export var wander_radius := 12.0
@export var detection_range := 15.0

# =========================
# NODES
# =========================
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var player = get_tree().get_first_node_in_group("player")
@onready var kill_zone: Area3D = $Killzone
@onready var jumpscare_ui: CanvasLayer = $JumpscareUI

# =========================
# VARIÁVEIS INTERNAS
# =========================
var state := EnemyState.WANDERING
var current_speed := 0.5
var path_update_timer := 0.0

# Variáveis para NavigationLinks (O segredo do funcionamento)
var using_link := false
var link_end_position: Vector3

# =========================
# READY
# =========================
func _ready() -> void:
	randomize()
	nav_agent.link_reached.connect(_on_navigation_link_reached)
	_set_state(EnemyState.WANDERING)

# =========================
# PHYSICS PROCESS
# =========================
func _physics_process(delta: float) -> void:
	if state == EnemyState.CATCHING: return
	if using_link:
		_process_navigation_link(delta)
		return

	# 1. Lógica de Transição
	_check_logic_transitions()

	path_update_timer += delta
	if path_update_timer >= 0.2: # Aumentei um pouco para estabilidade
		match state:
			EnemyState.WANDERING:
				if nav_agent.is_navigation_finished():
					_set_random_wander_target()
			EnemyState.CHASING:
				if is_instance_valid(player):
					nav_agent.target_position = player.global_position
		path_update_timer = 0.0

	_move_and_rotate(delta)
	
# =========================
# LÓGICA DE ESTADOS
# =========================
func _check_logic_transitions():
	if not is_instance_valid(player): return
	
	var dist = global_position.distance_to(player.global_position)
	var is_light_on = player.get("lights_on") == true
	
	if dist < detection_range and is_light_on:
		if state != EnemyState.CHASING:
			_set_state(EnemyState.CHASING)
	else:
		if state != EnemyState.WANDERING:
			_set_state(EnemyState.WANDERING)

func _set_state(new_state: EnemyState) -> void:
	state = new_state
	match state:
		EnemyState.WANDERING:
			current_speed = walk_speed
			anim_player.play("walk")
			_set_random_wander_target()
		EnemyState.CHASING:
			current_speed = chase_speed
			anim_player.play("run")

# =========================
# MOVIMENTAÇÃO E ROTAÇÃO
# =========================
func _move_and_rotate(delta: float) -> void:
	if nav_agent.is_navigation_finished() and state == EnemyState.WANDERING:
		velocity = velocity.move_toward(Vector3.ZERO, 0.5) # Desaceleração suave
		move_and_slide()
		return

	var next_pos := nav_agent.get_next_path_position()
	var current_pos := global_position
	var direction := (next_pos - current_pos).normalized()
	
	if state == EnemyState.CHASING and is_instance_valid(player):
		var dist_to_player = global_position.distance_to(player.global_position)
		if dist_to_player < 2.0: # Se estiver a menos de 2 metros
			direction = (player.global_position - global_position).normalized()

	if direction.length() > 0:
		velocity = direction * current_speed
		
		# Rotação
		var target_yaw := atan2(-direction.x, -direction.z)
		target_yaw += deg_to_rad(model_y_rotation_fix_deg)
		rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)
	
	move_and_slide()
# =========================
# TRATAMENTO DE NAVIGATION LINKS (O que resolve seu problema)
# =========================
func _on_navigation_link_reached(details: Dictionary) -> void:
	using_link = true
	link_end_position = details["link_exit_position"]

func _process_navigation_link(delta: float) -> void:
	var direction := (link_end_position - global_position).normalized()
	velocity = direction * current_speed

	var target_yaw := atan2(-direction.x, -direction.z)
	target_yaw += deg_to_rad(model_y_rotation_fix_deg)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)

	move_and_slide()

	if global_position.distance_to(link_end_position) < 0.5:
		using_link = false
		if state == EnemyState.CHASING:
			nav_agent.set_target_position(player.global_position)
		else:
			_set_random_wander_target()

# =========================
# AUXILIARES
# =========================
func _set_random_wander_target() -> void:
	var random_dir := Vector3(randf_range(-1,1), 0, randf_range(-1,1)).normalized()
	nav_agent.set_target_position(global_position + random_dir * wander_radius)


func _on_killzone_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and state == EnemyState.CHASING and player.get("lights_on") == true:
		_set_state(EnemyState.CATCHING)
		velocity = Vector3.ZERO
		utils.jumpscare_video(jumpscare_ui)
