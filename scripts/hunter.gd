extends CharacterBody3D

@export var walk_speed := 1.0
@export var chase_speed := 1.5

@onready var anim = $AnimationPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var chase_music: AudioStreamPlayer = $ChaseMusic
@onready var video_player: VideoStreamPlayer = $JumpscareUI/VideoStreamPlayer
@onready var audio_stream_player: AudioStreamPlayer = $JumpscareUI/AudioStreamPlayer
@onready var anim_player: AnimationPlayer = $JumpscareUI/AnimPlayer
@onready var ray_cast: RayCast3D = $Sketchfab_model/Shade_FBX/Object_2/RootNode/Object_4/Skeleton3D/Object_10/Flashlight/FieldOfView
@onready var animation_player: AnimationPlayer = $AnimationPlayer

enum State { WANDERING, CHASING }
var current_state = State.WANDERING
var player_target: CharacterBody3D = null
var chase_lost_timer: float = 0.0

func _process(_delta):
	if player_target:
		check_line_of_sight(_delta)

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
		animation_player.speed_scale = 4.0
		
		if not chase_music.playing:
			chase_music.play()
	else:
		animation_player.speed_scale = 3.0
		if chase_music.playing:
			chase_music.stop()
			
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

func check_line_of_sight(delta):
	if not player_target:
		return

	ray_cast.look_at(player_target.global_position + Vector3(0, 1, 0))
	ray_cast.force_raycast_update()
	
	var is_player_visible = false
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider.name == "Player":
			is_player_visible = true

	if is_player_visible:
		chase_lost_timer = 0.0
		current_state = State.CHASING
	else:
		if current_state == State.CHASING:
			chase_lost_timer += delta
			
			if chase_lost_timer >= 5.0:
				current_state = State.WANDERING
				player_target = null
				_choose_new_target()

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_target = body

func _on_killzone_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		utils.jumpscare_video(audio_stream_player, video_player, anim_player)

func _on_navigation_agent_3d_link_reached(details: Dictionary) -> void:
	var global_exit_pos = details.get("link_exit_position")
	if global_exit_pos:
		global_position = global_exit_pos
