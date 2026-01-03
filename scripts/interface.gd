extends Control

@onready var battery_bar: ProgressBar = $MarginContainer/VBoxContainer/BatteryBar
@onready var battery_quantity: Label = $MarginContainer/VBoxContainer/HBoxContainer/BatteryQuantity
@onready var hotbar: HBoxContainer = $Inventory/VBoxContainer/hotbar
@onready var item_name_label: Label = $Inventory/VBoxContainer/ItemName

var name_tween: Tween
var total_slots = 4

func _ready() -> void:
	change_slot(0)
	item_name_label.modulate.a = 0
	inventory.hotbar_updated.connect(update_selection_visual)

func _process(_delta):
	var battery_value = inventory.player_battery 
	update_battery_ui(battery_value)

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_slot(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_slot(1)

func update_battery_ui(value):
	battery_bar.value = value
	battery_quantity.text = str(inventory.player_items['Battery'])
	var tween = create_tween()
	tween.tween_property(battery_bar, "value", value, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var sb = battery_bar.get_theme_stylebox("fill").duplicate()
	var main_color : Color
	if value > 70:
		main_color = Color.DARK_GREEN # Use tons mais escuros/saturados para terror
	elif value > 30:
		main_color = Color.GOLDENROD
	else:
		main_color = Color.DARK_RED
		
	sb.bg_color = main_color
	
	sb.shadow_color = main_color.darkened(0.1)
	sb.shadow_size = 6
	battery_bar.add_theme_stylebox_override("fill", sb)

func change_slot(amount):
	inventory.hotbar_current_slot = posmod(inventory.hotbar_current_slot + amount, total_slots)
	update_selection_visual()

func update_selection_visual():
	var slots = hotbar.get_children()
	var current_slot_index = inventory.hotbar_current_slot
	
	# --- Parte 1: Atualizar Bordas e Ícones (o que já tínhamos) ---
	for i in range(slots.size()):
		var slot_node = slots[i]
		var border = slot_node.get_node("SelectionBorder")
		var icon_rect = slot_node.get_node("Icon")
		
		border.visible = (i == current_slot_index)
		
		if i < inventory.player_hotbar.size() and inventory.player_hotbar[i] != null:
			icon_rect.texture = inventory.player_hotbar[i]["icon"]
			icon_rect.visible = true
		else:
			icon_rect.texture = null
			icon_rect.visible = false

	# --- Parte 2: Atualizar o Nome do Item selecionado ---
	var selected_item = inventory.player_hotbar[current_slot_index]
	
	if selected_item != null:
		animate_item_name(selected_item["name"])
	else:
		animate_item_name("") # Ou "Vazio" se preferir

func animate_item_name(new_text: String):
	if name_tween:
		name_tween.kill()
	
	if new_text == "":
		item_name_label.modulate.a = 0
		item_name_label.text = ""
		return

	item_name_label.text = new_text
	item_name_label.modulate.a = 1.0
	
	name_tween = create_tween()
	name_tween.tween_property(item_name_label, "scale", Vector2(1.1, 1.1), 0.1)
	name_tween.tween_property(item_name_label, "scale", Vector2(1.0, 1.0), 0.1)
	name_tween.tween_interval(2.0)
	
	name_tween.tween_property(item_name_label, "modulate:a", 0.0, 1.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	name_tween.tween_callback(func(): item_name_label.text = "")
