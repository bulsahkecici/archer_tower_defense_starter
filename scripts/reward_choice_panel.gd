extends Control
class_name RewardChoicePanel

signal reward_selected(reward_id: StringName)

var choices: Array[Dictionary] = []
var selection_locked: bool = false
var selection_count: int = 0
var choice_buttons: Array[Button] = []


func setup(reward_choices: Array[Dictionary]) -> void:
	choices = reward_choices.duplicate(true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()


func choose_reward(reward_id: StringName) -> bool:
	if selection_locked:
		return false
	var valid_choice: bool = choices.any(
		func(choice: Dictionary) -> bool:
			return StringName(choice.get("id", &"")) == reward_id
	)
	if not valid_choice:
		return false
	selection_locked = true
	selection_count += 1
	for button in choice_buttons:
		button.disabled = true
	reward_selected.emit(reward_id)
	return true


func _build_interface() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.03, 0.04, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(760.0, 0.0)
	content.add_theme_constant_override("separation", 22)
	center.add_child(content)
	var title := Label.new()
	title.text = "DALGA ÖDÜLÜNÜ SEÇ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 43)
	content.add_child(title)
	for choice in choices:
		var reward_id: StringName = StringName(choice.get("id", &""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(720.0, 112.0)
		button.text = "%s\n%s" % [
			String(choice.get("title", "")),
			String(choice.get("description", ""))
		]
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(
			func() -> void: choose_reward(reward_id)
		)
		content.add_child(button)
		choice_buttons.append(button)
