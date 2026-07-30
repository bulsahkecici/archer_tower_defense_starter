extends Control
class_name SettingsMenu

signal close_requested

var music_slider: HSlider
var sfx_slider: HSlider
var vibration_toggle: CheckButton
var screen_shake_toggle: CheckButton
var save_manager: Node
var audio_manager: Node
var back_button: Button
var music_row: HBoxContainer
var sfx_row: HBoxContainer
var embedded_mode: bool = false
var _ui_built: bool = false


func _ready() -> void:
	if not embedded_mode:
		Engine.time_scale = 1.0
		get_tree().paused = false
	else:
		process_mode = Node.PROCESS_MODE_ALWAYS
	save_manager = get_node("/root/SaveManager")
	audio_manager = get_node("/root/AudioManager")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_apply_saved_values()


func _build_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("173f38")
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(640.0, 0.0)
	content.add_theme_constant_override("separation", 22)
	center.add_child(content)
	var title := Label.new()
	title.text = "AYARLAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	content.add_child(title)
	var music_result: Array = _add_slider(content, "Müzik")
	music_row = music_result[0] as HBoxContainer
	music_slider = music_result[1] as HSlider
	var sfx_result: Array = _add_slider(content, "Efekt")
	sfx_row = sfx_result[0] as HBoxContainer
	sfx_slider = sfx_result[1] as HSlider
	vibration_toggle = CheckButton.new()
	vibration_toggle.text = "Titreşim"
	vibration_toggle.custom_minimum_size = Vector2(0.0, 108.0)
	vibration_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vibration_toggle.add_theme_font_size_override("font_size", 30)
	content.add_child(vibration_toggle)
	screen_shake_toggle = CheckButton.new()
	screen_shake_toggle.text = "Ekran Sarsıntısı"
	screen_shake_toggle.custom_minimum_size = Vector2(0.0, 108.0)
	screen_shake_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen_shake_toggle.add_theme_font_size_override("font_size", 30)
	content.add_child(screen_shake_toggle)
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Geri"
	back_button.custom_minimum_size = Vector2(620.0, 100.0)
	content.add_child(back_button)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	vibration_toggle.toggled.connect(_on_vibration_toggled)
	screen_shake_toggle.toggled.connect(_on_screen_shake_toggled)
	back_button.pressed.connect(_go_back)


func _add_slider(parent: Control, label_text: String) -> Array:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 108.0)
	row.add_theme_constant_override("separation", 24)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(0.0, 96.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	return [row, slider]


func _apply_saved_values() -> void:
	music_slider.set_value_no_signal(save_manager.music_volume)
	sfx_slider.set_value_no_signal(save_manager.sfx_volume)
	vibration_toggle.set_pressed_no_signal(save_manager.vibration_enabled)
	screen_shake_toggle.set_pressed_no_signal(save_manager.screen_shake_enabled)
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


func _on_screen_shake_toggled(enabled: bool) -> void:
	save_manager.screen_shake_enabled = enabled
	save_manager.save_data()


func _go_back() -> void:
	if embedded_mode:
		close_requested.emit()
		return
	MenuNavigation.return_from(get_tree(), &"settings")
