extends CharacterBody3D

# Configurações de movimento
@export var speed = 1.5             # Aumentei um pouco a velocidade
@export var wander_radius = 15.0    # Aumentei o raio para ele andar mais longe
@export var idle_time_min = 0.5     # Mínimo de meio segundo parado
@export var idle_time_max = 1.5     # Máximo de 1.5 segundos parado
@export_range(0, 100) var squeak_chance = 40 # 40% de chance de fazer som

# Referências aos nós
@onready var nav_agent = $NavigationAgent3D
@onready var anim = $AnimationPlayer
@onready var squeak_sound: AudioStreamPlayer3D = $SqueakSound

# Estados do rato
enum State { IDLE, WANDERING }
var current_state = State.IDLE

func _ready():
	# Começa parado e depois de um tempo escolhe um destino
	wait_and_move()

func _physics_process(delta: float) -> void:
	# Aplicar gravidade básica
	if not is_on_floor():
		velocity += get_gravity() * delta

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			anim.play("rig|idol animtion") # Nome conforme solicitado

		State.WANDERING:
			if nav_agent.is_navigation_finished():
				start_idle()
				return

			# Lógica de navegação
			var next_path_pos = nav_agent.get_next_path_position()
			var direction = (next_path_pos - global_position).normalized()
			
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			# Rotação suave para olhar na direção do movimento
			if velocity.length() > 0.2:
				var look_target = Vector3(next_path_pos.x, global_position.y, next_path_pos.z)
				look_at(look_target, Vector3.UP)
				rotate_y(PI) # Remova ou comente esta linha se o rato andar de costas
			
			anim.play("rig|run cycle") # Nome conforme solicitado

	move_and_slide()

# Função para parar o rato e decidir quando ele volta a andar
func start_idle():
	current_state = State.IDLE
	try_play_squeak() # Tenta fazer som ao parar
	var wait_time = randf_range(idle_time_min, idle_time_max)
	await get_tree().create_timer(wait_time).timeout
	set_new_random_target()

# Função para definir o novo alvo aleatório
func set_new_random_target():
	var target_pos = global_position
	
	# Tenta encontrar um ponto que não seja colado no rato
	for i in range(5): # Tenta 5 vezes achar um ponto longe
		var random_dir = Vector3(
			randf_range(-wander_radius, wander_radius),
			0,
			randf_range(-wander_radius, wander_radius)
		)
		target_pos = global_position + random_dir
		
		# Se o ponto sorteado for longe o suficiente (ex: 3 metros), aceita ele
		if target_pos.distance_to(global_position) > 3.0:
			break

	nav_agent.target_position = target_pos
	current_state = State.WANDERING
	try_play_squeak()

# Chamada inicial
func wait_and_move():
	start_idle()

func try_play_squeak():
	# Sorteia um número de 0 a 100. Se for menor que a chance, toca o som.
	if randf_range(0, 100) < squeak_chance:
		# Verifica se o som já não está tocando para não sobrepor
		if not squeak_sound.playing:
			# Muda levemente o tom (pitch) para não ficar repetitivo
			squeak_sound.pitch_scale = randf_range(0.9, 1.2)
			squeak_sound.play()
			
