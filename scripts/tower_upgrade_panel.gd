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
var target_mode_selector: OptionButton
var synergy_label: Label
var input_armed: bool = false
var upgrade_cost_override: int = -1


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
	synergy_label = _create_label(content, 23)

	target_mode_selector = OptionButton.new()
	target_mode_selector.custom_minimum_size = Vector2(520.0, 70.0)
	target_mode_selector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	target_mode_selector.add_item("En Yakın", ShooterUnit.TargetMode.NEAREST)
	target_mode_selector.add_item("Yolda İlk", ShooterUnit.TargetMode.FIRST)
	target_mode_selector.add_item("En Yüksek Can", ShooterUnit.TargetMode.HIGHEST_HEALTH)
	target_mode_selector.add_item("En Düşük Can", ShooterUnit.TargetMode.LOWEST_HEALTH)
	target_mode_selector.item_selected.connect(_on_target_mode_selected)
	var target_label := Label.new()
	target_label.text = "HEDEFLEME MODU"
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.add_theme_font_size_override("font_size", 22)
	content.add_child(target_label)
	content.add_child(target_mode_selector)

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
	stats_label.text = data.get_role_summary()
	stats_label.tooltip_text = data.get_role_summary()
	var cost: int = (
		upgrade_cost_override
		if upgrade_cost_override >= 0 else tower.get_upgrade_cost()
	)
	if tower.can_upgrade():
		var next_level: int = tower.level + 1
		var damage_factor: float = tower.damage / maxf(0.01, tower.base_damage_stat)
		var range_factor: float = tower.attack_range / maxf(0.01, tower.base_range_stat)
		var interval_factor: float = (
			tower.fire_interval / maxf(0.01, tower.base_fire_interval_stat)
		)
		next_stats_label.text = (
			"Hasar: %.1f → %.1f\nMenzil: %.0f → %.0f\nAtış: %.2f sn → %.2f sn"
		) % [
			tower.damage,
			data.get_damage(next_level) * damage_factor,
			tower.attack_range,
			data.get_attack_range(next_level) * range_factor,
			tower.fire_interval,
			data.get_fire_interval(next_level) * interval_factor
		]
		upgrade_button.text = "YÜKSELT: %d ALTIN" % cost
		upgrade_button.disabled = cost <= 0 or not economy.can_afford(cost)
	else:
		next_stats_label.text = "Maksimum Seviye"
		upgrade_button.text = "Maksimum Seviye"
		upgrade_button.disabled = true
	sell_button.text = "SAT: +%d ALTIN" % tower.get_sell_refund()
	title_label.tooltip_text = data.get_role_summary()
	var active_synergies: Array[String] = tower.get_active_modifier_descriptions()
	synergy_label.text = (
		"AKTİF SİNERJİLER\n%s" % "\n".join(active_synergies)
		if not active_synergies.is_empty() else "Aktif sinerji yok"
	)
	for index in target_mode_selector.item_count:
		if target_mode_selector.get_item_id(index) == tower.target_mode:
			target_mode_selector.select(index)
			break


func _on_target_mode_selected(index: int) -> void:
	if is_instance_valid(tower):
		tower.target_mode = target_mode_selector.get_item_id(index) as ShooterUnit.TargetMode


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
