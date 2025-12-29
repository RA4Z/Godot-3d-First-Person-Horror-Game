extends CharacterBody3D

@export var walk_speed := 1.0
@export var chase_speed := 1.2
@onready var anim = $AnimationPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

enum State { WANDERING, CHASING }
var current_state = State.WANDERING
var player_target: CharacterBody3D = null

func _ready():
	if anim.has_animation("Take 001"):
		anim.play("Take 001")
	
	await get_tree().process_frame
	_choose_new_target()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if current_state == State.CHASING and player_target:
		nav_agent.target_position = player_target.global_position
		move_towards_target(chase_speed, delta)
	else:
		if nav_agent.is_navigation_finished():
			_choose_new_target()
		move_towards_target(walk_speed, delta)

	move_and_slide()

func move_towards_target(current_speed, delta):
	if nav_agent.is_navigation_finished():
		velocity.x = 0
		velocity.z = 0
		return

	var current_pos = global_transform.origin
	var next_path_pos = nav_agent.get_next_path_position()
	
	var direction = (next_path_pos - current_pos).normalized()
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	
	if velocity.length() > 0.1:
		var look_target = Vector3(next_path_pos.x, global_position.y, next_path_pos.z)
		if global_position.distance_to(look_target) > 0.1:
			look_at(look_target, Vector3.UP)
			rotate_y(deg_to_rad(180))

func _choose_new_target():
	var map = get_world_3d().get_navigation_map()
	for i in range(5):
		var random_point = NavigationServer3D.map_get_random_point(map, 1, false)
		var reachable_point = NavigationServer3D.map_get_closest_point(map, random_point)
		if global_position.distance_to(reachable_point) > 2.0:
			nav_agent.target_position = reachable_point
			return

func _on_detection_area_body_entered(body: Node3D) -> void:
	print(body.name)
	if body.name == "Player":
		player_target = body
		current_state = State.CHASING
		print("Jogador detectado pela lanterna!")

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		await get_tree().create_timer(2.0).timeout
		
		if current_state == State.CHASING:
			current_state = State.WANDERING
			player_target = null
			_choose_new_target()
			print("Perdi o jogador de vista...")
