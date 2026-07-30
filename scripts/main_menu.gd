extends Control
class_name MainMenu

var start_button: Button
var level_select_button: Button
var settings_button: Button
var about_button: Button
var save_manager: Node


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	save_manager = get_node("/root/SaveManager")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("173f38")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(700.0, 0.0)
	content.add_theme_constant_override("separation", 28)
	center.add_child(content)
	var title := Label.new()
	title.text = "ARCHER TOWER DEFENSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	content.add_child(title)
	start_button = _button(content, "Oyuna Başla")
	level_select_button = _button(content, "Bölüm Seç")
	settings_button = _button(content, "Ayarlar")
	about_button = _button(content, "Hakkında")
	start_button.pressed.connect(func() -> void: _start_level(save_manager.last_level))
	level_select_button.pressed.connect(_open_level_select)
	settings_button.pressed.connect(_show_settings)
	about_button.pressed.connect(func() -> void: title.text = "Özgün Godot kule savunması")


func _button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(620.0, 105.0)
	button.add_theme_font_size_override("font_size", 32)
	parent.add_child(button)
	return button


func _start_level(level_id: int) -> bool:
	if not save_manager.is_level_unlocked(level_id):
		return false
	save_manager.last_level = level_id
	save_manager.save_data()
	get_tree().change_scene_to_file("res://main.tscn")
	return true


func _open_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _show_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")
