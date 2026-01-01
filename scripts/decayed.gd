extends CharacterBody3D

enum State { IDLE, WANDERING, ALERTED, RUNNING }

@export_group("Movimentação")
@export var walk_speed = 1.2
@export var run_speed = 5.0
@export var rotation_speed = 5.0
@export var wander_radius = 10.0
@onready var jumpscare_ui: CanvasLayer = $JumpscareUI

@export_group("Senses")
@export var hearing_sensitivity = 1.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var current_state = State.WANDERING
var target_pos = Vector3.ZERO
var reaction_timer: SceneTreeTimer = null
var chase_timeout = 5.0
var chase_timer = 0.0
@onready var clicks_sound: AudioStreamPlayer3D = $ClicksSound

func _ready():
	GameEvents.noise_made.connect(_on_noise_heard)
	setup_wander()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 15.0 * delta # Gravidade normal no ar
	else:
		velocity.y = -5.0
		
	match current_state:
		State.IDLE:
			move_and_slide()
		State.WANDERING:
			_move_to_target(delta, walk_speed, "walk")
			if nav_agent.is_navigation_finished():
				setup_wander()
		State.ALERTED:
			_look_at_target(delta) 
			move_and_slide()
		State.RUNNING:
			chase_timer += delta

			if chase_timer >= chase_timeout:
				chase_timer = 0.0
				setup_wander() 
			else:
				_move_to_target(delta, run_speed, "run")
				if nav_agent.is_navigation_finished():
					chase_timer = 0.0
					setup_wander()

func _on_noise_heard(noise_pos: Vector3, radius: float):
	var distance = global_position.distance_to(noise_pos)
	
	if distance <= (radius * hearing_sensitivity):
		target_pos = noise_pos
		chase_timer = 0.0
		
		if current_state == State.RUNNING:
			nav_agent.target_position = target_pos
			
		elif current_state == State.ALERTED:
			start_alert_sequence() 
			
		else:
			start_alert_sequence()

func start_alert_sequence():
	current_state = State.ALERTED
	anim_player.play("idle")
	clicks_sound.play()
	
	reaction_timer = get_tree().create_timer(2.0)
	reaction_timer.timeout.connect(_start_chase)

func _start_chase():
	if current_state == State.ALERTED:
		current_state = State.RUNNING
		nav_agent.target_position = target_pos

func setup_wander():
	current_state = State.WANDERING
	var random_pos = global_position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * wander_radius
	nav_agent.target_position = random_pos

func _move_to_target(delta, speed, anim_name):
	if nav_agent.is_navigation_finished():
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	
	anim_player.play(anim_name)
	
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	direction.y = 0
	direction = direction.normalized()
	
	var target_rotation = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	move_and_slide()

func _look_at_target(delta):
	var direction = global_position.direction_to(target_pos)
	direction.y = 0
	var target_rotation = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	
	velocity.x = 0
	velocity.z = 0

func short_angle_dist(from, to):
	var max_angle = PI * 2
	var difference = fmod(to - from, max_angle)
	return fmod(2 * difference, max_angle) - difference

func _on_killzone_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		utils.jumpscare_video(jumpscare_ui)
