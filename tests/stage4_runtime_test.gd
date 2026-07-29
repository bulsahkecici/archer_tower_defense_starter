extends SceneTree

var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = await _create_game()
	game.set_process(false)

	var normal: EnemyData = game.wave_manager.get_enemy_data(WaveManager.NORMAL_ID)
	var fast: EnemyData = game.wave_manager.get_enemy_data(WaveManager.FAST_ID)
	var boss: EnemyData = game.wave_manager.get_enemy_data(WaveManager.BOSS_ID)
	_expect(normal.max_health == 30.0, "Normal düşman canı veri kataloğundan gelmeli")
	_expect(normal.movement_speed == 75.0, "Normal düşman hızı doğru olmalı")
	_expect(normal.reward_gold == 3 and normal.base_damage == 5, "Normal ödül/hasar doğru olmalı")
	_expect(fast.movement_speed > normal.movement_speed, "Hızlı düşman daha hızlı olmalı")
	_expect(fast.max_health < normal.max_health, "Hızlı düşman daha düşük canlı olmalı")
	_expect(boss.body_radius > normal.body_radius * 1.6, "Boss belirgin şekilde büyük olmalı")
	_expect(boss.max_health > normal.max_health, "Boss daha yüksek canlı olmalı")

	await _test_enemy_rewards(game, normal, fast, boss)
	await _test_base_resolution(game, normal)
	_test_wave_compositions(game)
	await _test_wave_completion(game)
	await _test_game_over_security(game)
	await _test_restart_cleanup(game)
	game.queue_free()
	await process_frame

	var stress_game: Node = await _create_game()
	stress_game.set_process(false)
	await _test_stress(stress_game)
	stress_game.queue_free()
	await process_frame

	var fresh_game: Node = await _create_game()
	fresh_game.set_process(false)
	_expect(fresh_game.wave == 1, "Yeniden yüklenen oyun dalga 1'den başlamalı")
	var original_wave: int = fresh_game.wave
	fresh_game._start_next_wave()
	_expect(fresh_game.wave == original_wave, "İlk dalga aynı anda iki kez başlamamalı")
	fresh_game.queue_free()
	await process_frame

	if failures == 0:
		print("STAGE4_TEST_PASS")
	else:
		push_error("STAGE4_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _create_game() -> Node:
	var scene_resource: PackedScene = load("res://main.tscn")
	var game: Node = scene_resource.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	return game


func _test_enemy_rewards(
	game: Node,
	normal: EnemyData,
	fast: EnemyData,
	boss: EnemyData
) -> void:
	var datasets: Array[EnemyData] = [normal, fast, boss]
	for enemy_data in datasets:
		var gold_before: int = game.economy.gold
		var enemy: PathEnemy = game._spawn_enemy(enemy_data.id)
		_expect(is_instance_valid(enemy), "%s üretilebilmeli" % enemy_data.display_name)
		enemy.take_damage(enemy.max_health + 1.0)
		var gold_after_first_hit: int = game.economy.gold
		enemy.take_damage(enemy.max_health + 1.0)
		_expect(
			gold_after_first_hit == gold_before + enemy.reward,
			"%s doğru ödülü vermeli" % enemy_data.display_name
		)
		_expect(
			game.economy.gold == gold_after_first_hit,
			"%s yalnızca bir kez ödül vermeli" % enemy_data.display_name
		)
		await process_frame


func _test_base_resolution(game: Node, normal: EnemyData) -> void:
	var gold_before: int = game.economy.gold
	var health_before: int = game.base.health
	var enemy: PathEnemy = game._spawn_enemy(normal.id)
	var first_resolution: bool = enemy.resolve_at_base()
	var second_resolution: bool = enemy.resolve_at_base()
	_expect(first_resolution and not second_resolution, "Kale çözülmesi yalnızca bir kez olmalı")
	_expect(game.economy.gold == gold_before, "Kaleye ulaşan düşman altın vermemeli")
	_expect(
		game.base.health == health_before - normal.base_damage,
		"Düşman kendi base_damage değeri kadar hasar vermeli"
	)
	await process_frame


func _test_wave_compositions(game: Node) -> void:
	var wave_one: Array[StringName] = game.wave_manager.get_wave_composition(1)
	var wave_five: Array[StringName] = game.wave_manager.get_wave_composition(5)
	_expect(wave_one.count(WaveManager.NORMAL_ID) == 8, "Dalga 1 sekiz normal içermeli")
	_expect(wave_five.count(WaveManager.NORMAL_ID) == 8, "Dalga 5 sekiz normal içermeli")
	_expect(wave_five.count(WaveManager.FAST_ID) == 4, "Dalga 5 dört hızlı içermeli")
	_expect(wave_five.count(WaveManager.BOSS_ID) == 1, "Dalga 5 tek boss içermeli")


func _test_wave_completion(game: Node) -> void:
	game.wave_manager.state = WaveManager.WaveState.ACTIVE
	var boss_enemy: PathEnemy = game._spawn_enemy(WaveManager.BOSS_ID)
	game._process(0.016)
	_expect(
		game.wave_manager.state == WaveManager.WaveState.ACTIVE,
		"Boss canlıyken dalga tamamlanmamalı"
	)
	boss_enemy.resolve_defeated()
	await process_frame
	game._process(0.016)
	_expect(
		game.wave_manager.state == WaveManager.WaveState.COMPLETED,
		"Tüm düşmanlar çözülünce dalga tamamlanmalı"
	)
	game._process(0.016)
	_expect(
		game.wave_manager.state == WaveManager.WaveState.COMPLETED,
		"Dalga tamamlanması yalnızca bir kez tetiklenmeli"
	)


func _test_game_over_security(game: Node) -> void:
	game._finish_game()
	game._finish_game()
	_expect(game.game_over_trigger_count == 1, "Game over yalnızca bir kez tetiklenmeli")
	_expect(
		game.wave_manager.state == WaveManager.WaveState.GAME_OVER,
		"Dalga state'i GAME_OVER olmalı"
	)
	_expect(not game.archer.combat_enabled, "Game over sonrası ana okçu durmalı")
	var spawned_after_game_over: PathEnemy = game._spawn_enemy(WaveManager.NORMAL_ID)
	_expect(spawned_after_game_over == null, "Game over sonrası spawn durmalı")
	var gold_before: int = game.economy.gold
	game._on_enemy_defeated(99, Vector2.ZERO)
	_expect(game.economy.gold == gold_before, "Game over sonrası altın eklenmemeli")
	_expect(
		is_instance_valid(game.game_over_layer),
		"Game over paneli yalnızca bir örnek olarak bulunmalı"
	)


func _test_restart_cleanup(game: Node) -> void:
	game.built_spots[0] = true
	var tower := ShooterUnit.new()
	game.add_child(tower)
	tower.setup_tower(ShooterUnit.TowerType.ARCHER)
	game.towers.append(tower)
	game._prepare_restart()
	await process_frame
	_expect(game.wave == 0, "Restart hazırlığında dalga sıfırlanmalı")
	_expect(
		game.economy.gold == game.level_data.starting_gold,
		"Restart seçili bölümün başlangıç altınını yenilemeli"
	)
	_expect(game.base.health == game.base.max_health, "Restart kale canını yenilemeli")
	_expect(game.towers.is_empty(), "Restart kule listesini temizlemeli")
	_expect(game.built_spots.all(func(value: bool) -> bool: return not value), "BuildSpot'lar boşalmalı")
	_expect(game.active_enemy_count == 0, "Aktif düşman sayacı sıfırlanmalı")
	_expect(
		game.wave_manager.state == WaveManager.WaveState.WAITING,
		"Dalga state'i başlangıç durumuna dönmeli"
	)
	_expect(
		game.get_tree().get_nodes_in_group("projectiles").is_empty(),
		"Restart mermileri temizlemeli"
	)


func _test_stress(game: Node) -> void:
	game.wave = 10
	game.wave_manager.state = WaveManager.WaveState.SPAWNING
	var enemies: Array[PathEnemy] = []
	for index in range(50):
		var enemy_id: StringName = (
			WaveManager.FAST_ID if index % 3 == 0 else WaveManager.NORMAL_ID
		)
		var enemy: PathEnemy = game._spawn_enemy(enemy_id)
		enemies.append(enemy)
	_expect(enemies.size() == 50, "Stres senaryosu 50 düşman üretmeli")
	_expect(game.active_enemy_count == 50, "50 düşman aktif sayılmalı")
	for simulation_step in range(30):
		for enemy in enemies:
			if is_instance_valid(enemy) and not enemy.has_resolved:
				enemy._process(0.016)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.resolve_defeated()
	await process_frame
	_expect(game.active_enemy_count == 0, "50 düşman güvenli şekilde çözülmeli")
	print("STRESS_TEST_PASS: 50 düşman, 30 simülasyon adımı")


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
