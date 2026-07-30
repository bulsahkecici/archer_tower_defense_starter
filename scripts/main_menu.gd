extends Control
class_name MainMenu

var start_button: Button
var vertical_slice_button: Button
var level_select_button: Button
var settings_button: Button
var about_button: Button
var endless_button: Button
var achievements_button: Button
var cosmetics_button: Button
var tower_guide_button: Button
var save_manager: Node
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
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_bottom", 54)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	margin.add_child(content)
	var title := Label.new()
	title.text = GameMetadata.GAME_NAME.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	content.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.name = "MenuScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var buttons := VBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_theme_constant_override("separation", 14)
	scroll.add_child(buttons)
	start_button = _button(buttons, "Oyuna Başla")
	vertical_slice_button = _button(buttons, "3D Dikey Kesit  •  PROTOTİP")
	endless_button = _button(buttons, "Sonsuz Mod")
	level_select_button = _button(buttons, "Bölüm Seç")
	achievements_button = _button(buttons, "Başarımlar")
	tower_guide_button = _button(buttons, "Kule Rehberi")
	cosmetics_button = _button(buttons, "Kozmetikler")
	settings_button = _button(buttons, "Ayarlar")
	about_button = _button(buttons, "Hakkında")
	start_button.pressed.connect(func() -> void: _start_level(save_manager.last_level))
	vertical_slice_button.pressed.connect(
		func() -> void:
			MenuNavigation.change_scene(get_tree(), MenuNavigation.GAME_3D)
	)
	endless_button.disabled = not save_manager.is_endless_unlocked()
	endless_button.text = (
		"Sonsuz Mod  •  Rekor %d" % save_manager.endless_high_wave
		if save_manager.is_endless_unlocked() else "Sonsuz Mod  •  KİLİTLİ"
	)
	endless_button.pressed.connect(_start_endless)
	level_select_button.pressed.connect(_open_level_select)
	settings_button.pressed.connect(_show_settings)
	achievements_button.pressed.connect(
		func() -> void:
			MenuNavigation.change_scene(get_tree(), "res://scenes/achievements.tscn")
	)
	tower_guide_button.pressed.connect(
		func() -> void:
			MenuNavigation.open_with_return(
				get_tree(), MenuNavigation.TOWER_GUIDE, &"tower_guide"
			)
	)
	cosmetics_button.pressed.connect(
		func() -> void:
			MenuNavigation.open_with_return(
				get_tree(), MenuNavigation.COSMETICS, &"cosmetics"
			)
	)
	about_button.pressed.connect(
		func() -> void:
			MenuNavigation.open_with_return(get_tree(), MenuNavigation.ABOUT, &"about")
	)


func _button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 92.0)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 30)
	parent.add_child(button)
	return button


func _start_level(level_id: int) -> bool:
	if not save_manager.is_level_unlocked(level_id):
		return false
	save_manager.last_level = level_id
	save_manager.selected_game_mode = &"story"
	save_manager.save_data()
	MenuNavigation.change_scene(get_tree(), MenuNavigation.GAME)
	return true


func _start_endless() -> bool:
	if not save_manager.is_endless_unlocked():
		return false
	save_manager.selected_game_mode = &"endless"
	MenuNavigation.change_scene(get_tree(), MenuNavigation.GAME)
	return true


func _open_level_select() -> void:
	MenuNavigation.open_with_return(
		get_tree(), MenuNavigation.LEVEL_SELECT, &"level_select"
	)


func _show_settings() -> void:
	MenuNavigation.open_with_return(get_tree(), MenuNavigation.SETTINGS, &"settings")
