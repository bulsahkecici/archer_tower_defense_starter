extends Control
class_name LevelSelect

var level_buttons: Array[Button] = []
var save_manager: Node
var back_button: Button
var _ui_built: bool = false


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	save_manager = get_node("/root/SaveManager")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("173f38")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_bottom", 56)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "BÖLÜM SEÇ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	layout.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 22)
	scroll.add_child(content)
	for data in LevelData.create_catalog():
		var button := Button.new()
		button.custom_minimum_size = Vector2(900.0, 150.0)
		button.text = "%d. %s  •  %d/3 ★" % [
			data.id, data.display_name, save_manager.get_level_stars(data.id)
		]
		button.disabled = not save_manager.is_level_unlocked(data.id)
		button.pressed.connect(func() -> void: _select_level(data.id))
		content.add_child(button)
		level_buttons.append(button)
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Geri"
	back_button.custom_minimum_size = Vector2(0.0, 96.0)
	back_button.add_theme_font_size_override("font_size", 30)
	back_button.pressed.connect(_go_back)
	layout.add_child(back_button)


func _select_level(level_id: int) -> bool:
	if not save_manager.is_level_unlocked(level_id):
		return false
	save_manager.last_level = level_id
	save_manager.save_data()
	MenuNavigation.change_scene(get_tree(), MenuNavigation.GAME)
	return true


func _go_back() -> void:
	MenuNavigation.return_from(get_tree(), &"level_select")
