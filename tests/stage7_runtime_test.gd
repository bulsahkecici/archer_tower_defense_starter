extends SceneTree

const ArrowScript = preload("res://scripts/arrow.gd")

var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_use_clean_level_one_save("stage7")
	var game: Node = await _create_game()
	game.set_process(false)
	game.archer.stop_combat()
	await _test_tower_catalog_and_projectiles(game)
	await _test_enemy_types_and_status(game)
	await _test_targeting_and_ability(game)
	await _test_stress(game)
	game.queue_free()
	await process_frame
	if failures == 0:
		print("STAGE7_TEST_PASS")
	else:
		push_error("STAGE7_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _use_clean_level_one_save(test_name: String) -> void:
	var save_manager: Node = root.get_node("SaveManager")
	save_manager.set_save_path("/private/tmp/archer_%s_save.json" % test_name)
	save_manager.reset_defaults()
	save_manager.tutorial_completed = true


func _create_game() -> Node:
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	return game


func _test_tower_catalog_and_projectiles(game: Node) -> void:
	game.economy.add_gold(200)
	game._open_tower_selection(0)
	await process_frame
	_expect(
		is_instance_valid(game.tower_selection_panel.ice_button)
		and is_instance_valid(game.tower_selection_panel.bomb_button),
		"Buz ve Bomba kuleleri seçim panelinde bulunmalı"
	)
	game._close_tower_panel()

	var ice_tower: ShooterUnit = _make_tower(game, ShooterUnit.TowerType.ICE, Vector2(420.0, 900.0))
	var ice_enemy: PathEnemy = _spawn_stationary(game, WaveManager.FAST_ID, Vector2(660.0, 900.0))
	ice_tower._process(0.016)
	var ice_arrow: Node2D = ice_tower.last_projectile
	_expect(is_instance_valid(ice_arrow), "Buz Kulesi mermi oluşturmalı")
	var ice_start: Vector2 = ice_arrow.global_position
	for frame in range(10):
		await process_frame
	_expect(ice_start.distance_to(ice_arrow.global_position) > 5.0, "Buz mermisi hareket etmeli")
	for frame in range(90):
		if not is_instance_valid(ice_arrow):
			break
		await process_frame
	_expect(ice_enemy.slow_ratio > 0.0, "Buz mermisi slow uygulamalı")
	ice_enemy.resolve_defeated()
	ice_tower.queue_free()
	await process_frame

	var bomb_tower: ShooterUnit = _make_tower(game, ShooterUnit.TowerType.BOMB, Vector2(420.0, 900.0))
	var targets: Array[PathEnemy] = []
	for offset in [Vector2(250.0, 0.0), Vector2(285.0, 20.0), Vector2(300.0, -25.0)]:
		targets.append(_spawn_stationary(game, WaveManager.BOSS_ID, bomb_tower.global_position + offset))
	var health_before: Array[float] = []
	for enemy in targets:
		health_before.append(enemy.health)
	bomb_tower._process(0.016)
	var bomb_arrow: Node2D = bomb_tower.last_projectile
	var bomb_start: Vector2 = bomb_arrow.global_position
	for frame in range(10):
		await process_frame
	_expect(bomb_start.distance_to(bomb_arrow.global_position) > 5.0, "Bomba mermisi hareket etmeli")
	for frame in range(120):
		if not is_instance_valid(bomb_arrow):
			break
		await process_frame
	var damaged_count: int = 0
	for index in targets.size():
		if targets[index].health < health_before[index]:
			damaged_count += 1
		targets[index].resolve_defeated()
	_expect(damaged_count >= 2, "Bomba alan hasarı birden fazla düşmana uygulanmalı")
	bomb_tower.queue_free()
	await process_frame


func _test_enemy_types_and_status(game: Node) -> void:
	var armored_data: EnemyData = game.wave_manager.get_enemy_data(WaveManager.ARMORED_ID)
	var swarm_data: EnemyData = game.wave_manager.get_enemy_data(WaveManager.SWARM_ID)
	_expect(armored_data.armor_ratio == 0.25, "Zırhlı düşman %25 hasar azaltmalı")
	_expect(swarm_data.movement_speed == 145.0 and swarm_data.max_health == 9.0, "Sürü düşmanı hızlı ve düşük canlı olmalı")
	var armored: PathEnemy = _spawn_stationary(game, WaveManager.ARMORED_ID, Vector2(500.0, 700.0))
	var armored_before: float = armored.health
	armored.take_damage(20.0)
	_expect(is_equal_approx(armored_before - armored.health, 15.0), "Zırh gelen hasarı azaltmalı")
	armored.resolve_defeated()

	var normal: PathEnemy = _spawn_stationary(game, WaveManager.NORMAL_ID, Vector2(500.0, 700.0))
	normal.apply_slow(0.25, 1.5)
	var first_slow: float = normal.slow_ratio
	normal.apply_slow(0.10, 0.5)
	_expect(normal.slow_ratio == first_slow, "Zayıf slow güçlü etki üzerine birikmemeli")
	for frame in range(100):
		normal._process(0.02)
	_expect(normal.slow_ratio == 0.0 and is_equal_approx(normal.speed, normal.base_speed), "Slow süresi sonunda hız düzelmeli")
	normal.resolve_defeated()

	var boss: PathEnemy = _spawn_stationary(game, WaveManager.BOSS_ID, Vector2(500.0, 700.0))
	boss.apply_slow(0.25, 1.5)
	_expect(boss.slow_ratio < 0.25, "Boss slow direnci etkiyi azaltmalı")
	boss.resolve_defeated()
	await create_timer(0.34).timeout


func _test_targeting_and_ability(game: Node) -> void:
	var tower: ShooterUnit = _make_tower(game, ShooterUnit.TowerType.ARCHER, Vector2(420.0, 900.0))
	var low: PathEnemy = _spawn_stationary(game, WaveManager.NORMAL_ID, Vector2(600.0, 900.0))
	var high: PathEnemy = _spawn_stationary(game, WaveManager.BOSS_ID, Vector2(650.0, 900.0))
	low.health = 5.0
	high.health = 100.0
	low.progress = 200.0
	high.progress = 100.0
	low.global_position = Vector2(600.0, 900.0)
	high.global_position = Vector2(650.0, 900.0)
	tower.target_mode = ShooterUnit.TargetMode.HIGHEST_HEALTH
	_expect(tower._find_nearest_enemy() == high, "En yüksek can hedefleme modu çalışmalı")
	tower.target_mode = ShooterUnit.TargetMode.LOWEST_HEALTH
	_expect(tower._find_nearest_enemy() == low, "En düşük can hedefleme modu çalışmalı")
	tower.target_mode = ShooterUnit.TargetMode.FIRST
	_expect(tower._find_nearest_enemy() == low, "Yolda ilk hedefleme modu çalışmalı")
	var low_before: float = low.health
	var high_before: float = high.health
	_expect(game._use_arrow_rain(), "Ok Yağmuru kullanılabilmeli")
	_expect(
		is_equal_approx(low.health, low_before)
		and is_equal_approx(high.health, high_before),
		"Ok Yağmuru hasarı görsel varıştan önce uygulanmamalı"
	)
	for _step in range(60):
		var ability_arrows: Array[Node] = get_nodes_in_group("ability_arrows")
		if ability_arrows.is_empty():
			break
		for node in ability_arrows:
			if is_instance_valid(node) and not node.is_queued_for_deletion():
				(node as ArrowRainProjectile)._process(0.05)
		await process_frame
	_expect(
		low.health < low_before and high.health < high_before,
		"Ok Yağmuru görsel varışta görünür düşmanlara hasar vermeli"
	)
	_expect(not game._use_arrow_rain(), "Ok Yağmuru cooldown sırasında iki kez tetiklenmemeli")
	game.ability_cooldown = 0.0
	game.game_over = true
	_expect(not game._use_arrow_rain(), "Game-over sırasında Ok Yağmuru kullanılamamalı")
	game.game_over = false
	low.resolve_defeated()
	high.resolve_defeated()
	tower.queue_free()
	await create_timer(0.34).timeout


func _test_stress(game: Node) -> void:
	game.wave_manager.state = WaveManager.WaveState.SPAWNING
	var enemies: Array[PathEnemy] = []
	for index in range(75):
		var enemy: PathEnemy = game._spawn_enemy(
			WaveManager.SWARM_ID if index % 2 == 0 else WaveManager.ARMORED_ID
		)
		enemy.set_process(false)
		enemies.append(enemy)
	for index in range(40):
		var arrow := ArrowScript.new()
		game.projectiles.add_child(arrow)
		var target: PathEnemy = enemies[index % enemies.size()]
		arrow.global_position = target.global_position
		arrow.setup(target, 1.0, 600.0, true, 0.0, 0.0, 95.0)
		arrow._process(0.016)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.resolve_defeated()
	await create_timer(0.5).timeout
	_expect(game.active_enemy_count == 0, "75 düşman stres testi güvenli çözülmeli")
	print("STAGE7_STRESS_PASS: 75 düşman, 40 alan mermisi")


func _make_tower(game: Node, type: ShooterUnit.TowerType, position: Vector2) -> ShooterUnit:
	var tower := ShooterUnit.new()
	game.add_child(tower)
	tower.set_projectile_parent(game.projectiles)
	tower.position = position
	tower.setup_tower(type)
	tower.set_process(false)
	return tower


func _spawn_stationary(game: Node, id: StringName, position: Vector2) -> PathEnemy:
	var enemy: PathEnemy = game._spawn_enemy(id)
	enemy.set_process(false)
	enemy.global_position = position
	return enemy


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
