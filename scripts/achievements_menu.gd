extends Control
class_name AchievementsMenu

var rows: Array[Control] = []
var achievement_manager: Node


func _ready() -> void:
	Engine.time_scale = 1.0
	achievement_manager = get_node("/root/AchievementManager")
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
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)
	var title := Label.new()
	title.text = "BAŞARIMLAR"
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
	for achievement_id in achievement_manager.get_definitions():
		var definition: Dictionary = achievement_manager.get_definitions()[achievement_id]
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0.0, 112.0)
		var label := Label.new()
		var progress: int = achievement_manager.get_progress(achievement_id)
		var target: int = int(definition.target)
		label.text = "%s  %s\n%s\n%d / %d" % [
			"✓" if achievement_manager.is_unlocked(achievement_id) else "○",
			String(definition.title),
			String(definition.description),
			progress,
			target
		]
		label.add_theme_font_size_override("font_size", 24)
		row.add_child(label)
		list.add_child(row)
		rows.append(row)
	var back := Button.new()
	back.text = "Geri"
	back.custom_minimum_size = Vector2(0.0, 88.0)
	back.pressed.connect(
		func() -> void:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	content.add_child(back)
