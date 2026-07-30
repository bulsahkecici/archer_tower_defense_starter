extends PanelContainer
class_name TowerPalette3D

signal tower_selected(tower_id: StringName)
signal cancel_requested

var tower_buttons: Dictionary[StringName, Button] = {}
var cost_labels: Dictionary[StringName, Label] = {}
var tower_definitions: Dictionary[StringName, TowerData] = {}
var archer_button: Button
var cost_label: Label
var cancel_button: Button


func setup(initial_build_cost: int) -> void:
	name = "TowerSelectionPanel3D"
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var safe_margins: Vector4 = SafeAreaHelper.get_safe_margins(viewport_size)
	offset_left = safe_margins.x + 20.0
	offset_right = -safe_margins.z - 20.0
	offset_bottom = -safe_margins.w - 24.0
	offset_top = offset_bottom - 390.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.09, 0.10, 0.96)
	style.border_color = Color("75b5aa")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	add_child(content)
	var title := Label.new()
	title.text = "KULE SEÇ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	content.add_child(title)

	var cards := HBoxContainer.new()
	cards.name = "TowerCards"
	cards.add_theme_constant_override("separation", 10)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cards)
	for data in TowerData.create_catalog():
		_create_tower_card(cards, data, initial_build_cost)

	cancel_button = Button.new()
	cancel_button.name = "CancelPlacement"
	cancel_button.text = "İptal"
	cancel_button.custom_minimum_size = Vector2(0.0, 58.0)
	cancel_button.add_theme_font_size_override("font_size", 22)
	cancel_button.pressed.connect(func() -> void: cancel_requested.emit())
	content.add_child(cancel_button)
	archer_button = tower_buttons[TowerData.ARCHER_ID]
	cost_label = cost_labels[TowerData.ARCHER_ID]
	set_selection_active(false)


func _create_tower_card(parent: HBoxContainer, data: TowerData, build_cost: int) -> void:
	tower_definitions[data.id] = data
	var button := Button.new()
	button.name = "%sCard" % String(data.id).capitalize()
	button.custom_minimum_size = Vector2(0.0, 230.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = ""
	button.toggle_mode = true
	button.tooltip_text = data.display_name
	var selected_style := StyleBoxFlat.new()
	selected_style.bg_color = data.accent.darkened(0.46)
	selected_style.border_color = data.accent.lightened(0.28)
	selected_style.set_border_width_all(5)
	selected_style.set_corner_radius_all(16)
	button.add_theme_stylebox_override("pressed", selected_style)
	button.pressed.connect(_on_tower_pressed.bind(data.id))
	parent.add_child(button)
	tower_buttons[data.id] = button

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	var tower_icon := ArcherTowerCardIcon3D.new()
	tower_icon.custom_minimum_size = Vector2(68.0, 68.0)
	tower_icon.configure(data)
	column.add_child(tower_icon)
	var tower_name := Label.new()
	tower_name.text = data.display_name.to_upper()
	tower_name.custom_minimum_size.y = 54.0
	tower_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tower_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tower_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tower_name.add_theme_font_size_override("font_size", 19)
	tower_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(tower_name)
	var cost_row := HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(cost_row)
	var coin := CoinIcon.new()
	coin.custom_minimum_size = Vector2(34.0, 34.0)
	cost_row.add_child(coin)
	var tower_cost := Label.new()
	tower_cost.text = str(build_cost + data.additional_cost)
	tower_cost.add_theme_font_size_override("font_size", 21)
	tower_cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(tower_cost)
	cost_labels[data.id] = tower_cost


func _on_tower_pressed(tower_id: StringName) -> void:
	tower_selected.emit(tower_id)


func set_selection_active(active: bool, tower_id: StringName = &"") -> void:
	for id in tower_buttons:
		var button: Button = tower_buttons[id]
		button.set_pressed_no_signal(active and id == tower_id)
	if is_instance_valid(cancel_button):
		cancel_button.disabled = not active
		cancel_button.modulate = Color.WHITE if active else Color(0.65, 0.65, 0.65, 0.75)


func update_availability(gold: int, minimum_build_cost: int) -> void:
	for id in tower_buttons:
		var button: Button = tower_buttons[id]
		var data: TowerData = tower_definitions[id]
		var total_cost: int = (
			minimum_build_cost + data.additional_cost
			if minimum_build_cost >= 0 else -1
		)
		cost_labels[id].text = str(total_cost) if total_cost >= 0 else "—"
		button.disabled = total_cost < 0 or gold < total_cost
