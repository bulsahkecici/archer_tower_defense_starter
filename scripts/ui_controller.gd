extends Node
class_name UIController

signal restart_requested
signal ability_requested
signal pause_requested
signal resume_requested
signal next_level_requested
signal speed_requested(speed: float)
signal wave_preview_ready
signal tutorial_skipped
signal reward_selected(reward_id: StringName)

const WavePreviewPanelScript = preload("res://scripts/wave_preview_panel.gd")
const TutorialOverlayScript = preload("res://scripts/tutorial_overlay.gd")
const RewardChoicePanelScript = preload("res://scripts/reward_choice_panel.gd")
const PerformancePanelScript = preload("res://scripts/performance_panel.gd")

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
var speed_button: Button
var selected_speed: float = 1.0
var wave_preview_layer: CanvasLayer
var wave_preview_panel: WavePreviewPanel
var tutorial_layer: CanvasLayer
var tutorial_overlay: FirstLevelTutorialOverlay
var boss_bar_container: PanelContainer
var boss_name_label: Label
var boss_health_label: Label
var boss_progress: ProgressBar
var tracked_bosses: Array[Node] = []
var ability_cooldown_duration: float = 25.0
var reward_layer: CanvasLayer
var reward_panel: RewardChoicePanel
var achievement_notification: PanelContainer
var achievement_notification_tween: Tween
var achievement_notification_count: int = 0
var debug_panel: DebugPerformancePanel
var last_summary_text: String = ""


func setup() -> void:
	interface_layer = CanvasLayer.new()
	interface_layer.name = "Interface"
	interface_layer.layer = 10
	add_child(interface_layer)
	_build_hud()
	debug_panel = PerformancePanelScript.new()
	interface_layer.add_child(debug_panel)
	debug_panel.setup(get_parent())


func _process(_delta: float) -> void:
	_update_boss_bar()


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

	speed_button = Button.new()
	speed_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	speed_button.position = Vector2(-290.0 - margins.z, margins.y)
	speed_button.size = Vector2(120.0, 82.0)
	speed_button.text = "1×"
	speed_button.add_theme_font_size_override("font_size", 28)
	speed_button.pressed.connect(_toggle_speed)
	safe_ui.add_child(speed_button)
	_build_boss_bar(safe_ui, margins)


func _build_boss_bar(parent: Control, margins: Vector4) -> void:
	boss_bar_container = PanelContainer.new()
	boss_bar_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_bar_container.offset_left = margins.x + 160.0
	boss_bar_container.offset_top = margins.y + 104.0
	boss_bar_container.offset_right = -margins.z - 160.0
	boss_bar_container.offset_bottom = margins.y + 224.0
	boss_bar_container.visible = false
	boss_bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.05, 0.13, 0.92)
	style.border_color = Color("d2b45f")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	boss_bar_container.add_theme_stylebox_override("panel", style)
	parent.add_child(boss_bar_container)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	boss_bar_container.add_child(content)
	boss_name_label = Label.new()
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 25)
	content.add_child(boss_name_label)
	boss_progress = ProgressBar.new()
	boss_progress.custom_minimum_size = Vector2(0.0, 24.0)
	boss_progress.show_percentage = false
	boss_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(boss_progress)
	boss_health_label = Label.new()
	boss_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_health_label.add_theme_font_size_override("font_size", 19)
	content.add_child(boss_health_label)


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


func update_status(
	wave: int,
	health: int,
	active_enemies: int = -1,
	total_waves: int = 0
) -> void:
	wave_label.text = (
		"%d / %d" % [wave, total_waves]
		if total_waves > 0 else "DALGA %d" % wave
	)
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
		"OK YAĞMURU\n%d sn" % int(ceil(remaining))
		if remaining > 0.0 else "OK YAĞMURU\nHAZIR"
	)
	ability_button.modulate = Color.WHITE if remaining > 0.0 else Color("fff1a8")


func set_ability_cooldown_duration(duration: float) -> void:
	ability_cooldown_duration = maxf(0.0, duration)


func _toggle_speed() -> void:
	var next_speed: float = 2.0 if is_equal_approx(selected_speed, 1.0) else 1.0
	set_speed(next_speed)
	speed_requested.emit(selected_speed)


func set_speed(speed: float) -> void:
	selected_speed = 2.0 if speed >= 1.5 else 1.0
	if is_instance_valid(speed_button):
		speed_button.text = "%d×" % int(selected_speed)


func show_wave_preview(summary: Dictionary, total: int) -> WavePreviewPanel:
	if is_instance_valid(wave_preview_panel):
		return wave_preview_panel
	wave_preview_layer = CanvasLayer.new()
	wave_preview_layer.layer = 24
	add_child(wave_preview_layer)
	wave_preview_panel = WavePreviewPanelScript.new()
	wave_preview_layer.add_child(wave_preview_panel)
	wave_preview_panel.setup(summary, total)
	wave_preview_panel.ready_pressed.connect(_on_wave_preview_ready)
	return wave_preview_panel


func _on_wave_preview_ready() -> void:
	if not is_instance_valid(wave_preview_panel):
		return
	wave_preview_panel.queue_free()
	wave_preview_panel = null
	if is_instance_valid(wave_preview_layer):
		wave_preview_layer.queue_free()
	wave_preview_layer = null
	wave_preview_ready.emit()


func confirm_wave_preview_for_test() -> void:
	if is_instance_valid(wave_preview_panel):
		wave_preview_panel._confirm_ready()


func show_tutorial(step: int = 0) -> FirstLevelTutorialOverlay:
	if not is_instance_valid(tutorial_overlay):
		tutorial_layer = CanvasLayer.new()
		tutorial_layer.layer = 25
		add_child(tutorial_layer)
		tutorial_overlay = TutorialOverlayScript.new()
		tutorial_layer.add_child(tutorial_overlay)
		tutorial_overlay.setup()
		tutorial_overlay.skip_requested.connect(
			func() -> void: tutorial_skipped.emit()
		)
	tutorial_overlay.show_step(step)
	return tutorial_overlay


func hide_tutorial() -> void:
	if is_instance_valid(tutorial_layer):
		tutorial_layer.queue_free()
	tutorial_layer = null
	tutorial_overlay = null


func show_reward_choices(choices: Array[Dictionary]) -> RewardChoicePanel:
	if is_instance_valid(reward_panel):
		return reward_panel
	reward_layer = CanvasLayer.new()
	reward_layer.layer = 26
	add_child(reward_layer)
	reward_panel = RewardChoicePanelScript.new()
	reward_layer.add_child(reward_panel)
	reward_panel.setup(choices)
	reward_panel.reward_selected.connect(
		func(reward_id: StringName) -> void:
			reward_selected.emit(reward_id)
	)
	return reward_panel


func hide_reward_choices() -> void:
	if is_instance_valid(reward_layer):
		reward_layer.queue_free()
	reward_layer = null
	reward_panel = null


func show_achievement_notification(
	_achievement_id: StringName,
	title: String
) -> void:
	if is_instance_valid(achievement_notification):
		achievement_notification.queue_free()
	achievement_notification = PanelContainer.new()
	achievement_notification.name = "AchievementNotification"
	achievement_notification.set_anchors_preset(Control.PRESET_CENTER_TOP)
	achievement_notification.position = Vector2(-330.0, 260.0)
	achievement_notification.size = Vector2(660.0, 100.0)
	achievement_notification.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.12, 0.14, 0.96)
	style.border_color = Color("ffd667")
	style.set_border_width_all(3)
	style.set_corner_radius_all(24)
	achievement_notification.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "BAŞARIM AÇILDI\n%s" % title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 25)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	achievement_notification.add_child(label)
	interface_layer.add_child(achievement_notification)
	achievement_notification_count += 1
	achievement_notification.modulate.a = 0.0
	achievement_notification_tween = create_tween()
	achievement_notification_tween.tween_property(
		achievement_notification,
		"modulate:a",
		1.0,
		0.18
	)
	achievement_notification_tween.tween_interval(1.8)
	achievement_notification_tween.tween_property(
		achievement_notification,
		"modulate:a",
		0.0,
		0.25
	)
	achievement_notification_tween.tween_callback(
		func() -> void:
			if is_instance_valid(achievement_notification):
				achievement_notification.queue_free()
	)


func register_boss(enemy: Node) -> void:
	if not is_instance_valid(enemy) or enemy in tracked_bosses:
		return
	tracked_bosses.append(enemy)
	_update_boss_bar()


func unregister_boss(enemy: Node) -> void:
	tracked_bosses.erase(enemy)
	_update_boss_bar()


func _update_boss_bar() -> void:
	tracked_bosses = tracked_bosses.filter(
		func(enemy: Node) -> bool:
			return (
				is_instance_valid(enemy)
				and not enemy.is_queued_for_deletion()
				and enemy.get("has_resolved") != true
			)
	)
	if tracked_bosses.is_empty():
		if is_instance_valid(boss_bar_container):
			boss_bar_container.visible = false
		return
	var boss: Node = tracked_bosses[0]
	var health: float = maxf(0.0, float(boss.get("health")))
	var maximum: float = maxf(1.0, float(boss.get("max_health")))
	boss_bar_container.visible = true
	boss_name_label.text = "BOSS — %s" % String(boss.get("display_name"))
	boss_progress.max_value = maximum
	boss_progress.value = health
	boss_health_label.text = "%.0f / %.0f  •  %d%%" % [
		health,
		maximum,
		int(round(health / maximum * 100.0))
	]
	var behavior_description: String = String(boss.get("boss_behavior_description"))
	if not behavior_description.is_empty():
		boss_name_label.text += "\n" + behavior_description


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


func show_game_over(
	wave: int,
	total_gold: int,
	run_summary: Dictionary = {}
) -> CanvasLayer:
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
	last_summary_text = _format_run_summary(run_summary, wave, total_gold)
	result.text = last_summary_text
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
	tower_count: int = 0,
	run_summary: Dictionary = {}
) -> CanvasLayer:
	if is_instance_valid(victory_layer):
		return victory_layer
	last_summary_text = _format_run_summary(run_summary, 0, total_gold)
	victory_layer = _create_action_layer(
		"BÖLÜM TAMAMLANDI\n%s\n%s\n%s" % [
			level_name,
			"★".repeat(clampi(stars, 1, 3)),
			last_summary_text if not run_summary.is_empty()
				else "Kale: %d  Altın: %d  Kule: %d" % [health, total_gold, tower_count]
		],
		[
			["Tekrar Oyna", func() -> void: restart_requested.emit()],
			["Sonraki Bölüm", func() -> void: next_level_requested.emit()],
			["Bölüm Seçimi", func() -> void: _change_scene_unpaused("res://scenes/level_select.tscn")]
		]
	)
	return victory_layer


func _format_run_summary(
	summary: Dictionary,
	fallback_wave: int,
	fallback_gold: int
) -> String:
	if summary.is_empty():
		return "Ulaşılan dalga: %d\nKazanılan toplam altın: %d" % [
			fallback_wave,
			fallback_gold
		]
	var achievements: Array = summary.get("achievements_unlocked", [])
	return (
		"Dalga: %d  •  Kale: %d\nAltın: %d  •  Düşman: %d  •  Boss: %d\n"
		+ "Kule: %d  •  Yükseltme: %d  •  Satış: %d\n"
		+ "Ok Yağmuru: %d  •  Favori: %s\nBaşarım: %s"
	) % [
		int(summary.get("wave", fallback_wave)),
		int(summary.get("base_health", 0)),
		int(summary.get("gold_earned", fallback_gold)),
		int(summary.get("enemies_defeated", 0)),
		int(summary.get("bosses_defeated", 0)),
		int(summary.get("towers_built", 0)),
		int(summary.get("upgrades", 0)),
		int(summary.get("towers_sold", 0)),
		int(summary.get("arrow_rain_uses", 0)),
		String(summary.get("favorite_tower", &"none")),
		", ".join(achievements) if not achievements.is_empty() else "Yok"
	]


func _change_scene_unpaused(scene_path: String) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
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
	if is_instance_valid(wave_preview_layer):
		wave_preview_layer.queue_free()
	wave_preview_layer = null
	wave_preview_panel = null
	hide_tutorial()
	hide_reward_choices()
	tracked_bosses.clear()
	if is_instance_valid(boss_bar_container):
		boss_bar_container.visible = false
	set_speed(1.0)
	if achievement_notification_tween != null and achievement_notification_tween.is_valid():
		achievement_notification_tween.kill()
	if is_instance_valid(achievement_notification):
		achievement_notification.queue_free()
	achievement_notification = null
