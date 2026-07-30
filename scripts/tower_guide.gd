extends Control
class_name TowerGuide

signal close_requested

var embedded_mode: bool = false
var back_button: Button
var guide_texts: Dictionary[StringName, String] = {}
var _ui_built: bool = false


func _ready() -> void:
	if embedded_mode:
		process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		Engine.time_scale = 1.0
		get_tree().paused = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("102f31")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 58)
	margin.add_theme_constant_override("margin_bottom", 58)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)
	var title := Label.new()
	title.text = "KULE REHBERİ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	content.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 18)
	scroll.add_child(list)
	for data in TowerData.create_catalog():
		_add_tower_card(list, data)
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Geri"
	back_button.custom_minimum_size = Vector2(0.0, 96.0)
	back_button.add_theme_font_size_override("font_size", 30)
	back_button.pressed.connect(_go_back)
	content.add_child(back_button)


func _add_tower_card(parent: Control, data: TowerData) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 460.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.12, 0.14, 0.96)
	style.border_color = data.accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 22.0
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(150.0, 180.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func() -> void: _draw_tower_icon(icon, data))
	row.add_child(icon)
	var label := Label.new()
	var guide_text: String = data.get_guide_text()
	guide_texts[data.id] = guide_text
	label.text = guide_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 23)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)


func _draw_tower_icon(icon: Control, data: TowerData) -> void:
	var center := Vector2(icon.size.x * 0.5, 88.0)
	icon.draw_circle(center + Vector2(0.0, 50.0), 48.0, Color(0.02, 0.05, 0.06, 0.5))
	icon.draw_rect(Rect2(center + Vector2(-34.0, -12.0), Vector2(68.0, 80.0)), data.accent)
	icon.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-48.0, -8.0),
		center + Vector2(0.0, -55.0),
		center + Vector2(48.0, -8.0)
	]), data.accent.lightened(0.18))
	if data.is_heavy_projectile:
		icon.draw_line(
			center + Vector2(-48.0, -25.0),
			center + Vector2(48.0, -25.0),
			Color("d6e4dd"),
			8.0
		)


func _go_back() -> void:
	if embedded_mode:
		close_requested.emit()
		return
	MenuNavigation.return_from(get_tree(), &"tower_guide")
