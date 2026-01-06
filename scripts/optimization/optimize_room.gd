extends Area3D

# Arraste o arquivo .tscn da sala para cá no Inspetor
@export var sala_cena: PackedScene 
@export var posicao_spawn: Marker3D

var sala_instanciada = null

func _ready():
	body_entered.connect(_on_player_entered)
	body_exited.connect(_on_player_exited)

func _on_player_entered(body):
	if body.is_in_group("player"): # Certifique-se que seu player está no grupo "player"
		if sala_instanciada == null:
			print('sala adicionada')
			# Carrega e adiciona a sala na cena
			sala_instanciada = sala_cena.instantiate()
			get_parent().add_child(sala_instanciada)
			
			# Posiciona a sala no lugar correto
			sala_instanciada.global_transform = posicao_spawn.global_transform
			print("Sala do segundo andar carregada!")

func _on_player_exited(body):
	if body.is_in_group("player"):
		if sala_instanciada != null:
			sala_instanciada.queue_free()
			sala_instanciada = null
			print("Sala descarregada para poupar memória.")
