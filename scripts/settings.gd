extends Control
class_name SettingsMenu

var music_slider: HSlider
var sfx_slider: HSlider
var vibration_toggle: CheckButton
var save_manager: Node
var audio_manager: Node


func _ready() -> void:
	save_manager = get_node("/root/SaveManager")
	audio_manager = get_node("/root/AudioManager")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_apply_saved_values()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("173f38")
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(720.0, 0.0)
	content.add_theme_constant_override("separation", 30)
	center.add_child(content)
	var title := Label.new()
	title.text = "AYARLAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	content.add_child(title)
	music_slider = _add_slider(content, "Müzik")
	sfx_slider = _add_slider(content, "Efekt")
	vibration_toggle = CheckButton.new()
	vibration_toggle.text = "Titreşim"
	vibration_toggle.custom_minimum_size = Vector2(620.0, 90.0)
	vibration_toggle.add_theme_font_size_override("font_size", 30)
	content.add_child(vibration_toggle)
	var back := Button.new()
	back.text = "Geri"
	back.custom_minimum_size = Vector2(620.0, 100.0)
	content.add_child(back)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	vibration_toggle.toggled.connect(_on_vibration_toggled)
	back.pressed.connect(_go_back)


func _add_slider(parent: Control, label_text: String) -> HSlider:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 30)
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(620.0, 72.0)
	parent.add_child(slider)
	return slider


func _apply_saved_values() -> void:
	music_slider.set_value_no_signal(save_manager.music_volume)
	sfx_slider.set_value_no_signal(save_manager.sfx_volume)
	vibration_toggle.set_pressed_no_signal(save_manager.vibration_enabled)
	audio_manager.set_music_volume(save_manager.music_volume)
	audio_manager.set_sfx_volume(save_manager.sfx_volume)


func _on_music_changed(value: float) -> void:
	save_manager.music_volume = clampf(value, 0.0, 1.0)
	audio_manager.set_music_volume(save_manager.music_volume)
	save_manager.save_data()


func _on_sfx_changed(value: float) -> void:
	save_manager.sfx_volume = clampf(value, 0.0, 1.0)
	audio_manager.set_sfx_volume(save_manager.sfx_volume)
	save_manager.save_data()


func _on_vibration_toggled(enabled: bool) -> void:
	save_manager.vibration_enabled = enabled
	save_manager.save_data()


func _go_back() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
