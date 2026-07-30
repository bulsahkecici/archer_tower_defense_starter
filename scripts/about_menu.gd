extends Control
class_name AboutMenu

var back_button: Button
var about_label: Label
var _ui_built: bool = false


func _ready() -> void:
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
	background.color = Color("173f38")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 70)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	margin.add_child(content)
	var title := Label.new()
	title.text = "HAKKINDA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	content.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	about_label = Label.new()
	about_label.text = GameMetadata.get_about_text()
	about_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about_label.custom_minimum_size = Vector2(0.0, 720.0)
	about_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	about_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	about_label.add_theme_font_size_override("font_size", 28)
	scroll.add_child(about_label)
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Geri"
	back_button.custom_minimum_size = Vector2(0.0, 96.0)
	back_button.add_theme_font_size_override("font_size", 30)
	back_button.pressed.connect(_go_back)
	content.add_child(back_button)


func _go_back() -> void:
	MenuNavigation.return_from(get_tree(), &"about")
