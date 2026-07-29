extends Control
class_name TowerUpgradePanel

signal upgrade_requested
signal sell_requested
signal closed

var tower: ShooterUnit
var economy: EconomyManager
var panel_container: PanelContainer
var panel_rect: Rect2
var title_label: Label
var level_label: Label
var stats_label: Label
var next_stats_label: Label
var upgrade_button: Button
var sell_button: Button
var input_armed: bool = false


func setup(selected_tower: ShooterUnit, economy_manager: EconomyManager) -> void:
	tower = selected_tower
	economy = economy_manager
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	if not economy.gold_changed.is_connected(_on_gold_changed):
		economy.gold_changed.connect(_on_gold_changed)
	refresh()
	call_deferred("_update_panel_rect")
	call_deferred("_arm_input")


func _build_interface() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.05, 0.07, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var viewport_size: Vector2 = get_viewport_rect().size
	var safe_rect: Rect2 = SafeAreaHelper.get_safe_rect(viewport_size)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = safe_rect.position.x
	center.offset_top = safe_rect.position.y
	center.offset_right = -(viewport_size.x - safe_rect.end.x)
	center.offset_bottom = -(viewport_size.y - safe_rect.end.y)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	panel_container = PanelContainer.new()
	panel_container.custom_minimum_size = Vector2(minf(820.0, safe_rect.size.x - 36.0), 0.0)
	panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("17343a")
	style.border_color = Color("d1b35c")
	style.set_border_width_all(4)
	style.set_corner_radius_all(30)
	style.content_margin_left = 46.0
	style.content_margin_right = 46.0
	style.content_margin_top = 34.0
	style.content_margin_bottom = 34.0
	panel_container.add_theme_stylebox_override("panel", style)
	panel_container.resized.connect(_update_panel_rect)
	center.add_child(panel_container)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel_container.add_child(content)
	title_label = _create_label(content, 42)
	level_label = _create_label(content, 30)
	stats_label = _create_label(content, 28)
	next_stats_label = _create_label(content, 26)

	upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(520.0, 90.0)
	upgrade_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	upgrade_button.add_theme_font_size_override("font_size", 29)
	upgrade_button.pressed.connect(func() -> void: upgrade_requested.emit())
	content.add_child(upgrade_button)

	sell_button = Button.new()
	sell_button.custom_minimum_size = Vector2(520.0, 82.0)
	sell_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sell_button.add_theme_font_size_override("font_size", 27)
	sell_button.pressed.connect(func() -> void: sell_requested.emit())
	content.add_child(sell_button)

	var close_button := Button.new()
	close_button.custom_minimum_size = Vector2(360.0, 72.0)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.text = "Kapat"
	close_button.add_theme_font_size_override("font_size", 25)
	close_button.pressed.connect(_close)
	content.add_child(close_button)


func _create_label(parent: Control, font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func refresh() -> void:
	if not is_instance_valid(tower) or tower.tower_data == null:
		_close()
		return
	var data: TowerData = tower.tower_data
	title_label.text = data.display_name
	level_label.text = "SEVİYE %d / %d" % [tower.level, data.maximum_level]
	stats_label.text = "Hasar: %.1f   Menzil: %.0f   Atış: %.2f sn" % [
		tower.damage, tower.attack_range, tower.fire_interval
	]
	var cost: int = tower.get_upgrade_cost()
	if tower.can_upgrade():
		var next_level: int = tower.level + 1
		next_stats_label.text = "Sonraki: %.1f hasar • %.0f menzil • %.2f sn" % [
			data.get_damage(next_level),
			data.get_attack_range(next_level),
			data.get_fire_interval(next_level)
		]
		upgrade_button.text = "Yükselt  •  %d Altın" % cost
		upgrade_button.disabled = cost <= 0 or not economy.can_afford(cost)
	else:
		next_stats_label.text = "Maksimum Seviye"
		upgrade_button.text = "Maksimum Seviye"
		upgrade_button.disabled = true
	sell_button.text = "Sat  •  +%d Altın" % tower.get_sell_refund()


func _on_gold_changed(_gold: int) -> void:
	refresh()


func _gui_input(event: InputEvent) -> void:
	if not input_armed:
		accept_event()
		return
	var pressed: bool = false
	var position: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		position = event.position
	elif event is InputEventScreenTouch:
		pressed = event.pressed
		position = event.position
	if pressed and not panel_rect.has_point(position):
		accept_event()
		_close()


func _update_panel_rect() -> void:
	if is_instance_valid(panel_container):
		panel_rect = panel_container.get_global_rect()


func _arm_input() -> void:
	input_armed = true


func _close() -> void:
	closed.emit()
	queue_free()
