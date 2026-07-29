extends Node2D

const EnemyScript = preload("res://scripts/enemy.gd")
const ShooterScript = preload("res://scripts/shooter.gd")
const BaseScript = preload("res://scripts/base.gd")
const GamePathScript = preload("res://scripts/game_path.gd")
const EconomyScript = preload("res://scripts/economy_manager.gd")
const TowerSelectionPanelScript = preload("res://scripts/tower_selection_panel.gd")
const WaveManagerScript = preload("res://scripts/wave_manager.gd")
const VisualEffectScript = preload("res://scripts/visual_effect.gd")

const WORLD_SIZE := Vector2(1080.0, 1920.0)
const STARTING_GOLD := 20
const BUILD_SPOT_COSTS: Array[int] = [15, 20, 25, 30]

var wave: int = 0
var spawn_cooldown: float = 0.0
var spawn_interval: float = 0.8
var intermission: float = 3.0
var game_over: bool = false
var active_enemy_count: int = 0
var game_over_trigger_count: int = 0
var hovered_build_spot: int = -1
var pressed_build_spot: int = -1
var build_spot_press_time: float = 0.0
var boss_warning_wave: int = -1

var base: DefenseBase
var archer: ShooterUnit
var enemy_path: Path2D
var build_spots: Array[Vector2] = [
	Vector2(205.0, 1370.0),
	Vector2(875.0, 1240.0),
	Vector2(205.0, 815.0),
	Vector2(860.0, 620.0)
]
var built_spots: Array[bool] = []
var towers: Array[Node2D] = []
var economy: EconomyManager
var wave_manager: WaveManager
var selected_build_spot: int = -1
var tower_selection_panel: TowerSelectionPanel

var gold_label: Label
var wave_label: Label
var base_label: Label
var message_label: Label
var help_label: Label
var game_over_layer: CanvasLayer
var boss_warning_label: Label
var gold_tween: Tween
var base_tween: Tween
var boss_warning_tween: Tween

func _ready() -> void:
	for _spot in build_spots:
		built_spots.append(false)

	economy = EconomyScript.new()
	add_child(economy)
	economy.gold_changed.connect(_on_gold_changed)
	economy.setup(STARTING_GOLD)
	wave_manager = WaveManagerScript.new()
	add_child(wave_manager)

	_create_world()
	_create_ui()
	_update_ui()
	_start_next_wave()
	queue_redraw()

func _create_world() -> void:
	enemy_path = GamePathScript.new()
	enemy_path.curve = _create_enemy_curve()
	add_child(enemy_path)
	move_child(enemy_path, 0)

	base = BaseScript.new()
	add_child(base)
	base.position = Vector2(790.0, 1705.0)
	base.z_index = 1705

	archer = ShooterScript.new()
	add_child(archer)
	archer.position = Vector2(330.0, 1600.0)
	archer.z_index = 1600
	archer.setup_archer()

func _create_enemy_curve() -> Curve2D:
	var path_curve := Curve2D.new()
	path_curve.bake_interval = 12.0
	path_curve.add_point(Vector2(535.0, -80.0))
	path_curve.add_point(Vector2(470.0, 260.0))
	path_curve.add_point(Vector2(650.0, 540.0))
	path_curve.add_point(Vector2(440.0, 850.0))
	path_curve.add_point(Vector2(570.0, 1160.0))
	path_curve.add_point(Vector2(710.0, 1450.0))
	path_curve.add_point(Vector2(790.0, 1695.0))

	for point_index in range(path_curve.point_count):
		if point_index > 0:
			var previous: Vector2 = path_curve.get_point_position(point_index - 1)
			var current: Vector2 = path_curve.get_point_position(point_index)
			path_curve.set_point_in(point_index, (previous - current) * 0.28)
		if point_index < path_curve.point_count - 1:
			var following: Vector2 = path_curve.get_point_position(point_index + 1)
			var current: Vector2 = path_curve.get_point_position(point_index)
			path_curve.set_point_out(point_index, (following - current) * 0.28)

	return path_curve

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Interface"
	canvas.layer = 10
	add_child(canvas)

	var safe_ui := Control.new()
	safe_ui.name = "SafeUI"
	safe_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(safe_ui)

	var top_margin := MarginContainer.new()
	top_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_margin.offset_left = 28.0
	top_margin.offset_top = 28.0
	top_margin.offset_right = -28.0
	top_margin.offset_bottom = 124.0
	safe_ui.add_child(top_margin)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	top_margin.add_child(top_row)
	gold_label = _create_hud_pill(top_row, Color("d59a32"))
	wave_label = _create_hud_pill(top_row, Color("487ca8"))
	base_label = _create_hud_pill(top_row, Color("b34f54"))

	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-370.0, 144.0)
	message_label.size = Vector2(740.0, 58.0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 30)
	message_label.modulate = Color("ffe08a")
	safe_ui.add_child(message_label)

	boss_warning_label = Label.new()
	boss_warning_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_warning_label.position = Vector2(-300.0, 220.0)
	boss_warning_label.size = Vector2(600.0, 90.0)
	boss_warning_label.text = "◆  BOSS YAKLAŞIYOR  ◆"
	boss_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_warning_label.add_theme_font_size_override("font_size", 40)
	boss_warning_label.add_theme_color_override("font_color", Color("ffd785"))
	boss_warning_label.add_theme_color_override("font_outline_color", Color("492536"))
	boss_warning_label.add_theme_constant_override("outline_size", 8)
	boss_warning_label.visible = false
	safe_ui.add_child(boss_warning_label)

	help_label = Label.new()
	help_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	help_label.position = Vector2(-440.0, -76.0)
	help_label.size = Vector2(880.0, 50.0)
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.text = "Boş daireye dokun: okçu kulesi kur"
	help_label.add_theme_font_size_override("font_size", 25)
	help_label.modulate = Color(1.0, 1.0, 1.0, 0.88)
	safe_ui.add_child(help_label)

func _create_hud_pill(parent: Control, accent: Color) -> Label:
	var panel := PanelContainer.new()
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
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color("f8f4df"))
	panel.add_child(label)
	return label

func _process(delta: float) -> void:
	if build_spot_press_time > 0.0:
		build_spot_press_time -= delta
		if build_spot_press_time <= 0.0:
			pressed_build_spot = -1
			queue_redraw()
	if game_over:
		return

	match wave_manager.state:
		WaveManager.WaveState.SPAWNING:
			spawn_cooldown -= delta
			if spawn_cooldown <= 0.0:
				var enemy_id: StringName = wave_manager.take_next_spawn()
				if not enemy_id.is_empty():
					_spawn_enemy(enemy_id)
				spawn_cooldown = spawn_interval
		WaveManager.WaveState.ACTIVE:
			if active_enemy_count == 0 and wave_manager.mark_completed():
				intermission = 3.0
				message_label.text = "Dalga temizlendi!"
		WaveManager.WaveState.COMPLETED:
			intermission -= delta
			if intermission <= 0.0:
				wave_manager.set_waiting()
				_start_next_wave()

func _start_next_wave() -> void:
	if game_over or wave_manager.state != WaveManager.WaveState.WAITING:
		return
	wave += 1
	wave_manager.begin_wave(wave)
	spawn_interval = maxf(0.30, 0.78 - float(wave - 1) * 0.018)
	spawn_cooldown = 0.15
	if WaveManager.BOSS_ID in wave_manager.spawn_queue:
		message_label.text = "Dalga %d başladı" % wave
		_show_boss_warning()
	else:
		message_label.text = "Dalga %d başladı" % wave
	_update_ui()

func _spawn_enemy(enemy_id: StringName) -> PathEnemy:
	if game_over or wave_manager.state == WaveManager.WaveState.GAME_OVER:
		return null
	var enemy_data: EnemyData = wave_manager.get_enemy_data(enemy_id)
	if enemy_data == null:
		return null

	var enemy: PathEnemy = EnemyScript.new()
	enemy_path.add_child(enemy)
	enemy.progress = randf_range(0.0, 18.0)
	enemy.h_offset = randf_range(-38.0, 38.0)
	enemy.setup(
		enemy_data,
		wave_manager.get_health_multiplier(wave),
		wave_manager.get_speed_multiplier(wave, enemy_data.is_boss),
		wave_manager.get_reward_bonus(wave, enemy_data.is_boss)
	)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.reached_base.connect(_on_enemy_reached_base)
	active_enemy_count += 1
	return enemy

func _on_enemy_defeated(reward: int, world_position: Vector2) -> void:
	active_enemy_count = maxi(0, active_enemy_count - 1)
	if not game_over:
		economy.add_gold(reward)
		_spawn_floating_gold(world_position, reward)

func _on_enemy_reached_base(damage: int) -> void:
	active_enemy_count = maxi(0, active_enemy_count - 1)
	if game_over:
		return
	base.take_damage(damage)
	_update_ui()
	_play_base_hud_feedback()
	if base.health <= 0:
		_finish_game()

func _unhandled_input(event: InputEvent) -> void:
	if game_over or is_instance_valid(tower_selection_panel):
		return

	if event is InputEventMouseMotion:
		hovered_build_spot = _find_build_spot_at(event.position)
		queue_redraw()
		return

	var pressed: bool = false
	var input_position: Vector2 = Vector2.ZERO

	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		input_position = event.position
	elif event is InputEventScreenTouch:
		pressed = event.pressed
		input_position = event.position

	if not pressed:
		return

	for index in build_spots.size():
		if built_spots[index]:
			continue
		if input_position.distance_to(build_spots[index]) <= 68.0:
			pressed_build_spot = index
			build_spot_press_time = 0.14
			queue_redraw()
			_open_tower_selection(index)
			break

func _find_build_spot_at(input_position: Vector2) -> int:
	for index in build_spots.size():
		if not built_spots[index] and input_position.distance_to(build_spots[index]) <= 68.0:
			return index
	return -1

func _open_tower_selection(index: int) -> void:
	if index < 0 or index >= build_spots.size() or built_spots[index]:
		return
	selected_build_spot = index
	tower_selection_panel = TowerSelectionPanelScript.new()
	var canvas := get_node("Interface") as CanvasLayer
	canvas.add_child(tower_selection_panel)
	tower_selection_panel.setup(BUILD_SPOT_COSTS[index], economy)
	tower_selection_panel.tower_selected.connect(_on_tower_selected)
	tower_selection_panel.closed.connect(_on_tower_panel_closed)
	message_label.text = "Kule türünü seç"

func _on_tower_selected(tower_type: ShooterUnit.TowerType) -> void:
	if not is_instance_valid(tower_selection_panel):
		return
	if selected_build_spot < 0 or selected_build_spot >= build_spots.size():
		_close_tower_panel()
		return

	var cost: int = tower_selection_panel.get_tower_cost(tower_type)
	if not economy.spend_gold(cost):
		message_label.text = "Yetersiz altın: %d gerekli" % cost
		return

	var tower: ShooterUnit = ShooterScript.new()
	add_child(tower)
	tower.position = build_spots[selected_build_spot]
	tower.z_index = clampi(int(tower.position.y), 0, 1900)
	tower.setup_tower(tower_type, 1)
	tower.play_build_animation()
	towers.append(tower)
	built_spots[selected_build_spot] = true

	var tower_name: String = (
		"Arbalet Kulesi"
		if tower_type == ShooterUnit.TowerType.CROSSBOW
		else "Okçu Kulesi"
	)
	message_label.text = "%s kuruldu!" % tower_name
	var build_effect := VisualEffectScript.new()
	add_child(build_effect)
	build_effect.position = build_spots[selected_build_spot]
	build_effect.setup_build_dust()
	_close_tower_panel()
	queue_redraw()

func _spawn_floating_gold(world_position: Vector2, reward: int) -> void:
	var gold_effect := VisualEffectScript.new()
	add_child(gold_effect)
	gold_effect.global_position = world_position
	gold_effect.setup_floating_gold(reward)

func _on_tower_panel_closed() -> void:
	tower_selection_panel = null
	selected_build_spot = -1

func _close_tower_panel() -> void:
	if is_instance_valid(tower_selection_panel):
		tower_selection_panel.queue_free()
	tower_selection_panel = null
	selected_build_spot = -1

func _on_gold_changed(current_gold: int) -> void:
	if is_instance_valid(gold_label):
		gold_label.text = "●  %d" % current_gold
		if gold_tween != null and gold_tween.is_valid():
			gold_tween.kill()
		gold_label.scale = Vector2.ONE
		gold_label.pivot_offset = gold_label.size * 0.5
		gold_tween = create_tween()
		gold_tween.tween_property(gold_label, "scale", Vector2(1.10, 1.10), 0.07)
		gold_tween.tween_property(gold_label, "scale", Vector2.ONE, 0.12)
	queue_redraw()

func _play_base_hud_feedback() -> void:
	if base_tween != null and base_tween.is_valid():
		base_tween.kill()
	base_label.modulate = Color(1.0, 0.48, 0.48)
	base_tween = create_tween()
	base_tween.tween_property(base_label, "modulate", Color.WHITE, 0.24)

func _show_boss_warning() -> void:
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

func _finish_game() -> void:
	if game_over:
		return
	game_over = true
	game_over_trigger_count += 1
	wave_manager.set_game_over()
	message_label.text = "Savunma Düştü"
	_close_tower_panel()
	_stop_combat()

	game_over_layer = CanvasLayer.new()
	game_over_layer.layer = 30
	add_child(game_over_layer)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.03, 0.05, 0.82)
	game_over_layer.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 36.0
	center.offset_top = 80.0
	center.offset_right = -36.0
	center.offset_bottom = -80.0
	game_over_layer.add_child(center)

	var result_panel := PanelContainer.new()
	result_panel.custom_minimum_size = Vector2(760.0, 590.0)
	var result_style := StyleBoxFlat.new()
	result_style.bg_color = Color("15353b")
	result_style.border_color = Color("c8a85b")
	result_style.set_border_width_all(5)
	result_style.set_corner_radius_all(34)
	result_style.content_margin_left = 70.0
	result_style.content_margin_right = 70.0
	result_style.content_margin_top = 58.0
	result_style.content_margin_bottom = 58.0
	result_panel.add_theme_stylebox_override("panel", result_style)
	center.add_child(result_panel)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 34)
	result_panel.add_child(content)

	var title := Label.new()
	title.custom_minimum_size = Vector2(620.0, 100.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "SAVUNMA DÜŞTÜ"
	title.add_theme_font_size_override("font_size", 62)
	title.add_theme_color_override("font_color", Color("ffd88b"))
	content.add_child(title)

	var result := Label.new()
	result.custom_minimum_size = Vector2(620.0, 150.0)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.text = (
		"Ulaşılan dalga: %d\nKazanılan toplam altın: %d"
		% [wave, economy.total_gold_earned]
	)
	result.add_theme_font_size_override("font_size", 36)
	content.add_child(result)

	var restart_button := Button.new()
	restart_button.custom_minimum_size = Vector2(440.0, 110.0)
	restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_button.text = "Yeniden Başlat"
	restart_button.add_theme_font_size_override("font_size", 32)
	restart_button.pressed.connect(_restart_game)
	content.add_child(restart_button)

	result_panel.pivot_offset = result_panel.size * 0.5
	result_panel.scale = Vector2(0.86, 0.86)
	result_panel.modulate.a = 0.0
	var panel_tween := create_tween()
	panel_tween.set_parallel(true)
	panel_tween.tween_property(result_panel, "scale", Vector2.ONE, 0.24)
	panel_tween.tween_property(result_panel, "modulate:a", 1.0, 0.20)

func _restart_game() -> void:
	_prepare_restart()
	get_tree().reload_current_scene()

func _prepare_restart() -> void:
	_close_tower_panel()
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node):
			node.queue_free()
	for node in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(node):
			node.queue_free()
	for node in get_tree().get_nodes_in_group("visual_effects"):
		if is_instance_valid(node):
			node.queue_free()
	for tower in towers:
		if is_instance_valid(tower):
			tower.queue_free()
	towers.clear()
	built_spots.fill(false)
	boss_warning_wave = -1
	if is_instance_valid(boss_warning_label):
		boss_warning_label.visible = false
	active_enemy_count = 0
	game_over = false
	wave = 0
	wave_manager.reset()
	economy.setup(STARTING_GOLD)
	base.reset()
	queue_redraw()

func _stop_combat() -> void:
	archer.stop_combat()
	for tower in towers:
		if is_instance_valid(tower):
			tower.stop_combat()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.set_process(false)
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(projectile):
			projectile.queue_free()

func _update_ui() -> void:
	gold_label.text = "●  %d" % economy.gold
	wave_label.text = "DALGA  %d" % wave
	base_label.text = "◆  %d" % base.health
	help_label.text = "Kule kurmak için işaretli alanlardan birine dokun"

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("2e9c69"))
	draw_rect(Rect2(Vector2.ZERO, Vector2(1080.0, 205.0)), Color("237b63"))
	for x in range(45, 1080, 135):
		for y in range(245, 1880, 170):
			var pattern_index: int = int(x / 135) + int(y / 170)
			var offset: float = 18.0 if pattern_index % 2 == 0 else -12.0
			draw_circle(Vector2(float(x) + offset, float(y)), 17.0, Color(0.12, 0.48, 0.30, 0.18))
			draw_line(
				Vector2(float(x) - 7.0 + offset, float(y) + 8.0),
				Vector2(float(x) + offset, float(y) - 8.0),
				Color(0.64, 0.90, 0.55, 0.20),
				3.0
			)
	_draw_environment()

	# Build spots
	for index in build_spots.size():
		if built_spots[index]:
			continue
		var spot := build_spots[index]
		var affordable: bool = economy.can_afford(BUILD_SPOT_COSTS[index])
		var emphasis: float = 1.12 if index == hovered_build_spot else 1.0
		if index == pressed_build_spot:
			emphasis = 0.92
		var spot_color: Color = Color("fff1bd") if affordable else Color(0.70, 0.73, 0.70, 0.62)
		draw_colored_polygon(PackedVector2Array([
			spot + Vector2(0.0, -58.0) * emphasis,
			spot + Vector2(70.0, 0.0) * emphasis,
			spot + Vector2(0.0, 48.0) * emphasis,
			spot + Vector2(-70.0, 0.0) * emphasis
		]), Color(0.18, 0.25, 0.25, 0.78))
		draw_circle(spot + Vector2(0.0, -5.0), 46.0 * emphasis, Color(0.26, 0.34, 0.33, 0.95))
		for segment in range(12):
			var start_angle: float = float(segment) * TAU / 12.0
			var end_angle: float = start_angle + TAU / 24.0
			draw_arc(spot, 59.0 * emphasis, start_angle, end_angle, 4, spot_color, 6.0)
		draw_circle(spot + Vector2(-25.0, -1.0), 11.0, Color("d89b35") if affordable else Color("858b82"))
		draw_circle(spot + Vector2(-25.0, -1.0), 7.0, Color("ffd765") if affordable else Color("a8ada5"))
		var cost_text: String = "%d" % BUILD_SPOT_COSTS[index]
		draw_string(
			ThemeDB.fallback_font,
			spot + Vector2(-8.0, 10.0),
			cost_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			48.0,
			24,
			spot_color
		)

func _draw_environment() -> void:
	var tree_positions: Array[Vector2] = [
		Vector2(90.0, 270.0), Vector2(940.0, 250.0), Vector2(110.0, 610.0),
		Vector2(960.0, 860.0), Vector2(90.0, 1190.0), Vector2(980.0, 1320.0),
		Vector2(120.0, 1690.0), Vector2(965.0, 1730.0)
	]
	for tree_position in tree_positions:
		draw_circle(tree_position + Vector2(8.0, 18.0), 34.0, Color(0.05, 0.20, 0.17, 0.22))
		draw_rect(Rect2(tree_position + Vector2(-8.0, 10.0), Vector2(16.0, 48.0)), Color("76522f"))
		draw_circle(tree_position + Vector2(0.0, -12.0), 36.0, Color("176a51"))
		draw_circle(tree_position + Vector2(-22.0, 2.0), 27.0, Color("23815b"))
		draw_circle(tree_position + Vector2(22.0, 4.0), 25.0, Color("2d8c60"))

	var rock_positions: Array[Vector2] = [
		Vector2(280.0, 260.0), Vector2(930.0, 510.0), Vector2(110.0, 950.0),
		Vector2(900.0, 1180.0), Vector2(210.0, 1510.0)
	]
	for rock_position in rock_positions:
		draw_colored_polygon(PackedVector2Array([
			rock_position + Vector2(-22.0, 16.0),
			rock_position + Vector2(-12.0, -15.0),
			rock_position + Vector2(15.0, -21.0),
			rock_position + Vector2(27.0, 12.0)
		]), Color("78948a"))
