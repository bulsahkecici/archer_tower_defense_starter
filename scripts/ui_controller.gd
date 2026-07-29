extends Node
class_name UIController

signal restart_requested
signal ability_requested
signal pause_requested
signal resume_requested
signal next_level_requested

var interface_layer: CanvasLayer
var gold_label: Label
var wave_label: Label
var base_label: Label
var message_label: Label
var help_label: Label
var boss_warning_label: Label
var game_over_layer: CanvasLayer
var boss_warning_wave: int = -1
var gold_tween: Tween
var base_tween: Tween
var boss_warning_tween: Tween
var ability_button: Button
var pause_button: Button
var pause_layer: CanvasLayer
var victory_layer: CanvasLayer


func setup() -> void:
	interface_layer = CanvasLayer.new()
	interface_layer.name = "Interface"
	interface_layer.layer = 10
	add_child(interface_layer)
	_build_hud()


func _build_hud() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var margins: Vector4 = SafeAreaHelper.get_safe_margins(viewport_size)
	var safe_ui := Control.new()
	safe_ui.name = "SafeUI"
	safe_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface_layer.add_child(safe_ui)

	var top_margin := MarginContainer.new()
	top_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_margin.offset_left = margins.x
	top_margin.offset_top = margins.y
	top_margin.offset_right = -margins.z
	top_margin.offset_bottom = margins.y + 96.0
	top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_ui.add_child(top_margin)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_margin.add_child(top_row)
	gold_label = _create_hud_pill(top_row, Color("d59a32"))
	wave_label = _create_hud_pill(top_row, Color("487ca8"))
	base_label = _create_hud_pill(top_row, Color("b34f54"))

	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-370.0, margins.y + 116.0)
	message_label.size = Vector2(740.0, 58.0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 30)
	message_label.modulate = Color("ffe08a")
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_ui.add_child(message_label)

	boss_warning_label = Label.new()
	boss_warning_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_warning_label.position = Vector2(-300.0, margins.y + 192.0)
	boss_warning_label.size = Vector2(600.0, 90.0)
	boss_warning_label.text = "◆  BOSS YAKLAŞIYOR  ◆"
	boss_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_warning_label.add_theme_font_size_override("font_size", 40)
	boss_warning_label.add_theme_color_override("font_color", Color("ffd785"))
	boss_warning_label.add_theme_color_override("font_outline_color", Color("492536"))
	boss_warning_label.add_theme_constant_override("outline_size", 8)
	boss_warning_label.visible = false
	boss_warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_ui.add_child(boss_warning_label)

	help_label = Label.new()
	help_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	help_label.position = Vector2(-440.0, -margins.w - 50.0)
	help_label.size = Vector2(880.0, 50.0)
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.add_theme_font_size_override("font_size", 25)
	help_label.modulate = Color(1.0, 1.0, 1.0, 0.88)
	help_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_ui.add_child(help_label)

	ability_button = Button.new()
	ability_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ability_button.position = Vector2(-330.0 - margins.z, -190.0 - margins.w)
	ability_button.size = Vector2(300.0, 100.0)
	ability_button.text = "OK YAĞMURU"
	ability_button.add_theme_font_size_override("font_size", 26)
	ability_button.pressed.connect(func() -> void: ability_requested.emit())
	safe_ui.add_child(ability_button)

	pause_button = Button.new()
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.position = Vector2(-150.0 - margins.z, margins.y)
	pause_button.size = Vector2(120.0, 82.0)
	pause_button.text = "Ⅱ"
	pause_button.add_theme_font_size_override("font_size", 30)
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	safe_ui.add_child(pause_button)


func _create_hud_pill(parent: Control, accent: Color) -> Label:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(0.0, 88.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.10, 0.90)
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(24)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color("f8f4df"))
	panel.add_child(label)
	return label


func update_gold(current_gold: int, animate: bool = true) -> void:
	gold_label.text = "●  %d" % current_gold
	if not animate:
		return
	if gold_tween != null and gold_tween.is_valid():
		gold_tween.kill()
	gold_label.scale = Vector2.ONE
	gold_label.pivot_offset = gold_label.size * 0.5
	gold_tween = create_tween()
	gold_tween.tween_property(gold_label, "scale", Vector2(1.10, 1.10), 0.07)
	gold_tween.tween_property(gold_label, "scale", Vector2.ONE, 0.12)


func update_status(wave: int, health: int, active_enemies: int = -1) -> void:
	wave_label.text = "DALGA  %d" % wave
	base_label.text = "◆  %d" % health
	if active_enemies >= 0:
		help_label.text = "Aktif düşman: %d  •  Kule kurmak için platforma dokun" % active_enemies
	else:
		help_label.text = "Kule kurmak için işaretli platformlardan birine dokun"


func set_message(text: String) -> void:
	message_label.text = text


func update_ability_cooldown(remaining: float) -> void:
	if not is_instance_valid(ability_button):
		return
	ability_button.disabled = remaining > 0.0
	ability_button.text = (
		"OK YAĞMURU  %.0f" % ceil(remaining)
		if remaining > 0.0 else "OK YAĞMURU"
	)


func play_base_feedback() -> void:
	if base_tween != null and base_tween.is_valid():
		base_tween.kill()
	base_label.modulate = Color(1.0, 0.48, 0.48)
	base_tween = create_tween()
	base_tween.tween_property(base_label, "modulate", Color.WHITE, 0.24)


func show_boss_warning(wave: int) -> void:
	if boss_warning_wave == wave:
		return
	boss_warning_wave = wave
	boss_warning_label.visible = true
	boss_warning_label.modulate.a = 0.0
	boss_warning_label.scale = Vector2(0.88, 0.88)
	boss_warning_label.pivot_offset = boss_warning_label.size * 0.5
	if boss_warning_tween != null and boss_warning_tween.is_valid():
		boss_warning_tween.kill()
	boss_warning_tween = create_tween()
	boss_warning_tween.set_parallel(true)
	boss_warning_tween.tween_property(boss_warning_label, "modulate:a", 1.0, 0.22)
	boss_warning_tween.tween_property(boss_warning_label, "scale", Vector2.ONE, 0.30)
	boss_warning_tween.set_parallel(false)
	boss_warning_tween.tween_interval(1.55)
	boss_warning_tween.tween_property(boss_warning_label, "modulate:a", 0.0, 0.28)
	boss_warning_tween.tween_callback(func() -> void: boss_warning_label.visible = false)


func show_game_over(wave: int, total_gold: int) -> CanvasLayer:
	if is_instance_valid(game_over_layer):
		return game_over_layer
	game_over_layer = CanvasLayer.new()
	game_over_layer.layer = 30
	add_child(game_over_layer)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.03, 0.05, 0.82)
	game_over_layer.add_child(shade)

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var safe_rect: Rect2 = SafeAreaHelper.get_safe_rect(viewport_size)
	var center := CenterContainer.new()
	center.name = "SafeGameOverCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = safe_rect.position.x
	center.offset_top = safe_rect.position.y
	center.offset_right = -(viewport_size.x - safe_rect.end.x)
	center.offset_bottom = -(viewport_size.y - safe_rect.end.y)
	game_over_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(760.0, safe_rect.size.x - 36.0), 590.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("15353b")
	style.border_color = Color("c8a85b")
	style.set_border_width_all(5)
	style.set_corner_radius_all(34)
	style.content_margin_left = 70.0
	style.content_margin_right = 70.0
	style.content_margin_top = 58.0
	style.content_margin_bottom = 58.0
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 34)
	panel.add_child(content)
	var title := Label.new()
	title.text = "SAVUNMA DÜŞTÜ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 62)
	title.add_theme_color_override("font_color", Color("ffd88b"))
	content.add_child(title)
	var result := Label.new()
	result.custom_minimum_size = Vector2(620.0, 150.0)
	result.text = "Ulaşılan dalga: %d\nKazanılan toplam altın: %d" % [wave, total_gold]
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", 36)
	content.add_child(result)
	var restart := Button.new()
	restart.custom_minimum_size = Vector2(440.0, 110.0)
	restart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart.text = "Yeniden Başlat"
	restart.add_theme_font_size_override("font_size", 32)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	content.add_child(restart)
	panel.scale = Vector2(0.86, 0.86)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.24)
	tween.tween_property(panel, "modulate:a", 1.0, 0.20)
	return game_over_layer


func show_pause() -> CanvasLayer:
	if is_instance_valid(pause_layer):
		return pause_layer
	pause_layer = _create_action_layer("OYUN DURAKLATILDI", [
		["Devam Et", func() -> void: resume_requested.emit()],
		["Yeniden Başlat", func() -> void: restart_requested.emit()],
		["Ayarlar", func() -> void: _change_scene_unpaused("res://scenes/settings.tscn")],
		["Bölüm Seçimi", func() -> void: _change_scene_unpaused("res://scenes/level_select.tscn")],
		["Ana Menü", func() -> void: _change_scene_unpaused("res://scenes/main_menu.tscn")]
	])
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	return pause_layer


func hide_pause() -> void:
	if is_instance_valid(pause_layer):
		pause_layer.queue_free()
	pause_layer = null


func show_victory(
	level_name: String,
	stars: int,
	health: int,
	total_gold: int,
	tower_count: int = 0
) -> CanvasLayer:
	if is_instance_valid(victory_layer):
		return victory_layer
	victory_layer = _create_action_layer(
		"BÖLÜM TAMAMLANDI\n%s\n%s\nKale: %d  Altın: %d  Kule: %d" % [
			level_name, "★".repeat(clampi(stars, 1, 3)), health, total_gold, tower_count
		],
		[
			["Tekrar Oyna", func() -> void: restart_requested.emit()],
			["Sonraki Bölüm", func() -> void: next_level_requested.emit()],
			["Bölüm Seçimi", func() -> void: _change_scene_unpaused("res://scenes/level_select.tscn")]
		]
	)
	return victory_layer


func _change_scene_unpaused(scene_path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)


func _create_action_layer(title_text: String, actions: Array) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 35
	add_child(layer)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.03, 0.04, 0.86)
	layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.name = "SafeActionCenter"
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var safe_rect: Rect2 = SafeAreaHelper.get_safe_rect(viewport_size)
	center.offset_left = safe_rect.position.x
	center.offset_top = safe_rect.position.y
	center.offset_right = -(viewport_size.x - safe_rect.end.x)
	center.offset_bottom = -(viewport_size.y - safe_rect.end.y)
	layer.add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(720.0, 0.0)
	content.add_theme_constant_override("separation", 24)
	center.add_child(content)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	content.add_child(title)
	for action in actions:
		var button := Button.new()
		button.custom_minimum_size = Vector2(580.0, 92.0)
		button.text = String(action[0])
		button.pressed.connect(action[1])
		content.add_child(button)
	return layer


func reset() -> void:
	boss_warning_wave = -1
	if boss_warning_tween != null and boss_warning_tween.is_valid():
		boss_warning_tween.kill()
	if is_instance_valid(boss_warning_label):
		boss_warning_label.visible = false
	if is_instance_valid(game_over_layer):
		game_over_layer.queue_free()
	game_over_layer = null
	hide_pause()
	if is_instance_valid(victory_layer):
		victory_layer.queue_free()
	victory_layer = null
