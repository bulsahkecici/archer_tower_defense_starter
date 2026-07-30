extends Control
class_name LevelSelect

var level_buttons: Array[Button] = []
var save_manager: Node


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	save_manager = get_node("/root/SaveManager")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(1000.0, 0.0)
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


func _select_level(level_id: int) -> bool:
	if not save_manager.is_level_unlocked(level_id):
		return false
	save_manager.last_level = level_id
	save_manager.save_data()
	get_tree().change_scene_to_file("res://main.tscn")
	return true
