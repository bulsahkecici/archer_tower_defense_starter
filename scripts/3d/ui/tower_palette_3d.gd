extends PanelContainer
class_name TowerPalette3D

signal archer_selected
signal cancel_requested

var archer_button: Button
var cost_label: Label
var cancel_button: Button


func setup(cost: int) -> void:
	name = "TowerSelectionPanel3D"
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var safe_margins: Vector4 = SafeAreaHelper.get_safe_margins(viewport_size)
	offset_left = safe_margins.x + 30.0
	offset_bottom = -safe_margins.w - 30.0
	offset_right = offset_left + 460.0
	offset_top = offset_bottom - 300.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.09, 0.10, 0.94)
	style.border_color = Color("75b5aa")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	var title := Label.new()
	title.text = "KULE SEÇ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	content.add_child(title)

	archer_button = Button.new()
	archer_button.name = "ArcherCard"
	archer_button.custom_minimum_size = Vector2(410.0, 160.0)
	archer_button.text = ""
	archer_button.toggle_mode = true
	var selected_style := StyleBoxFlat.new()
	selected_style.bg_color = Color("244f43")
	selected_style.border_color = Color("8ee6a3")
	selected_style.set_border_width_all(5)
	selected_style.set_corner_radius_all(18)
	archer_button.add_theme_stylebox_override("pressed", selected_style)
	archer_button.pressed.connect(func() -> void: archer_selected.emit())
	content.add_child(archer_button)
	var card_margin := MarginContainer.new()
	card_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_margin.add_theme_constant_override("margin_left", 16)
	card_margin.add_theme_constant_override("margin_right", 16)
	card_margin.add_theme_constant_override("margin_top", 12)
	card_margin.add_theme_constant_override("margin_bottom", 12)
	card_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	archer_button.add_child(card_margin)
	var card_row := HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 18)
	card_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_margin.add_child(card_row)
	var tower_icon := ArcherTowerCardIcon3D.new()
	tower_icon.custom_minimum_size = Vector2(92.0, 92.0)
	card_row.add_child(tower_icon)
	var text_column := VBoxContainer.new()
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_row.add_child(text_column)
	var tower_name := Label.new()
	tower_name.text = "OKÇU KULESİ"
	tower_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tower_name.add_theme_font_size_override("font_size", 27)
	tower_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(tower_name)
	var cost_row := HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(cost_row)
	var coin := CoinIcon.new()
	coin.custom_minimum_size = Vector2(42.0, 42.0)
	cost_row.add_child(coin)
	cost_label = Label.new()
	cost_label.text = str(cost)
	cost_label.add_theme_font_size_override("font_size", 27)
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(cost_label)

	cancel_button = Button.new()
	cancel_button.name = "CancelPlacement"
	cancel_button.text = "İptal"
	cancel_button.custom_minimum_size = Vector2(0.0, 64.0)
	cancel_button.add_theme_font_size_override("font_size", 23)
	cancel_button.pressed.connect(func() -> void: cancel_requested.emit())
	content.add_child(cancel_button)
	set_selection_active(false)


func set_selection_active(active: bool) -> void:
	if is_instance_valid(archer_button):
		archer_button.set_pressed_no_signal(active)
		archer_button.tooltip_text = (
			"Seçildi — haritada bir platforma dokun"
			if active else "Okçu Kulesi seç"
		)
	if is_instance_valid(cancel_button):
		cancel_button.disabled = not active
		cancel_button.modulate = Color.WHITE if active else Color(0.65, 0.65, 0.65, 0.75)
