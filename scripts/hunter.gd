extends CharacterBody3D

# =========================
# ENUMS / ESTADOS
# =========================
enum EnemyState {
	WANDERING,
	CHASING
}

# =========================
# EXPORTS
# =========================
@export_category("Movement")
@export var walk_speed := 1.0
@export var chase_speed := 1.5
@export var rotation_speed := 6.0
@export var model_y_rotation_fix_deg := 180.0

@export_category("AI")
@export var wander_radius := 12.0
@export var lose_sight_time := 5.0

@export_category("Animation")
@export var base_animation_name := "Take 001"
@export var walk_anim_speed := 1.0
@export var chase_anim_speed := 1.6

# =========================
# NODES
# =========================
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var vision_area: Area3D = $Sketchfab_model/Shade_FBX/Object_2/RootNode/Object_4/Skeleton3D/Object_10/Flashlight/DetectionArea
@onready var vision_ray: RayCast3D = $Sketchfab_model/Shade_FBX/Object_2/RootNode/Object_4/Skeleton3D/Object_10/Flashlight/FieldOfView
@onready var kill_zone: Area3D = $Killzone
@onready var jumpscare_ui: CanvasLayer = $JumpscareUI

# =========================
# VARIÁVEIS INTERNAS
# =========================
var state := EnemyState.WANDERING
var player: Node3D
var last_seen_timer := 0.0
var current_speed := 1.0

var last_known_player_position: Vector3 = Vector3.ZERO

var using_link := false
var link_end_position: Vector3

# =========================
# READY
# =========================
func _ready() -> void:
	randomize()
	_set_state(EnemyState.WANDERING)

	nav_agent.navigation_layers = 1
	nav_agent.link_reached.connect(_on_navigation_link_reached)
	vision_area.body_entered.connect(_on_vision_body_entered)
	kill_zone.body_entered.connect(_on_killzone_body_entered)

	anim_player.play(base_animation_name)
	anim_player.speed_scale = walk_anim_speed

# =========================
# PHYSICS PROCESS
# =========================
func _physics_process(delta: float) -> void:
	if using_link:
		_process_navigation_link(delta)
		return

	match state:
		EnemyState.WANDERING:
			_process_wandering()
		EnemyState.CHASING:
			_process_chasing(delta)

	_move_and_rotate(delta)

# =========================
# STATES
# =========================
func _set_state(new_state: EnemyState) -> void:
	if state == new_state:
		return

	state = new_state
	AudioPlayer.update_chase_music()

	match state:
		EnemyState.WANDERING:
			current_speed = walk_speed
			anim_player.speed_scale = walk_anim_speed

			# ❌ Bloqueia portas
			nav_agent.navigation_layers = 1
			_set_random_wander_target()

		EnemyState.CHASING:
			current_speed = chase_speed
			anim_player.speed_scale = chase_anim_speed

			# ✅ Libera portas
			nav_agent.navigation_layers = 1 | 2

# =========================
# WANDERING
# =========================
func _process_wandering() -> void:
	if nav_agent.is_navigation_finished():
		_set_random_wander_target()
		return

	# 🔥 Se ficar parado sem chegar ao destino, replaneja
	if velocity.length() < 0.05:
		_set_random_wander_target()


# =========================
# CHASING (CORRIGIDO)
# =========================
func _process_chasing(delta: float) -> void:
	if not is_instance_valid(player):
		_set_state(EnemyState.WANDERING)
		return

	if _has_line_of_sight():
		last_seen_timer = 0.0
		last_known_player_position = player.global_position
	else:
		last_seen_timer += delta
		if last_seen_timer >= lose_sight_time:
			_set_state(EnemyState.WANDERING)
			return

	# 🔥 SEMPRE segue a última posição conhecida
	var target := last_known_player_position if last_known_player_position != Vector3.ZERO else player.global_position
	nav_agent.set_target_position(target)

# =========================
# MOVEMENT & ROTATION
# =========================
func _move_and_rotate(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := next_pos - global_position
	direction.y = 0

	if direction.length() < 0.05:
		# Força olhar para o target se travar em corredor
		var look_dir := nav_agent.target_position - global_position
		look_dir.y = 0
		if look_dir.length() > 0.1:
			var yaw := atan2(-look_dir.x, -look_dir.z)
			yaw += deg_to_rad(model_y_rotation_fix_deg)
			rotation.y = lerp_angle(rotation.y, yaw, rotation_speed * delta)
		velocity = Vector3.ZERO
		return

	direction = direction.normalized()
	velocity = direction * current_speed

	var target_yaw := atan2(-direction.x, -direction.z)
	target_yaw += deg_to_rad(model_y_rotation_fix_deg)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)

	move_and_slide()

# =========================
# LINE OF SIGHT
# =========================
func _has_line_of_sight() -> bool:
	if not is_instance_valid(player):
		return false

	vision_ray.target_position = vision_ray.to_local(player.global_position)
	vision_ray.force_raycast_update()

	if vision_ray.is_colliding():
		return vision_ray.get_collider().is_in_group("player")

	return false

# =========================
# WANDER TARGET
# =========================
func _set_random_wander_target() -> void:
	var dir := Vector3(randf_range(-1,1), 0, randf_range(-1,1)).normalized()
	nav_agent.set_target_position(global_position + dir * wander_radius)

# =========================
# SIGNALS
# =========================
func _on_vision_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body
		last_known_player_position = body.global_position
		last_seen_timer = 0.0
		_set_state(EnemyState.CHASING)

func _on_killzone_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		utils.jumpscare_video(jumpscare_ui)

func _on_navigation_link_reached(details: Dictionary) -> void:
	using_link = true
	link_end_position = details["link_exit_position"]
	velocity = Vector3.ZERO

func _process_navigation_link(delta: float) -> void:
	var direction := link_end_position - global_position
	direction.y = 0

	if direction.length() < 0.2:
		using_link = false
		velocity = Vector3.ZERO

		if state == EnemyState.CHASING and is_instance_valid(player):
			nav_agent.set_target_position(last_known_player_position)
		else:
			_set_random_wander_target()
		return

	direction = direction.normalized()
	velocity = direction * current_speed

	var yaw := atan2(-direction.x, -direction.z)
	yaw += deg_to_rad(model_y_rotation_fix_deg)
	rotation.y = lerp_angle(rotation.y, yaw, rotation_speed * delta)

	move_and_slide()
