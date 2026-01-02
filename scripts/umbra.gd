extends CharacterBody3D

# --- CONFIGURAÇÕES ---
@export var player: CharacterBody3D
@export var tempo_limite: float = 60.0
@export var distancia_minima_spawn: float = 12.0 
@export var suavidade_movimento: float = 5.0 
@export var intervalo_respawn_escuro: float = 5.0 

@onready var jumpscare_ui: CanvasLayer = $JumpscareUI
@onready var cry_sound: AudioStreamPlayer3D = $CrySound

# --- VARIÁVEIS INTERNAS ---
var segundos_contados: float = 0.0
var distancia_alvo: float = 0.0 
var jumpscare_disparado: bool = false
var lanterna_estava_ligada: bool = true 
var cronometro_respawn: float = 0.0 

func _ready():
	cry_sound.play()
	tornar_modelo_unshaded($Sketchfab_model)
	distancia_alvo = distancia_minima_spawn

func _physics_process(delta: float) -> void:
	if not utils.umbra_active or player == null or jumpscare_disparado:
		cry_sound.stream_paused = true
		self.visible = false
		return

	var lanterna_ligada = player.get("lights_on")
	
	# Detecta o momento que apaga: Spawn inicial aleatório
	if lanterna_estava_ligada == true and lanterna_ligada == false:
		spawn_aleatorio_navegavel(false) # Primeiro spawn pode ser em qualquer lugar
		cronometro_respawn = 0.0
	
	lanterna_estava_ligada = lanterna_ligada
	self.visible = !lanterna_ligada
	cry_sound.stream_paused = lanterna_ligada
	
	if !lanterna_ligada:
		segundos_contados += delta
		distancia_alvo = max(distancia_alvo - delta, 1.5)
		
		# LÓGICA DO RESPWAN DE 5 SEGUNDOS (Apenas se NÃO estiver sendo vista)
		if not esta_na_tela_do_jogador():
			cronometro_respawn += delta
			if cronometro_respawn >= intervalo_respawn_escuro:
				spawn_aleatorio_navegavel(true) # Força spawn NA FRENTE do jogador
				cronometro_respawn = 0.0
		else:
			# Se o jogador olhar para ela, o contador de 5s reseta
			cronometro_respawn = 0.0
		
		olhar_para_player()
		processar_movimento_navmesh(delta)

		if segundos_contados >= tempo_limite:
			disparar_morte()
			return

		if global_position.distance_to(player.global_position) <= 1.8:
			disparar_morte()
	else:
		cronometro_respawn = 0.0

# --- FUNÇÃO PARA VERIFICAR SE O JOGADOR ESTÁ VENDO ---
func esta_na_tela_do_jogador() -> bool:
	var camera = get_viewport().get_camera_3d()
	if camera == null: return false
	
	# Verifica se a posição da Umbra está dentro do frustum (pirâmide de visão) da câmera
	return camera.is_position_in_frustum(global_position)

func spawn_aleatorio_navegavel(na_frente: bool):
	var angulo: float
	
	if na_frente:
		# Pega a direção que o player está olhando (eixo Y)
		var rotacao_player = player.global_transform.basis.get_euler().y
		# Escolhe um ângulo de no máximo 45 graus para a esquerda ou direita da frente dele
		var desvio = randf_range(-deg_to_rad(45), deg_to_rad(45))
		angulo = rotacao_player + PI + desvio # +PI porque o Forward no Godot é Z negativo
	else:
		angulo = randf_range(0, TAU)
	
	var direcao = Vector3(sin(angulo), 0, cos(angulo))
	var posicao_teorica = player.global_position + (direcao * distancia_alvo)
	
	var mapa_rid = get_world_3d().get_navigation_map()
	global_position = NavigationServer3D.map_get_closest_point(mapa_rid, posicao_teorica)
	print("Umbra teleportada. Na frente: ", na_frente)

func processar_movimento_navmesh(delta):
	var direcao_atual = (global_position - player.global_position).normalized()
	if direcao_atual == Vector3.ZERO: direcao_atual = Vector3.FORWARD
	var posicao_teorica = player.global_position + (direcao_atual * distancia_alvo)
	var mapa_rid = get_world_3d().get_navigation_map()
	var posicao_no_mapa = NavigationServer3D.map_get_closest_point(mapa_rid, posicao_teorica)
	
	if global_position.distance_to(posicao_no_mapa) > 5.0:
		global_position = posicao_no_mapa
	
	global_position = global_position.lerp(posicao_no_mapa, delta * suavidade_movimento)

func disparar_morte():
	if jumpscare_disparado: return
	jumpscare_disparado = true
	self.visible = true
	var frente = player.global_transform.basis * Vector3(0, 0, -1.5)
	global_position = player.global_position + frente
	olhar_para_player()
	utils.jumpscare_video(jumpscare_ui)
	await get_tree().create_timer(0.5).timeout
	utils.umbra_active = false 

func olhar_para_player():
	var pos = player.global_position
	pos.y = global_position.y
	if global_position.distance_to(pos) > 0.1:
		look_at(pos, Vector3.UP)
		rotate_y(deg_to_rad(180)) 

func tornar_modelo_unshaded(node: Node):
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if node is MeshInstance3D:
		for i in range(node.get_surface_override_material_count()):
			var mat = node.get_active_material(i)
			if mat is StandardMaterial3D or mat is ORMMaterial3D:
				var novo_mat = mat.duplicate()
				novo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				node.set_surface_override_material(i, novo_mat)
	for child in node.get_children():
		tornar_modelo_unshaded(child)


func _on_cry_sound_finished() -> void:
	cry_sound.play()
