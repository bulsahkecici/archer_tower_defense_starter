extends Node2D

const EnemyScript = preload("res://scripts/enemy.gd")
const ShooterScript = preload("res://scripts/shooter.gd")
const BaseScript = preload("res://scripts/base.gd")
const GamePathScript = preload("res://scripts/game_path.gd")
const EconomyScript = preload("res://scripts/economy_manager.gd")
const WaveManagerScript = preload("res://scripts/wave_manager.gd")
const VisualEffectScript = preload("res://scripts/visual_effect.gd")
const UIControllerScript = preload("res://scripts/ui_controller.gd")
const TowerBuildManagerScript = preload("res://scripts/tower_build_manager.gd")
const BossBehaviorScript = preload("res://scripts/boss_behavior.gd")
const RunModifierManagerScript = preload("res://scripts/run_modifier_manager.gd")

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
var ability_cooldown: float = 0.0
const ABILITY_COOLDOWN: float = 25.0
const ABILITY_DAMAGE: float = 20.0
var level_data: LevelData
var total_waves: int = 10
var victory_shown: bool = false
var save_manager: Node
var wave_preview_pending: bool = false
var selected_game_speed: float = 1.0
var tutorial_active: bool = false
var tutorial_step: int = 0
var world_shake_tween: Tween
var damage_number_spawn_count: int = 0
var reward_pending: bool = false
var run_modifier_manager: RunModifierManager
var endless_mode: bool = false
var achievement_manager: Node
var enemies_defeated: int = 0
var bosses_defeated: int = 0
var towers_built_count: int = 0
var upgrades_count: int = 0
var towers_sold_count: int = 0
var arrow_rain_uses: int = 0
var tower_type_build_counts: Dictionary[StringName, int] = {}

var base: DefenseBase
var archer: ShooterUnit
var enemy_path: Path2D
var enemy_paths: Array[Path2D] = []
var projectiles: Node2D
var build_spots: Array[Vector2] = []
var built_spots: Array[bool] = []
var towers: Array[Node2D] = []
var economy: EconomyManager
var wave_manager: WaveManager
var ui_controller: UIController
var tower_build_manager: TowerBuildManager
var selected_build_spot: int:
	get:
		return tower_build_manager.selected_build_spot if is_instance_valid(tower_build_manager) else -1
var tower_selection_panel: TowerSelectionPanel:
	get:
		return tower_build_manager.tower_selection_panel if is_instance_valid(tower_build_manager) else null
var tower_upgrade_panel: TowerUpgradePanel:
	get:
		return tower_build_manager.tower_upgrade_panel if is_instance_valid(tower_build_manager) else null
var game_over_layer: CanvasLayer:
	get:
		return ui_controller.game_over_layer if is_instance_valid(ui_controller) else null
var boss_warning_label: Label:
	get:
		return ui_controller.boss_warning_label if is_instance_valid(ui_controller) else null
var boss_warning_tween: Tween:
	get:
		return ui_controller.boss_warning_tween if is_instance_valid(ui_controller) else null

func _ready() -> void:
	Engine.time_scale = 1.0
	add_to_group("gameplay_root")
	save_manager = get_node("/root/SaveManager")
	achievement_manager = get_node("/root/AchievementManager")
	endless_mode = (
		save_manager.selected_game_mode == &"endless"
		and save_manager.is_endless_unlocked()
	)
	var catalog: Array[LevelData] = LevelData.create_catalog()
	var selected_level: int = (
		catalog.size()
		if endless_mode else clampi(save_manager.last_level, 1, catalog.size())
	)
	level_data = catalog[selected_level - 1]
	total_waves = 0 if endless_mode else level_data.total_waves
	economy = EconomyScript.new()
	add_child(economy)
	economy.gold_changed.connect(_on_gold_changed)
	economy.setup(level_data.starting_gold)
	wave_manager = WaveManagerScript.new()
	add_child(wave_manager)
	wave_manager.configure_level(level_data.id)
	wave_manager.configure_endless(endless_mode)

	_create_world()
	_create_controllers()
	_update_ui()
	if not _begin_tutorial_if_needed():
		_queue_next_wave_preview()
	queue_redraw()


func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _create_world() -> void:
	enemy_path = GamePathScript.new()
	enemy_path.curve = _create_enemy_curve()
	enemy_path.set_theme(level_data.map_theme)
	add_child(enemy_path)
	move_child(enemy_path, 0)
	enemy_paths = [enemy_path]
	if level_data.id == 5:
		var alternate_path: Path2D = GamePathScript.new()
		alternate_path.name = "EnemyPathAlternate"
		alternate_path.curve = _create_curve_from_points(
			level_data.get_alternate_path_points()
		)
		alternate_path.set_theme(level_data.map_theme)
		add_child(alternate_path)
		move_child(alternate_path, 1)
		enemy_paths.append(alternate_path)

	projectiles = Node2D.new()
	projectiles.name = "Projectiles"
	projectiles.z_index = 2000
	projectiles.z_as_relative = false
	projectiles.add_to_group("projectile_container")
	add_child(projectiles)

	base = BaseScript.new()
	add_child(base)
	base.position = Vector2(790.0, 1705.0)
	base.z_index = 1705
	base.max_health = level_data.base_health
	base.health = level_data.base_health

	archer = ShooterScript.new()
	add_child(archer)
	archer.position = Vector2(330.0, 1600.0)
	archer.z_index = 1600
	archer.set_projectile_parent(projectiles)
	archer.setup_archer()

func _create_controllers() -> void:
	ui_controller = UIControllerScript.new()
	add_child(ui_controller)
	ui_controller.setup()
	ui_controller.restart_requested.connect(_restart_game)
	ui_controller.ability_requested.connect(_use_arrow_rain)
	ui_controller.pause_requested.connect(_pause_game)
	ui_controller.resume_requested.connect(_resume_game)
	ui_controller.next_level_requested.connect(_next_level)
	ui_controller.speed_requested.connect(_set_game_speed)
	ui_controller.wave_preview_ready.connect(_begin_previewed_wave)
	ui_controller.tutorial_skipped.connect(_complete_tutorial)
	ui_controller.reward_selected.connect(_on_reward_selected)
	achievement_manager.achievement_unlocked.connect(
		ui_controller.show_achievement_notification
	)
	ui_controller.set_ability_cooldown_duration(ABILITY_COOLDOWN)

	run_modifier_manager = RunModifierManagerScript.new()
	add_child(run_modifier_manager)
	tower_build_manager = TowerBuildManagerScript.new()
	add_child(tower_build_manager)
	tower_build_manager.configure_level(
		level_data.build_spot_positions,
		level_data.build_spot_costs
	)
	tower_build_manager.setup(economy, ui_controller.interface_layer, self, projectiles)
	tower_build_manager.set_run_modifier_manager(run_modifier_manager)
	tower_build_manager.tower_built.connect(_on_tower_built)
	tower_build_manager.tower_upgraded.connect(_on_tower_upgraded)
	tower_build_manager.tower_sold.connect(_on_tower_sold)
	tower_build_manager.selection_opened.connect(_on_tower_selection_opened)
	tower_build_manager.message_requested.connect(ui_controller.set_message)
	build_spots = tower_build_manager.build_spots
	built_spots = tower_build_manager.built_spots
	towers = tower_build_manager.towers

func _create_enemy_curve() -> Curve2D:
	return _create_curve_from_points(level_data.get_path_points())


func _create_curve_from_points(points: Array[Vector2]) -> Curve2D:
	var path_curve := Curve2D.new()
	path_curve.bake_interval = 12.0
	for path_point in points:
		path_curve.add_point(path_point)

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

func _process(delta: float) -> void:
	if ability_cooldown > 0.0:
		ability_cooldown = maxf(0.0, ability_cooldown - delta)
		ui_controller.update_ability_cooldown(ability_cooldown)
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
				if endless_mode:
					achievement_manager.record_event(&"endless_wave", wave)
				elif wave >= total_waves:
					_finish_victory()
					return
				intermission = 3.0
				ui_controller.set_message("Dalga temizlendi!")
				_open_reward_if_due()
		WaveManager.WaveState.COMPLETED:
			if reward_pending:
				return
			intermission -= delta
			if intermission <= 0.0:
				wave_manager.set_waiting()
				_queue_next_wave_preview()

func _start_next_wave() -> void:
	if wave_preview_pending:
		return
	_queue_next_wave_preview()


func _queue_next_wave_preview() -> void:
	if (
		game_over
		or victory_shown
		or tutorial_active
		or wave_preview_pending
		or wave_manager.state != WaveManager.WaveState.WAITING
		or (not endless_mode and wave >= total_waves)
	):
		return
	wave += 1
	wave_preview_pending = true
	tower_build_manager.input_enabled = false
	ui_controller.show_wave_preview(
		wave_manager.get_wave_summary(wave),
		total_waves
	)
	_update_ui()


func _begin_previewed_wave() -> void:
	if (
		not wave_preview_pending
		or game_over
		or victory_shown
		or get_tree().paused
	):
		return
	wave_preview_pending = false
	tower_build_manager.input_enabled = true
	wave_manager.begin_wave(wave)
	spawn_interval = maxf(0.30, 0.78 - float(wave - 1) * 0.018)
	spawn_cooldown = 0.15
	if WaveManager.BOSS_ID in wave_manager.spawn_queue:
		ui_controller.set_message("Dalga %d başladı" % wave)
		_show_boss_warning()
	else:
		ui_controller.set_message("Dalga %d başladı" % wave)
	_update_ui()

func _spawn_enemy(enemy_id: StringName) -> PathEnemy:
	if game_over or wave_manager.state == WaveManager.WaveState.GAME_OVER:
		return null
	var enemy_data: EnemyData = wave_manager.get_enemy_data(enemy_id)
	if enemy_data == null:
		return null

	var enemy: PathEnemy = EnemyScript.new()
	var selected_enemy_path: Path2D = enemy_path
	if enemy_paths.size() > 1 and (wave + active_enemy_count) % 2 == 1:
		selected_enemy_path = enemy_paths[1]
	selected_enemy_path.add_child(enemy)
	enemy.progress = randf_range(0.0, 18.0)
	enemy.h_offset = randf_range(-38.0, 38.0)
	enemy.setup(
		enemy_data,
		wave_manager.get_health_multiplier(wave) * level_data.wave_difficulty_multiplier,
		wave_manager.get_speed_multiplier(wave, enemy_data.is_boss)
			* lerpf(1.0, level_data.wave_difficulty_multiplier, 0.35),
		wave_manager.get_reward_bonus(wave, enemy_data.is_boss)
	)
	enemy.configure_level_mechanic(level_data.id)
	enemy.damage_received.connect(_on_enemy_damage_received)
	enemy.slow_applied.connect(_on_enemy_slow_applied)
	enemy.defeated.connect(
		func(reward: int, world_position: Vector2) -> void:
			ui_controller.unregister_boss(enemy)
			_on_enemy_defeated(reward, world_position, enemy.is_boss)
	)
	enemy.reached_base.connect(
		func(damage: int) -> void:
			ui_controller.unregister_boss(enemy)
			_on_enemy_reached_base(damage)
	)
	if enemy.is_boss:
		var behavior: BossBehavior = BossBehaviorScript.new()
		enemy.add_child(behavior)
		behavior.configure(enemy, self, level_data.id)
		ui_controller.register_boss(enemy)
	active_enemy_count += 1
	return enemy


func _spawn_boss_minions(count: int) -> int:
	if game_over or wave_manager.state == WaveManager.WaveState.GAME_OVER:
		return 0
	var spawned: int = 0
	for _index in range(clampi(count, 0, 8)):
		var minion: PathEnemy = _spawn_enemy(WaveManager.SWARM_ID)
		if is_instance_valid(minion):
			spawned += 1
	return spawned


func _on_enemy_damage_received(
	amount: float,
	world_position: Vector2,
	critical: bool,
	armor_blocked: bool
) -> void:
	if amount <= 0.0:
		return
	var damage_effect := VisualEffectScript.new()
	add_child(damage_effect)
	damage_effect.global_position = world_position
	damage_effect.setup_damage_number(amount, critical, armor_blocked)
	damage_number_spawn_count += 1
	var boss_hit: bool = false
	for boss in ui_controller.tracked_bosses:
		if (
			is_instance_valid(boss)
			and boss.global_position.distance_to(world_position) < 4.0
		):
			boss_hit = true
			break
	if boss_hit:
		var boss_effect := VisualEffectScript.new()
		add_child(boss_effect)
		boss_effect.global_position = world_position
		boss_effect.setup_status_flash(Color("c8a6ff"))


func _on_enemy_slow_applied(world_position: Vector2) -> void:
	var slow_effect := VisualEffectScript.new()
	add_child(slow_effect)
	slow_effect.global_position = world_position
	slow_effect.setup_status_flash(Color("9cecff"))
	achievement_manager.record_event(&"enemy_slowed")

func _on_enemy_defeated(
	reward: int,
	world_position: Vector2,
	was_boss: bool = false
) -> void:
	active_enemy_count = maxi(0, active_enemy_count - 1)
	if not game_over:
		enemies_defeated += 1
		if was_boss:
			bosses_defeated += 1
			achievement_manager.record_event(&"boss_defeated")
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

func _input(event: InputEvent) -> void:
	if game_over or wave_preview_pending:
		return
	if tutorial_active and tutorial_step != 0 and tutorial_step != 2:
		return
	tower_build_manager.handle_input(event)


func _unhandled_input(event: InputEvent) -> void:
	# Compatibility path for direct calls in the existing stage tests. Real
	# viewport events are handled once in _input before passive UI can consume them.
	if not event.is_pressed():
		return
	if game_over or wave_preview_pending:
		return
	tower_build_manager.handle_input(event)

func _find_build_spot_at(input_position: Vector2) -> int:
	return tower_build_manager.find_build_spot_at(input_position)

func _open_tower_selection(index: int) -> void:
	tower_build_manager.open_tower_selection(index)

func _on_tower_selected(tower_type: ShooterUnit.TowerType) -> void:
	tower_build_manager.select_tower(tower_type)

func _on_tower_built(
	built_tower: ShooterUnit,
	tower_name: String,
	world_position: Vector2
) -> void:
	ui_controller.set_message("%s kuruldu!" % tower_name)
	var build_effect := VisualEffectScript.new()
	add_child(build_effect)
	build_effect.position = world_position
	build_effect.setup_build_dust()
	towers_built_count += 1
	var tower_id: StringName = built_tower.tower_data.id
	tower_type_build_counts[tower_id] = int(tower_type_build_counts.get(tower_id, 0)) + 1
	achievement_manager.record_event(&"tower_built")
	if (
		tutorial_active
		and tutorial_step == 1
		and built_tower.tower_type == ShooterUnit.TowerType.ARCHER
	):
		_set_tutorial_step(2)


func _on_tower_selection_opened(_index: int) -> void:
	if tutorial_active and tutorial_step == 0:
		_set_tutorial_step(1)


func _on_tower_upgraded(upgraded_tower: ShooterUnit) -> void:
	upgrades_count += 1
	achievement_manager.record_event(
		&"tower_upgraded",
		1,
		{"level": upgraded_tower.level}
	)
	if tutorial_active and tutorial_step == 2:
		_set_tutorial_step(3)


func _on_tower_sold(world_position: Vector2, _refund: int) -> void:
	towers_sold_count += 1
	var sell_effect := VisualEffectScript.new()
	add_child(sell_effect)
	sell_effect.global_position = world_position
	sell_effect.setup_sell_dust()


func _open_reward_if_due() -> bool:
	if (
		not run_modifier_manager.is_reward_wave(wave, endless_mode)
		or game_over
		or victory_shown
		or reward_pending
	):
		return false
	reward_pending = true
	tower_build_manager.input_enabled = false
	ui_controller.show_reward_choices(
		run_modifier_manager.get_reward_choices(wave)
	)
	return true


func _on_reward_selected(reward_id: StringName) -> void:
	if not reward_pending:
		return
	if not run_modifier_manager.apply_reward(reward_id, economy, base, towers):
		return
	reward_pending = false
	ui_controller.hide_reward_choices()
	tower_build_manager.input_enabled = true
	tower_build_manager.synergy_manager.recompute(towers)
	intermission = minf(intermission, 0.15)
	_update_ui()

func _spawn_floating_gold(world_position: Vector2, reward: int) -> void:
	var gold_effect := VisualEffectScript.new()
	add_child(gold_effect)
	gold_effect.global_position = world_position
	gold_effect.setup_floating_gold(reward)

func _on_tower_panel_closed() -> void:
	tower_build_manager._on_panel_closed()

func _close_tower_panel() -> void:
	tower_build_manager.close_panel()

func _on_gold_changed(current_gold: int) -> void:
	if is_instance_valid(ui_controller):
		ui_controller.update_gold(current_gold)

func _play_base_hud_feedback() -> void:
	ui_controller.play_base_feedback()

func _show_boss_warning() -> void:
	ui_controller.show_boss_warning(wave)


func _use_arrow_rain() -> bool:
	if game_over or ability_cooldown > 0.0:
		return false
	var targets: Array[Node] = get_tree().get_nodes_in_group("enemies")
	if targets.is_empty():
		return false
	var hit_count: int = 0
	for node in targets:
		if hit_count >= 12:
			break
		if not is_instance_valid(node) or node.is_queued_for_deletion() or node.get("has_resolved") == true:
			continue
		var multiplier: float = 0.5 if node.get("is_boss") == true else 1.0
		node.take_damage(ABILITY_DAMAGE * multiplier)
		hit_count += 1
	if hit_count == 0:
		return false
	arrow_rain_uses += 1
	achievement_manager.record_event(&"arrow_rain_hit", hit_count)
	ability_cooldown = _get_ability_cooldown_duration()
	ui_controller.update_ability_cooldown(ability_cooldown)
	ui_controller.set_message("Ok Yağmuru!")
	if tutorial_active and tutorial_step == 3:
		_complete_tutorial()
	return true


func _get_ability_cooldown_duration() -> float:
	return maxf(
		5.0,
		ABILITY_COOLDOWN - run_modifier_manager.arrow_rain_cooldown_reduction
	)


func _on_bomb_explosion(world_position: Vector2, hit_count: int) -> void:
	var explosion_effect := VisualEffectScript.new()
	add_child(explosion_effect)
	explosion_effect.global_position = world_position
	explosion_effect.setup_status_flash(Color("f2a15d"))
	achievement_manager.record_event(&"bomb_multi_hit", hit_count)
	if (
		hit_count <= 0
		or not bool(save_manager.screen_shake_enabled)
		or game_over
	):
		return
	if world_shake_tween != null and world_shake_tween.is_valid():
		world_shake_tween.kill()
	position = Vector2.ZERO
	world_shake_tween = create_tween()
	world_shake_tween.tween_property(self, "position", Vector2(4.0, -3.0), 0.035)
	world_shake_tween.tween_property(self, "position", Vector2(-3.0, 2.0), 0.045)
	world_shake_tween.tween_property(self, "position", Vector2.ZERO, 0.055)

func _finish_game() -> void:
	if game_over:
		return
	game_over = true
	game_over_trigger_count += 1
	wave_manager.set_game_over()
	_reset_game_speed()
	ui_controller.set_message("Savunma Düştü")
	_close_tower_panel()
	_stop_combat()
	if endless_mode:
		save_manager.update_endless_high_wave(wave)
	ui_controller.show_game_over(wave, economy.total_gold_earned)


func _finish_victory() -> void:
	if victory_shown or game_over:
		return
	victory_shown = true
	_reset_game_speed()
	_stop_combat()
	var health_percent: int = int(round(
		float(base.health) / float(maxi(1, base.max_health)) * 100.0
	))
	var stars: int = 1
	if health_percent >= level_data.star_thresholds[2]:
		stars = 3
	elif health_percent >= level_data.star_thresholds[1]:
		stars = 2
	save_manager.complete_level(level_data.id, stars)
	achievement_manager.record_event(
		&"level_completed",
		1,
		{
			"level_id": level_data.id,
			"perfect": base.health == base.max_health
		}
	)
	ui_controller.show_victory(
		level_data.display_name,
		stars,
		base.health,
		economy.total_gold_earned,
		towers.size()
	)


func _pause_game() -> void:
	if game_over or victory_shown or get_tree().paused:
		return
	Engine.time_scale = 1.0
	ui_controller.show_pause()
	get_tree().paused = true


func _resume_game() -> void:
	get_tree().paused = false
	ui_controller.hide_pause()
	Engine.time_scale = selected_game_speed

func _restart_game() -> void:
	_prepare_restart()
	get_tree().reload_current_scene()


func _next_level() -> void:
	get_tree().paused = false
	_reset_game_speed()
	if level_data.id >= LevelData.create_catalog().size():
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
		return
	save_manager.last_level = level_data.id + 1
	save_manager.save_data()
	get_tree().reload_current_scene()

func _prepare_restart() -> void:
	_reset_game_speed()
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
	tower_build_manager.reset()
	ui_controller.reset()
	active_enemy_count = 0
	game_over = false
	victory_shown = false
	get_tree().paused = false
	wave = 0
	wave_preview_pending = false
	reward_pending = false
	tutorial_active = false
	tutorial_step = 0
	ability_cooldown = 0.0
	ui_controller.update_ability_cooldown(0.0)
	wave_manager.reset()
	run_modifier_manager.reset()
	enemies_defeated = 0
	bosses_defeated = 0
	towers_built_count = 0
	upgrades_count = 0
	towers_sold_count = 0
	arrow_rain_uses = 0
	tower_type_build_counts.clear()
	economy.setup(level_data.starting_gold)
	base.max_health = level_data.base_health
	base.reset()
	queue_redraw()


func get_run_summary() -> Dictionary:
	var favorite_tower: StringName = &"none"
	var favorite_count: int = 0
	for tower_id in tower_type_build_counts:
		var count: int = tower_type_build_counts[tower_id]
		if count > favorite_count:
			favorite_tower = tower_id
			favorite_count = count
	return {
		"wave": wave,
		"enemies_defeated": enemies_defeated,
		"bosses_defeated": bosses_defeated,
		"gold_earned": economy.total_gold_earned,
		"towers_built": towers_built_count,
		"upgrades": upgrades_count,
		"towers_sold": towers_sold_count,
		"arrow_rain_uses": arrow_rain_uses,
		"favorite_tower": favorite_tower,
		"endless": endless_mode
	}

func _stop_combat() -> void:
	tower_build_manager.input_enabled = false
	tower_build_manager.clear_range_indicator()
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
	ui_controller.update_gold(economy.gold, false)
	ui_controller.update_status(wave, base.health, active_enemy_count, total_waves)


func _set_game_speed(speed: float) -> void:
	if game_over or victory_shown or get_tree().paused:
		return
	selected_game_speed = 2.0 if speed >= 1.5 else 1.0
	Engine.time_scale = selected_game_speed
	ui_controller.set_speed(selected_game_speed)


func _reset_game_speed() -> void:
	selected_game_speed = 1.0
	Engine.time_scale = 1.0
	if is_instance_valid(ui_controller):
		ui_controller.set_speed(1.0)


func _begin_tutorial_if_needed() -> bool:
	if level_data.id != 1 or bool(save_manager.tutorial_completed):
		return false
	tutorial_active = true
	tutorial_step = 0
	ui_controller.show_tutorial(tutorial_step)
	return true


func _set_tutorial_step(step: int) -> void:
	if not tutorial_active:
		return
	tutorial_step = clampi(step, 0, 3)
	ui_controller.show_tutorial(tutorial_step)


func _complete_tutorial() -> void:
	if not tutorial_active and bool(save_manager.tutorial_completed):
		return
	tutorial_active = false
	tutorial_step = 0
	ui_controller.hide_tutorial()
	save_manager.complete_tutorial()
	if wave == 0 and wave_manager.state == WaveManager.WaveState.WAITING:
		_queue_next_wave_preview()


func confirm_wave_preview_for_test() -> void:
	ui_controller.confirm_wave_preview_for_test()

func _draw() -> void:
	var visible_size: Vector2 = get_viewport_rect().size
	var background_size := Vector2(maxf(WORLD_SIZE.x, visible_size.x), maxf(WORLD_SIZE.y, visible_size.y))
	draw_rect(Rect2(Vector2.ZERO, background_size), level_data.get_ground_color())
	draw_rect(Rect2(Vector2.ZERO, Vector2(background_size.x, 205.0)), Color("237b63"))
	for x in range(45, int(background_size.x), 135):
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
