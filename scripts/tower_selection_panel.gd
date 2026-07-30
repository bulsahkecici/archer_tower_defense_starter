extends Control
class_name TowerSelectionPanel

signal tower_selected(tower_type: ShooterUnit.TowerType)
signal tower_previewed(tower_type: ShooterUnit.TowerType)
signal closed

var spot_cost: int = 0
var economy: EconomyManager
var panel_rect: Rect2 = Rect2()
var panel_container: PanelContainer
var archer_button: Button
var crossbow_button: Button
var ice_button: Button
var bomb_button: Button
var archer_cost_label: Label
var crossbow_cost_label: Label
var archer_data: TowerData = TowerData.create_archer()
var crossbow_data: TowerData = TowerData.create_crossbow()
var ice_data: TowerData = TowerData.create_ice()
var bomb_data: TowerData = TowerData.create_bomb()
var input_armed: bool = false


func setup(new_spot_cost: int, economy_manager: EconomyManager) -> void:
	spot_cost = new_spot_cost
	economy = economy_manager
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	if not economy.gold_changed.is_connected(_on_gold_changed):
		economy.gold_changed.connect(_on_gold_changed)
	_refresh_affordability()
	call_deferred("_update_panel_rect")
	call_deferred("_arm_input")


func get_tower_cost(tower_type: ShooterUnit.TowerType) -> int:
	return spot_cost + get_tower_data(tower_type).additional_cost


func get_tower_data(tower_type: ShooterUnit.TowerType) -> TowerData:
	if tower_type == ShooterUnit.TowerType.CROSSBOW:
		return crossbow_data
	if tower_type == ShooterUnit.TowerType.ICE:
		return ice_data
	if tower_type == ShooterUnit.TowerType.BOMB:
		return bomb_data
	return archer_data


func _build_interface() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.05, 0.07, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var viewport_size: Vector2 = get_viewport_rect().size
	var safe_rect: Rect2 = SafeAreaHelper.get_safe_rect(viewport_size)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = safe_rect.position.x
	center.offset_top = safe_rect.position.y
	center.offset_right = -(viewport_size.x - safe_rect.end.x)
	center.offset_bottom = -(viewport_size.y - safe_rect.end.y)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 18)
	outer_margin.add_theme_constant_override("margin_top", 18)
	outer_margin.add_theme_constant_override("margin_right", 18)
	outer_margin.add_theme_constant_override("margin_bottom", 18)
	outer_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(outer_margin)

	panel_container = PanelContainer.new()
	panel_container.custom_minimum_size = Vector2(
		minf(860.0, safe_rect.size.x - 36.0),
		0.0
	)
	panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("17343a")
	panel_style.border_color = Color("75b5aa")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(30)
	panel_style.content_margin_left = 42.0
	panel_style.content_margin_right = 42.0
	panel_style.content_margin_top = 32.0
	panel_style.content_margin_bottom = 30.0
	panel_container.add_theme_stylebox_override("panel", panel_style)
	panel_container.resized.connect(_update_panel_rect)
	outer_margin.add_child(panel_container)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel_container.add_child(content)

	var title := Label.new()
	title.custom_minimum_size = Vector2(0.0, 60.0)
	title.text = "Savunma Kulesini Seç"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.custom_minimum_size = Vector2(0.0, 38.0)
	subtitle.text = "Kartın tamamına dokunabilirsin"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.78, 0.84, 0.82)
	subtitle.add_theme_font_size_override("font_size", 22)
	content.add_child(subtitle)

	var cards := GridContainer.new()
	cards.columns = 2 if safe_rect.size.x >= 820.0 else 1
	cards.add_theme_constant_override("h_separation", 24)
	cards.add_theme_constant_override("v_separation", 18)
	cards.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(cards)

	archer_button = _create_tower_card(cards, archer_data)
	archer_button.pressed.connect(
		func() -> void: tower_selected.emit(ShooterUnit.TowerType.ARCHER)
	)
	archer_button.mouse_entered.connect(
		func() -> void: tower_previewed.emit(ShooterUnit.TowerType.ARCHER)
	)
	archer_cost_label = archer_button.get_node("Content/CostRow/Cost") as Label

	crossbow_button = _create_tower_card(cards, crossbow_data)
	crossbow_button.pressed.connect(
		func() -> void: tower_selected.emit(ShooterUnit.TowerType.CROSSBOW)
	)
	crossbow_button.mouse_entered.connect(
		func() -> void: tower_previewed.emit(ShooterUnit.TowerType.CROSSBOW)
	)
	crossbow_cost_label = crossbow_button.get_node("Content/CostRow/Cost") as Label

	ice_button = _create_tower_card(cards, ice_data)
	ice_button.pressed.connect(func() -> void: tower_selected.emit(ShooterUnit.TowerType.ICE))
	ice_button.mouse_entered.connect(
		func() -> void: tower_previewed.emit(ShooterUnit.TowerType.ICE)
	)

	bomb_button = _create_tower_card(cards, bomb_data)
	bomb_button.pressed.connect(func() -> void: tower_selected.emit(ShooterUnit.TowerType.BOMB))
	bomb_button.mouse_entered.connect(
		func() -> void: tower_previewed.emit(ShooterUnit.TowerType.BOMB)
	)

	var cancel_button := Button.new()
	cancel_button.custom_minimum_size = Vector2(300.0, 72.0)
	cancel_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_button.text = "Vazgeç"
	cancel_button.add_theme_font_size_override("font_size", 27)
	cancel_button.pressed.connect(_close)
	content.add_child(cancel_button)


func _create_tower_card(
	parent: Control,
	data: TowerData
) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(360.0, 310.0)
	card.text = ""
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.13, 0.22, 0.23, 0.96)
	normal_style.border_color = data.accent
	normal_style.set_border_width_all(4)
	normal_style.set_corner_radius_all(22)
	card.add_theme_stylebox_override("normal", normal_style)
	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = normal_style.bg_color.lightened(0.08)
	card.add_theme_stylebox_override("hover", hover_style)
	var pressed_style := normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = data.accent.darkened(0.25)
	card.add_theme_stylebox_override("pressed", pressed_style)
	parent.add_child(card)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 24.0
	content.offset_top = 20.0
	content.offset_right = -24.0
	content.offset_bottom = -18.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 7)
	card.add_child(content)

	var icon := Control.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(160.0, 150.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func() -> void: _draw_tower_icon(icon, data))
	content.add_child(icon)

	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(300.0, 48.0)
	name_label.text = data.display_name.to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)

	var cost_row := HBoxContainer.new()
	cost_row.name = "CostRow"
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(cost_row)
	var coin := CoinIcon.new()
	cost_row.add_child(coin)
	var cost_label := Label.new()
	cost_label.name = "Cost"
	cost_label.custom_minimum_size = Vector2(90.0, 42.0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 26)
	cost_label.modulate = Color("f5ca62")
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(cost_label)
	return card


func _draw_tower_icon(icon: Control, data: TowerData) -> void:
	var center := Vector2(icon.size.x * 0.5, 75.0)
	icon.draw_circle(center + Vector2(0.0, 53.0), 55.0, Color(0.08, 0.11, 0.13, 0.22))
	icon.draw_rect(Rect2(center + Vector2(-38.0, -19.0), Vector2(76.0, 82.0)), data.accent)
	if data.is_heavy_projectile:
		icon.draw_line(center + Vector2(-53.0, -28.0), center + Vector2(53.0, -28.0), Color("a8dce5"), 11.0)
		icon.draw_line(center + Vector2(-38.0, -51.0), center + Vector2(38.0, -5.0), Color("263b52"), 8.0)
		icon.draw_line(center + Vector2(38.0, -51.0), center + Vector2(-38.0, -5.0), Color("263b52"), 8.0)
	else:
		icon.draw_colored_polygon(PackedVector2Array([
			center + Vector2(-52.0, -13.0),
			center + Vector2(0.0, -60.0),
			center + Vector2(52.0, -13.0)
		]), data.accent.lightened(0.16))
		icon.draw_arc(center + Vector2(24.0, -29.0), 28.0, -1.25, 1.25, 18, Color("8b5d2c"), 6.0)
	icon.draw_rect(Rect2(center + Vector2(-13.0, 17.0), Vector2(26.0, 46.0)), Color("413225"))


func _gui_input(event: InputEvent) -> void:
	if not input_armed:
		accept_event()
		return
	var pressed: bool = false
	var input_position: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		input_position = event.position
	elif event is InputEventScreenTouch:
		pressed = event.pressed
		input_position = event.position
	if pressed and not panel_rect.has_point(input_position):
		accept_event()
		_close()


func _on_gold_changed(_current_gold: int) -> void:
	_refresh_affordability()


func _refresh_affordability() -> void:
	var archer_cost: int = get_tower_cost(ShooterUnit.TowerType.ARCHER)
	var crossbow_cost: int = get_tower_cost(ShooterUnit.TowerType.CROSSBOW)
	archer_cost_label.text = str(archer_cost)
	crossbow_cost_label.text = str(crossbow_cost)
	archer_button.disabled = not economy.can_afford(archer_cost)
	crossbow_button.disabled = not economy.can_afford(crossbow_cost)
	var ice_cost: int = get_tower_cost(ShooterUnit.TowerType.ICE)
	var bomb_cost: int = get_tower_cost(ShooterUnit.TowerType.BOMB)
	var ice_label: Label = ice_button.get_node("Content/CostRow/Cost") as Label
	var bomb_label: Label = bomb_button.get_node("Content/CostRow/Cost") as Label
	ice_label.text = str(ice_cost)
	bomb_label.text = str(bomb_cost)
	ice_button.disabled = not economy.can_afford(ice_cost)
	bomb_button.disabled = not economy.can_afford(bomb_cost)


func _update_panel_rect() -> void:
	if is_instance_valid(panel_container):
		panel_rect = panel_container.get_global_rect()


func _arm_input() -> void:
	input_armed = true


func _close() -> void:
	closed.emit()
	queue_free()


func preview_tower(tower_type: ShooterUnit.TowerType) -> void:
	tower_previewed.emit(tower_type)
