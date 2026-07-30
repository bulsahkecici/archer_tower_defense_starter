extends Control
class_name CosmeticsMenu

var cosmetic_manager: Node
var selection_buttons: Dictionary[StringName, Button] = {}
var preview_colors: Dictionary[StringName, Color] = {}


func _ready() -> void:
	Engine.time_scale = 1.0
	cosmetic_manager = get_node("/root/CosmeticManager")
	cosmetic_manager.validate_selection()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("173f38")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 70)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	var title := Label.new()
	title.text = "KOZMETİKLER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	content.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	var definitions: Dictionary[StringName, Dictionary] = cosmetic_manager.get_definitions()
	for cosmetic_id in definitions:
		var definition: Dictionary = definitions[cosmetic_id]
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0.0, 105.0)
		row.add_theme_constant_override("separation", 18)
		list.add_child(row)
		var preview := ColorRect.new()
		preview.custom_minimum_size = Vector2(92.0, 72.0)
		preview.color = definition.color
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(preview)
		preview_colors[cosmetic_id] = definition.color
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s\n%s" % [definition.name, definition.condition]
		label.add_theme_font_size_override("font_size", 23)
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(180.0, 72.0)
		var selected: bool = (
			cosmetic_manager.get_selected(definition.category) == cosmetic_id
		)
		button.text = "AKTİF" if selected else "SEÇ"
		button.disabled = selected or not cosmetic_manager.is_unlocked(cosmetic_id)
		button.pressed.connect(
			func() -> void:
				if cosmetic_manager.select_cosmetic(cosmetic_id):
					get_tree().reload_current_scene()
		)
		row.add_child(button)
		selection_buttons[cosmetic_id] = button
	var back := Button.new()
	back.text = "Geri"
	back.custom_minimum_size = Vector2(0.0, 88.0)
	back.pressed.connect(
		func() -> void:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	content.add_child(back)
