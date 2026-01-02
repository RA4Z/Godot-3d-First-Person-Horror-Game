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
	
	if lanterna_estava_ligada == true and lanterna_ligada == false:
		spawn_aleatorio_navegavel(false) 
		cronometro_respawn = 0.0
	
	lanterna_estava_ligada = lanterna_ligada
	self.visible = !lanterna_ligada
	cry_sound.stream_paused = lanterna_ligada
	
	if !lanterna_ligada:
		segundos_contados += delta
		distancia_alvo = max(distancia_alvo - delta, 1.5)
		
		# RESPAWN SE NÃO ESTIVER NA TELA
		if not esta_na_tela_do_jogador():
			cronometro_respawn += delta
			if cronometro_respawn >= intervalo_respawn_escuro:
				# Tenta teleportar. Se conseguir um lugar visível e sem paredes, reseta o tempo.
				if spawn_aleatorio_navegavel(true):
					cronometro_respawn = 0.0
		else:
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

func esta_na_tela_do_jogador() -> bool:
	var camera = get_viewport().get_camera_3d()
	if camera == null: return false
	
	# Verifica se está no cone de visão
	if not camera.is_position_in_frustum(global_position):
		return false
		
	# Verifica se tem parede (Camada 1) entre a câmera e a Umbra
	return tem_linha_de_visao(camera.global_position, global_position)

func tem_linha_de_visao(origem: Vector3, destino: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origem, destino)
	query.collision_mask = 1 # Camada 1 (Cenário)
	query.exclude = [self, player] # Ignora a si mesma e ao player
	
	var result = space_state.intersect_ray(query)
	
	# Se o resultado estiver vazio, não bateu em nada (visão limpa)
	return result.is_empty()

func spawn_aleatorio_navegavel(na_frente: bool) -> bool:
	var mapa_rid = get_world_3d().get_navigation_map()
	var camera = get_viewport().get_camera_3d()
	if camera == null: return false

	var tentativas = 20 if na_frente else 1
	
	for i in range(tentativas):
		var angulo: float
		if na_frente:
			var direcao_olhar = -player.global_transform.basis.z
			var angulo_base = atan2(direcao_olhar.x, direcao_olhar.z)
			var desvio = randf_range(-deg_to_rad(45), deg_to_rad(45))
			angulo = angulo_base + desvio
		else:
			angulo = randf_range(0, TAU)
		
		var direcao_final = Vector3(sin(angulo), 0, cos(angulo))
		var posicao_teorica = player.global_position + (direcao_final * distancia_alvo)
		var ponto_navmesh = NavigationServer3D.map_get_closest_point(mapa_rid, posicao_teorica)
		
		# TESTE DE VALIDAÇÃO:
		if na_frente:
			# 1. Está no cone da câmera?
			if camera.is_position_in_frustum(ponto_navmesh):
				# 2. Tem parede no meio? (Checa contra a Camada 1)
				if tem_linha_de_visao(camera.global_position, ponto_navmesh + Vector3(0, 1.5, 0)):
					global_position = ponto_navmesh
					return true
		else:
			global_position = ponto_navmesh
			return true

	return false

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
	
	# 1. Para o som de choro para dar foco ao susto
	cry_sound.stop()
	
	# 2. Localiza a câmera para saber exatamente para onde o jogador olha
	var camera = get_viewport().get_camera_3d()
	
	if camera:
		# Define uma posição a 1.2 metros à frente da lente da câmera
		# Usamos o eixo Z negativo da câmera (que é o 'frente' no Godot)
		var direcao_frente = -camera.global_transform.basis.z
		var posicao_jumpscare = camera.global_position + (direcao_frente * 1.2)
		
		# Teleporta a Umbra para essa posição exata
		global_position = posicao_jumpscare
		
		# Faz ela encarar a câmera perfeitamente
		look_at(camera.global_position, Vector3.UP)
		# Se o modelo estiver de costas, mantemos a correção de 180 graus
		rotate_y(deg_to_rad(180))
	else:
		# Fallback caso a câmera não seja encontrada
		var frente = player.global_transform.basis * Vector3(0, 0, -1.5)
		global_position = player.global_position + frente
		olhar_para_player()

	# 3. Força a visibilidade (caso estivesse escondida por algum motivo)
	self.visible = true
	
	# 4. Executa o vídeo de jumpscare
	# É importante que o vídeo tenha fundo transparente ou cubra a tela 
	# enquanto a modelo está posicionada ali atrás.
	utils.jumpscare_video(jumpscare_ui)
	
	# 5. Desativa o comportamento para ela sumir após o susto
	await get_tree().create_timer(1.0).timeout
	utils.umbra_active = false 
	self.visible = false

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
