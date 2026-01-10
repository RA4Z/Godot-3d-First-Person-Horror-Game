extends CharacterBody3D

# =========================
# ENUMS / ESTADOS
# =========================
enum EnemyState {
	IDLE,      # Parado por 5 segundos
	WANDERING, # Caminhando aleatoriamente
	CHASING    # Perseguindo o jogador por 10 segundos
}

# =========================
# EXPORTS
# =========================
@export_category("Movement")
@export var speed_wander := 1.0
@export var speed_chase := 2.5
@export var rotation_speed := 10.0

@export_category("AI Timers & Distances")
@export var idle_duration := 5.0
@export var chase_duration := 15.0
@export var chase_trigger_distance := 5.0 # Distância para começar a perseguir
@export var wander_radius := 15.0 # Raio da caminhada aleatória

# =========================
# NODES
# =========================
@onready var jumpscare_ui: CanvasLayer = $JumpscareUI
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var grunt_sound: AudioStreamPlayer3D = $GruntSound
@onready var walk_sound: AudioStreamPlayer3D = $WalkSound

# =========================
# VARIÁVEIS INTERNAS
# =========================
var state := EnemyState.IDLE
var player: Node3D = null
var state_timer := 0.0

# =========================
# READY
# =========================
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	_set_state(EnemyState.IDLE)

# =========================
# PHYSICS PROCESS
# =========================
func _physics_process(delta: float) -> void:
	# Gravidade básica
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.1

	# Lógica de Estados
	match state:
		EnemyState.IDLE:
			_process_idle(delta)
		EnemyState.WANDERING:
			_process_wandering(delta)
		EnemyState.CHASING:
			_process_chasing(delta)

	move_and_slide()

# =========================
# LÓGICA DOS ESTADOS
# =========================

func _process_idle(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	
	state_timer -= delta
	if state_timer <= 0:
		_set_state(EnemyState.WANDERING)

func _process_wandering(delta: float) -> void:
	# 1. Checar se o jogador está perto para iniciar perseguição
	if player and global_position.distance_to(player.global_position) < chase_trigger_distance:
		_set_state(EnemyState.CHASING)
		return

	# 2. Se chegou no destino aleatório, pega outro
	if nav_agent.is_navigation_finished():
		_set_new_wander_target()

	_move_towards_target(speed_wander, delta)

func _process_chasing(delta: float) -> void:
	# Atualiza a posição do jogador como alvo constantemente
	nav_agent.target_position = player.global_position
	
	_move_towards_target(speed_chase, delta)
	
	# Timer de perseguição
	state_timer -= delta
	if state_timer <= 0:
		_set_state(EnemyState.IDLE)

# =========================
# FUNÇÕES AUXILIARES
# =========================

func _set_state(new_state: EnemyState) -> void:
	state = new_state
	
	match state:
		EnemyState.IDLE:
			grunt_sound.stop()
			state_timer = idle_duration
			
		EnemyState.WANDERING:
			walk_sound.play()
			_set_new_wander_target()
			
		EnemyState.CHASING:
			walk_sound.stop()
			grunt_sound.play()
			state_timer = chase_duration

func _set_new_wander_target() -> void:
	var random_offset = Vector3(
		randf_range(-wander_radius, wander_radius),
		0,
		randf_range(-wander_radius, wander_radius)
	)
	nav_agent.target_position = global_position + random_offset

func _move_towards_target(speed: float, delta: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity.x = 0
		velocity.z = 0
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	_rotate_to_direction(direction, delta)

func _rotate_to_direction(direction: Vector3, delta: float) -> void:
	if direction.length() > 0.1:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)

func _on_killzone_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		utils.jumpscare_video(jumpscare_ui)
