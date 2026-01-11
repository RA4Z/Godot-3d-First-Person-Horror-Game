extends CharacterBody3D

# =========================
# ENUMS / ESTADOS
# =========================
enum EnemyState {
	IDLE,
	WANDERING,
	JUMPSCARE
}

# =========================
# EXPORTS
# =========================
@export_category("Movement")
@export var walk_speed := 0.7
@export var rotation_speed := 6.0
@export var model_y_rotation_fix_deg := 180.0

@export_category("AI")
@export var wander_radius := 12.0
@export var idle_time_range := Vector2(1.0, 3.0) # Tempo que ele fica parado entre as caminhadas

@export_category("Animation")
@export var walk_anim_speed := 1.0
@export var idle_anim_speed := 0.5 # Velocidade da animação quando parado

# =========================
# NODES
# =========================
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var kill_zone: Area3D = $Killzone
@onready var jumpscare_ui: CanvasLayer = $JumpscareUI

# =========================
# VARIÁVEIS INTERNAS
# =========================
var state := EnemyState.IDLE
var state_timer := 0.0
var using_link := false
var link_end_position: Vector3

# =========================
# READY
# =========================
func _ready() -> void:
	randomize()
	_set_state(EnemyState.IDLE)
	
	# Conexões
	nav_agent.link_reached.connect(_on_navigation_link_reached)
	kill_zone.body_entered.connect(_on_killzone_body_entered)
	
# =========================
# PHYSICS PROCESS
# =========================
func _physics_process(delta: float) -> void:
	if state == EnemyState.JUMPSCARE:
		return

	if using_link:
		_process_navigation_link(delta)
		return

	match state:
		EnemyState.IDLE:
			_process_idle(delta)
		EnemyState.WANDERING:
			_process_wandering(delta)

	_move_and_rotate(delta)

# =========================
# LÓGICA DE ESTADOS
# =========================
func _set_state(new_state: EnemyState) -> void:
	state = new_state
	
	match state:
		EnemyState.IDLE:
			state_timer = randf_range(idle_time_range.x, idle_time_range.y)
			velocity = Vector3.ZERO
			
		EnemyState.WANDERING:
			_set_random_wander_target()
			
		EnemyState.JUMPSCARE:
			velocity = Vector3.ZERO

func _process_idle(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0:
		_set_state(EnemyState.WANDERING)

func _process_wandering(_delta: float) -> void:
	if nav_agent.is_navigation_finished():
		_set_state(EnemyState.IDLE)
		return

	# Se ficar preso por muito tempo em algum obstáculo, tenta um novo destino
	if velocity.length() < 0.05 and nav_agent.distance_to_target() > 0.5:
		_set_random_wander_target()

# =========================
# MOVIMENTAÇÃO
# =========================
func _move_and_rotate(delta: float) -> void:
	if state == EnemyState.IDLE or nav_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector3.ZERO, 0.2)
		move_and_slide()
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position)
	direction.y = 0
	
	if direction.length() > 0.05:
		direction = direction.normalized()
		velocity = direction * walk_speed
		_look_at_target(next_pos, delta)
	
	move_and_slide()

func _look_at_target(target_pos: Vector3, delta: float) -> void:
	var look_dir := target_pos - global_position
	look_dir.y = 0
	if look_dir.length() > 0.1:
		var target_yaw := atan2(-look_dir.x, -look_dir.z)
		target_yaw += deg_to_rad(model_y_rotation_fix_deg)
		rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)

func _set_random_wander_target() -> void:
	var random_dir := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	var target_pos = global_position + random_dir * wander_radius
	nav_agent.set_target_position(target_pos)

# =========================
# LINKS DE NAVEGAÇÃO (Escadas/Pulos)
# =========================
func _on_navigation_link_reached(details: Dictionary) -> void:
	using_link = true
	link_end_position = details["link_exit_position"]

func _process_navigation_link(delta: float) -> void:
	var direction := (link_end_position - global_position)
	direction.y = 0

	if direction.length() < 0.2:
		using_link = false
		_set_state(EnemyState.IDLE)
		return

	velocity = direction.normalized() * walk_speed
	_look_at_target(link_end_position, delta)
	move_and_slide()

# =========================
# JUMPSCARE (KILLZONE)
# =========================
func _on_killzone_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and state != EnemyState.JUMPSCARE:
		_set_state(EnemyState.JUMPSCARE)
		
		if AudioPlayer.has_method("stop_chase_music"):
			AudioPlayer.stop_chase_music()
			
		if has_node("JumpscareUI"):
			utils.jumpscare_video(jumpscare_ui)
