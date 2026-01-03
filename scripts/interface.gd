extends Control

@onready var battery_bar: ProgressBar = $MarginContainer/VBoxContainer/BatteryBar
@onready var battery_quantity: Label = $MarginContainer/VBoxContainer/HBoxContainer/BatteryQuantity
@onready var hotbar: HBoxContainer = $Inventory/hotbar

var total_slots = 4

func _ready() -> void:
	change_slot(0)
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
	
	for i in range(slots.size()):
		var slot_node = slots[i]
		var border = slot_node.get_node("SelectionBorder")
		var icon_rect = slot_node.get_node("Icon") # Pegamos o nó de ícone
		
		border.visible = (i == inventory.hotbar_current_slot)
		
		if i < inventory.player_hotbar.size():
			var item = inventory.player_hotbar[i]
			
			if item != null and item.has("icon"):
				icon_rect.texture = item["icon"]
				icon_rect.visible = true
			else:
				icon_rect.texture = null
				icon_rect.visible = false
		else:
			icon_rect.texture = null
			icon_rect.visible = false
