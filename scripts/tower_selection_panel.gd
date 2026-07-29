extends Control
class_name TowerSelectionPanel

signal tower_selected(tower_type: ShooterUnit.TowerType)
signal closed

var spot_cost: int = 0
var economy: EconomyManager
var panel_rect: Rect2 = Rect2(110.0, 540.0, 860.0, 720.0)
var archer_button: Button
var crossbow_button: Button
var archer_cost_label: Label
var crossbow_cost_label: Label


func setup(new_spot_cost: int, economy_manager: EconomyManager) -> void:
	spot_cost = new_spot_cost
	economy = economy_manager
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	economy.gold_changed.connect(_on_gold_changed)
	_refresh_affordability()


func get_tower_cost(tower_type: ShooterUnit.TowerType) -> int:
	if tower_type == ShooterUnit.TowerType.CROSSBOW:
		return spot_cost + 15
	return spot_cost


func _build_interface() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.05, 0.07, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var panel := Panel.new()
	panel.position = panel_rect.position
	panel.size = panel_rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var title := Label.new()
	title.position = Vector2(50.0, 35.0)
	title.size = Vector2(760.0, 70.0)
	title.text = "Savunma Kulesini Seç"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.position = Vector2(70.0, 105.0)
	subtitle.size = Vector2(720.0, 45.0)
	subtitle.text = "Boş alana dokunarak kapatabilirsin"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.78, 0.84, 0.82)
	subtitle.add_theme_font_size_override("font_size", 23)
	panel.add_child(subtitle)

	archer_button = _create_tower_card(
		panel,
		Vector2(55.0, 180.0),
		"OKÇU KULESİ",
		"Dengeli hasar\nHızlı atış\nOrta menzil",
		Color("4f9e75")
	)
	archer_button.pressed.connect(
		func() -> void: tower_selected.emit(ShooterUnit.TowerType.ARCHER)
	)
	archer_cost_label = archer_button.get_node("Cost") as Label

	crossbow_button = _create_tower_card(
		panel,
		Vector2(445.0, 180.0),
		"ARBALET KULESİ",
		"Yüksek hasar\nYavaş atış\nUzun menzil",
		Color("526d96")
	)
	crossbow_button.pressed.connect(
		func() -> void: tower_selected.emit(ShooterUnit.TowerType.CROSSBOW)
	)
	crossbow_cost_label = crossbow_button.get_node("Cost") as Label

	var cancel_button := Button.new()
	cancel_button.position = Vector2(280.0, 610.0)
	cancel_button.size = Vector2(300.0, 70.0)
	cancel_button.text = "Vazgeç"
	cancel_button.add_theme_font_size_override("font_size", 28)
	cancel_button.pressed.connect(_close)
	panel.add_child(cancel_button)


func _create_tower_card(
	parent: Control,
	card_position: Vector2,
	title_text: String,
	description: String,
	accent: Color
) -> Button:
	var card := Button.new()
	card.position = card_position
	card.size = Vector2(360.0, 400.0)
	card.text = ""
	parent.add_child(card)

	var icon := Control.new()
	icon.position = Vector2(100.0, 30.0)
	icon.size = Vector2(160.0, 150.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_meta("accent", accent)
	icon.draw.connect(func() -> void: _draw_tower_icon(icon, accent))
	card.add_child(icon)

	var name_label := Label.new()
	name_label.position = Vector2(20.0, 190.0)
	name_label.size = Vector2(320.0, 55.0)
	name_label.text = title_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)

	var description_label := Label.new()
	description_label.position = Vector2(35.0, 250.0)
	description_label.size = Vector2(290.0, 92.0)
	description_label.text = description
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.add_theme_font_size_override("font_size", 22)
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(description_label)

	var cost_label := Label.new()
	cost_label.name = "Cost"
	cost_label.position = Vector2(35.0, 345.0)
	cost_label.size = Vector2(290.0, 42.0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 27)
	cost_label.modulate = Color("f5ca62")
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(cost_label)
	return card


func _draw_tower_icon(icon: Control, accent: Color) -> void:
	icon.draw_circle(Vector2(80.0, 128.0), 55.0, Color(0.08, 0.11, 0.13, 0.22))
	icon.draw_rect(Rect2(42.0, 56.0, 76.0, 82.0), accent)
	icon.draw_colored_polygon(PackedVector2Array([
		Vector2(28.0, 62.0), Vector2(80.0, 15.0), Vector2(132.0, 62.0)
	]), accent.lightened(0.16))
	icon.draw_rect(Rect2(67.0, 92.0, 26.0, 46.0), Color("413225"))


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = false
	var input_position: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		input_position = event.position
	elif event is InputEventScreenTouch:
		pressed = event.pressed
		input_position = event.position
	if pressed and not panel_rect.has_point(input_position):
		accept_event()
		_close()


func _on_gold_changed(_current_gold: int) -> void:
	_refresh_affordability()


func _refresh_affordability() -> void:
	var archer_cost: int = get_tower_cost(ShooterUnit.TowerType.ARCHER)
	var crossbow_cost: int = get_tower_cost(ShooterUnit.TowerType.CROSSBOW)
	archer_cost_label.text = "● %d ALTIN" % archer_cost
	crossbow_cost_label.text = "● %d ALTIN" % crossbow_cost
	archer_button.disabled = not economy.can_afford(archer_cost)
	crossbow_button.disabled = not economy.can_afford(crossbow_cost)


func _close() -> void:
	closed.emit()
	queue_free()
