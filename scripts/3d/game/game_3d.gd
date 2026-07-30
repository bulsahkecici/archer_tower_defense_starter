extends Node3D
class_name Game3D

const VERTICAL_SLICE_WAVES: int = 1
const SPAWN_INTERVAL: float = 1.05
const ABILITY_COOLDOWN: float = 25.0

@export var auto_start_wave: bool = true

var level_data: LevelData
var wave_manager: WaveManager
var economy: EconomyManager
var castle: CastleTarget3D
var game_camera: Camera3D
var enemy_route: Path3D
var map: GreenValleyMap3D
var placement: TowerPlacement3D
var ui_controller: UIController
var tower_palette: TowerPalette3D
var tower_container: Node3D
var projectile_container: Node3D
var effect_container: Node3D
var enemies: Array[Enemy3D] = []
var towers: Array[ArcherTower3D] = []
var wave: int = 0
var active_enemies: int = 0
var spawn_remaining: float = 0.0
var wave_started: bool = false
var game_over: bool = false
var victory_shown: bool = false
var ability_cooldown_remaining: float = 0.0
var enemies_defeated: int = 0
var towers_built: int = 0
var arrow_rain_uses: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	level_data = LevelData.create_catalog()[0]
	_build_world()
	_build_gameplay()
	_build_ui()
	_refresh_hud(false)
	if auto_start_wave:
		start_vertical_slice_wave()


func _process(delta: float) -> void:
	if game_over or victory_shown:
		return
	if ability_cooldown_remaining > 0.0:
		ability_cooldown_remaining = maxf(0.0, ability_cooldown_remaining - delta)
		ui_controller.update_ability_cooldown(ability_cooldown_remaining)
	_process_spawning(delta)
	_check_wave_completion()


func _unhandled_input(event: InputEvent) -> void:
	if game_over or victory_shown or placement.selected_data == null:
		return
	if event is InputEventMouseMotion:
		placement.update_ghost_from_screen(event.position)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			placement.confirm_from_screen(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			placement.cancel()
	elif event is InputEventScreenTouch and event.pressed:
		placement.confirm_from_screen(event.position)


func _build_world() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("9fc7c0")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d9e4cf")
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "DirectionalLight3D"
	sunlight.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	sunlight.light_color = Color("fff0c5")
	sunlight.light_energy = 1.15
	sunlight.shadow_enabled = true
	add_child(sunlight)

	var camera_rig := Node3D.new()
	camera_rig.name = "FixedCameraRig"
	add_child(camera_rig)
	game_camera = Camera3D.new()
	game_camera.name = "Camera3D"
	game_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	game_camera.size = 66.0
	game_camera.near = 0.1
	game_camera.far = 160.0
	game_camera.position = Vector3(25.0, 34.0, 31.0)
	game_camera.current = true
	camera_rig.add_child(game_camera)
	game_camera.look_at(Vector3(0.0, 0.0, -0.5), Vector3.UP)


func _build_gameplay() -> void:
	enemy_route = Path3D.new()
	enemy_route.name = "EnemyRoute"
	add_child(enemy_route)

	tower_container = Node3D.new()
	tower_container.name = "TowerContainer"
	add_child(tower_container)
	projectile_container = Node3D.new()
	projectile_container.name = "ProjectileContainer"
	add_child(projectile_container)
	effect_container = Node3D.new()
	effect_container.name = "EffectContainer"
	add_child(effect_container)

	map = GreenValleyMap3D.new()
	map.name = "GreenValleyFortressApproach"
	add_child(map)
	var pads: Array[BuildPad3D] = map.setup(enemy_route, level_data.build_spot_costs)

	castle = CastleTarget3D.new()
	castle.name = "CastleTarget"
	castle.max_health = level_data.base_health
	castle.position = map.castle_marker.position + Vector3(0.0, 0.0, 3.5)
	add_child(castle)
	castle.health_changed.connect(_on_castle_health_changed)
	castle.defeated.connect(_on_castle_defeated)

	wave_manager = WaveManager.new()
	wave_manager.name = "WaveManager"
	add_child(wave_manager)
	wave_manager.configure_level(level_data.id)
	wave_manager.configure_endless(false)

	economy = EconomyManager.new()
	economy.name = "EconomyManager"
	add_child(economy)
	economy.gold_changed.connect(_on_gold_changed)
	economy.setup(level_data.starting_gold)

	placement = TowerPlacement3D.new()
	placement.name = "TowerPlacement3D"
	add_child(placement)
	placement.setup(game_camera, pads, economy, tower_container, projectile_container)
	placement.tower_placed.connect(_on_tower_placed)
	placement.placement_rejected.connect(_on_placement_rejected)


func _build_ui() -> void:
	ui_controller = UIController.new()
	ui_controller.name = "UIController"
	add_child(ui_controller)
	ui_controller.setup()
	ui_controller.help_label.visible = false
	ui_controller.set_ability_cooldown_duration(ABILITY_COOLDOWN)
	ui_controller.restart_requested.connect(_restart_scene)
	ui_controller.next_level_requested.connect(_return_to_main_menu)
	ui_controller.pause_requested.connect(_pause_game)
	ui_controller.resume_requested.connect(_resume_game)
	ui_controller.speed_requested.connect(_set_game_speed)
	ui_controller.ability_requested.connect(_use_arrow_rain)

	tower_palette = TowerPalette3D.new()
	ui_controller.interface_layer.add_child(tower_palette)
	tower_palette.setup(level_data.build_spot_costs[0])
	tower_palette.archer_selected.connect(_toggle_archer_selection)
	tower_palette.cancel_requested.connect(placement.cancel)
	placement.selection_changed.connect(_on_placement_selection_changed)


func start_vertical_slice_wave() -> bool:
	if wave_started or game_over or victory_shown:
		return false
	wave = 1
	wave_started = true
	spawn_remaining = 0.0
	wave_manager.begin_wave(wave)
	ui_controller.set_message("YEŞİL VADİ SAVUNMASI BAŞLADI")
	_refresh_hud(false)
	return true


func _process_spawning(delta: float) -> void:
	if not wave_started or wave_manager.state != WaveManager.WaveState.SPAWNING:
		return
	spawn_remaining -= delta
	if spawn_remaining > 0.0:
		return
	var enemy_id: StringName = wave_manager.take_next_spawn()
	if enemy_id != &"":
		spawn_enemy(enemy_id)
		spawn_remaining = SPAWN_INTERVAL


func spawn_enemy(enemy_id: StringName = WaveManager.NORMAL_ID) -> Enemy3D:
	var data: EnemyData = wave_manager.get_enemy_data(enemy_id)
	if data == null:
		return null
	var enemy := Enemy3D.new()
	enemy_route.add_child(enemy)
	enemy.setup(data)
	enemy.defeated.connect(_on_enemy_defeated.bind(enemy))
	enemy.reached_castle.connect(_on_enemy_reached_castle.bind(enemy))
	enemies.append(enemy)
	active_enemies += 1
	_refresh_hud(false)
	return enemy


func _on_enemy_defeated(reward: int, _world_position: Vector3, enemy: Enemy3D) -> void:
	enemies.erase(enemy)
	active_enemies = maxi(0, active_enemies - 1)
	enemies_defeated += 1
	economy.add_gold(reward)
	_refresh_hud(false)


func _on_enemy_reached_castle(damage: int, enemy: Enemy3D) -> void:
	enemies.erase(enemy)
	active_enemies = maxi(0, active_enemies - 1)
	castle.take_damage(damage)
	_refresh_hud(false)


func _on_tower_placed(tower: ArcherTower3D, _pad: BuildPad3D, _cost: int) -> void:
	towers.append(tower)
	towers_built += 1
	ui_controller.set_message("OKÇU KULESİ HAZIR")
	_refresh_hud(false)


func _on_placement_rejected(reason: String) -> void:
	ui_controller.set_message(reason)


func _toggle_archer_selection() -> void:
	if placement.selected_data == null:
		placement.select_archer()
	else:
		placement.cancel()


func _on_placement_selection_changed(active: bool) -> void:
	tower_palette.set_selection_active(active)
	if active:
		ui_controller.set_message("OKÇU SEÇİLDİ • ALTIN RENKLİ BİR PLATFORMA DOKUN")


func _on_gold_changed(_current_gold: int) -> void:
	if is_instance_valid(ui_controller):
		_refresh_hud()


func _on_castle_health_changed(_current_health: int) -> void:
	if is_instance_valid(ui_controller):
		_refresh_hud(false)


func _on_castle_defeated() -> void:
	if game_over or victory_shown:
		return
	game_over = true
	wave_manager.set_game_over()
	placement.cancel()
	var layer: CanvasLayer = ui_controller.show_game_over(
		wave,
		economy.total_gold_earned,
		_build_run_summary()
	)
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_process(false)
	for tower in towers:
		if is_instance_valid(tower):
			tower.process_mode = Node.PROCESS_MODE_DISABLED


func _check_wave_completion() -> bool:
	if (
		not wave_started
		or game_over
		or victory_shown
		or wave_manager.state != WaveManager.WaveState.ACTIVE
		or active_enemies > 0
		or projectile_container.get_child_count() > 0
	):
		return false
	if not wave_manager.mark_completed():
		return false
	victory_shown = true
	placement.cancel()
	var stars: int = 3 if castle.health >= 100 else (2 if castle.health >= 60 else 1)
	var layer: CanvasLayer = ui_controller.show_victory(
		"Yeşil Vadi — Kale Yaklaşımı",
		stars,
		castle.health,
		economy.gold,
		towers.size(),
		_build_run_summary()
	)
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	return true


func _use_arrow_rain() -> bool:
	if game_over or victory_shown or ability_cooldown_remaining > 0.0:
		return false
	var valid_targets: Array[Enemy3D] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.has_resolved:
			valid_targets.append(enemy)
	if valid_targets.is_empty():
		ui_controller.set_message("Ok Yağmuru için hedef yok")
		return false
	valid_targets.sort_custom(
		func(a: Enemy3D, b: Enemy3D) -> bool:
			return a.get_route_progress() > b.get_route_progress()
	)
	for index in mini(6, valid_targets.size()):
		var target: Enemy3D = valid_targets[index]
		var arrow := ArrowProjectile3D.new()
		projectile_container.add_child(arrow)
		arrow.global_position = target.global_position + Vector3(0.0, 9.0 + index * 0.35, 0.0)
		arrow.setup(target, 22.0, 24.0, target.global_position)
	ability_cooldown_remaining = ABILITY_COOLDOWN
	arrow_rain_uses += 1
	ui_controller.update_ability_cooldown(ability_cooldown_remaining)
	ui_controller.set_message("OK YAĞMURU")
	return true


func _pause_game() -> void:
	if game_over or victory_shown:
		return
	ui_controller.show_pause()
	get_tree().paused = true


func _resume_game() -> void:
	ui_controller.hide_pause()
	get_tree().paused = false


func _set_game_speed(speed: float) -> void:
	Engine.time_scale = 2.0 if speed >= 1.5 else 1.0


func _restart_scene() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _return_to_main_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(MenuNavigation.MAIN_MENU)


func _refresh_hud(animate_gold: bool = true) -> void:
	if not is_instance_valid(ui_controller):
		return
	ui_controller.update_gold(economy.gold, animate_gold)
	ui_controller.update_status(
		maxi(1, wave),
		castle.health,
		active_enemies,
		VERTICAL_SLICE_WAVES
	)


func _build_run_summary() -> Dictionary:
	return {
		"wave": wave,
		"base_health": castle.health,
		"gold_earned": economy.total_gold_earned,
		"enemies_defeated": enemies_defeated,
		"bosses_defeated": 0,
		"towers_built": towers_built,
		"upgrades": 0,
		"towers_sold": 0,
		"arrow_rain_uses": arrow_rain_uses,
		"favorite_tower": &"archer",
		"achievements_unlocked": []
	}


func get_state_snapshot() -> Dictionary:
	return {
		"wave": wave,
		"gold": economy.gold,
		"castle_health": castle.health,
		"active_enemies": active_enemies,
		"towers": towers.size(),
		"ability_cooldown": ability_cooldown_remaining,
		"paused": get_tree().paused,
		"game_over": game_over,
		"victory": victory_shown
	}
