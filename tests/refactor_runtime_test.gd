extends SceneTree

const ArrowScript = preload("res://scripts/arrow.gd")

var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = await _create_game()
	game.set_process(false)
	game.archer.stop_combat()
	await _test_visual_node_structure(game)
	await _test_tower_data_and_panel(game)
	await _test_build_animation_safety(game)
	await _test_controllers(game)
	_test_safe_area_and_balance(game)
	await _test_stress(game)
	game.queue_free()
	await process_frame

	if failures == 0:
		print("REFACTOR_TEST_PASS")
	else:
		push_error("REFACTOR_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _create_game() -> Node:
	var scene_resource: PackedScene = load("res://main.tscn")
	var game: Node = scene_resource.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	return game


func _test_visual_node_structure(game: Node) -> void:
	var tower := ShooterUnit.new()
	game.add_child(tower)
	tower.set_projectile_parent(game.projectiles)
	tower.position = Vector2(300.0, 900.0)
	tower.setup_tower(ShooterUnit.TowerType.ARCHER)
	tower.set_process(false)
	var target: PathEnemy = game._spawn_enemy(WaveManager.NORMAL_ID)
	target.set_process(false)
	target.global_position = Vector2(650.0, 760.0)

	var root_rotation_before: float = tower.rotation
	var static_rotation_before: float = tower.static_base.rotation
	var muzzle_before: Vector2 = tower.muzzle.global_position
	tower._shoot(target)
	_expect(tower.rotation == root_rotation_before, "Kule kökü ateş ederken dönmemeli")
	_expect(tower.static_base.rotation == static_rotation_before, "StaticBase hedefe dönmemeli")
	_expect(absf(tower.turret_head.rotation) > 0.01, "TurretHead hedef yönüne dönmeli")
	_expect(
		not tower.muzzle.global_position.is_equal_approx(muzzle_before),
		"Muzzle TurretHead ile birlikte hareket etmeli"
	)
	_expect(
		is_instance_valid(tower.last_projectile)
		and tower.last_projectile.global_position.is_equal_approx(tower.muzzle.global_position),
		"Ok Muzzle.global_position konumundan başlamalı"
	)
	var projectile: Node2D = tower.last_projectile
	var projectile_start: Vector2 = projectile.global_position
	for frame in range(10):
		await process_frame
	_expect(
		is_instance_valid(projectile)
		and projectile_start.distance_to(projectile.global_position) > 5.0,
		"Ok gerçek process framelerinde dünya koordinatında ilerlemeli"
	)
	_expect(
		projectile.get_parent() == game.projectiles,
		"Ok bağımsız Projectiles container altında olmalı"
	)
	tower.stop_combat()
	target.resolve_defeated()
	tower.queue_free()
	await create_timer(0.34).timeout


func _test_tower_data_and_panel(game: Node) -> void:
	var archer_data: TowerData = TowerData.create_archer()
	var crossbow_data: TowerData = TowerData.create_crossbow()
	_expect(
		archer_data.damage == 10.0
		and archer_data.fire_interval == 0.8
		and archer_data.attack_range == 336.0,
		"TowerData Okçu Kulesi değerlerini doğru sağlamalı"
	)
	_expect(
		crossbow_data.damage == 28.0
		and crossbow_data.fire_interval == 1.6
		and crossbow_data.attack_range == 418.0,
		"TowerData Arbalet Kulesi değerlerini doğru sağlamalı"
	)
	game.economy.add_gold(100)
	game._open_tower_selection(0)
	await process_frame
	var panel: TowerSelectionPanel = game.tower_selection_panel
	_expect(panel.archer_data.damage == archer_data.damage, "Panel Okçu verisini TowerData'dan almalı")
	_expect(
		panel.crossbow_data.attack_range == crossbow_data.attack_range,
		"Panel Arbalet verisini TowerData'dan almalı"
	)
	_expect(
		panel.get_tower_cost(ShooterUnit.TowerType.ARCHER) == 15
		and panel.get_tower_cost(ShooterUnit.TowerType.CROSSBOW) == 30,
		"Kule ek maliyetleri TowerData üzerinden hesaplanmalı"
	)
	_expect(panel.panel_rect.size.x > 0.0, "Responsive panel gerçek bir container rect üretmeli")
	game._close_tower_panel()
	await process_frame


func _test_build_animation_safety(game: Node) -> void:
	var tower := ShooterUnit.new()
	game.add_child(tower)
	tower.position = Vector2(420.0, 880.0)
	tower.setup_tower(ShooterUnit.TowerType.CROSSBOW)
	var expected_position: Vector2 = tower.position
	tower.play_build_animation()
	await create_timer(0.36).timeout
	_expect(tower.position.is_equal_approx(expected_position), "İnşa animasyonu resting_position'a dönmeli")
	_expect(tower.combat_enabled, "İnşa animasyonu sonrası savaş açılmalı")

	tower.position = Vector2(520.0, 980.0)
	var interrupted_resting_position: Vector2 = tower.position
	tower.play_build_animation()
	await create_timer(0.08).timeout
	tower.stop_combat()
	_expect(
		tower.position.is_equal_approx(interrupted_resting_position),
		"Yarıda kesilen animasyon kule konumunu bozmamalı"
	)
	_expect(
		tower.scale.is_equal_approx(Vector2.ONE) and tower.modulate.is_equal_approx(Color.WHITE),
		"stop_combat ölçek ve modulate değerlerini düzeltmeli"
	)
	tower.queue_free()
	await process_frame


func _test_controllers(game: Node) -> void:
	game.ui_controller.update_gold(77, false)
	game.ui_controller.update_status(6, 84, 3)
	_expect(game.ui_controller.gold_label.text.contains("77"), "UIController altın HUD değerini güncellemeli")
	_expect(game.ui_controller.wave_label.text.contains("6"), "UIController dalga HUD değerini güncellemeli")
	_expect(game.ui_controller.base_label.text.contains("84"), "UIController kale HUD değerini güncellemeli")

	game._open_tower_selection(0)
	await process_frame
	var selected_before: int = game.selected_build_spot
	var touch := InputEventScreenTouch.new()
	touch.position = game.build_spots[1]
	touch.pressed = true
	game._unhandled_input(touch)
	_expect(game.selected_build_spot == selected_before, "Panel açıkken dünya girişi engellenmeli")
	game._on_tower_selected(ShooterUnit.TowerType.ARCHER)
	await process_frame
	_expect(game.built_spots[0], "TowerBuildManager noktayı dolu işaretlemeli")
	var tower_count: int = game.towers.size()
	game._open_tower_selection(0)
	_expect(game.towers.size() == tower_count, "Dolu noktaya ikinci kule kurulmamalı")
	game._prepare_restart()
	await process_frame
	_expect(
		game.built_spots.all(func(value: bool) -> bool: return not value),
		"Restart TowerBuildManager durumunu temizlemeli"
	)


func _test_safe_area_and_balance(game: Node) -> void:
	var safe_rect: Rect2 = SafeAreaHelper.get_safe_rect(Vector2(1080.0, 1920.0))
	_expect(
		safe_rect.position.x >= 0.0
		and safe_rect.position.y >= 0.0
		and safe_rect.size.x > 0.0
		and safe_rect.size.y > 0.0,
		"Safe-area yardımcısı geçerli bir rect üretmeli"
	)
	for wave_number in [1, 5, 10, 20]:
		var balance: Dictionary = game.wave_manager.get_wave_balance(wave_number)
		_expect(
			float(balance["normal_health"]) > 0.0
			and float(balance["fast_health"]) > 0.0
			and float(balance["boss_health"]) > 0.0
			and float(balance["total_health"]) > 0.0
			and int(balance["total_reward"]) > 0,
			"Dalga %d denge değerleri pozitif olmalı" % wave_number
		)
	var wave_ten: Dictionary = game.wave_manager.get_wave_balance(10)
	var wave_twenty: Dictionary = game.wave_manager.get_wave_balance(20)
	_expect(
		float(wave_ten["health_multiplier"]) < 2.0,
		"İlk 10 dalga can çarpanı kontrollü kalmalı"
	)
	_expect(
		float(wave_twenty["health_multiplier"]) < 3.6,
		"Dalga 20 can çarpanı kontrolsüz büyümemeli"
	)


func _test_stress(game: Node) -> void:
	game.wave = 10
	game.game_over = false
	game.wave_manager.state = WaveManager.WaveState.SPAWNING
	var enemies: Array[PathEnemy] = []
	for index in range(50):
		var enemy: PathEnemy = game._spawn_enemy(
			WaveManager.FAST_ID if index % 3 == 0 else WaveManager.NORMAL_ID
		)
		enemy.set_process(false)
		enemies.append(enemy)
	for index in range(80):
		var target: PathEnemy = enemies[index % enemies.size()]
		var projectile := ArrowScript.new()
		game.add_child(projectile)
		projectile.global_position = target.global_position
		projectile.setup(target, 0.1, 900.0, index % 4 == 0)
		projectile._process(0.016)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.resolve_defeated()
	await create_timer(1.05).timeout
	_expect(game.active_enemy_count == 0, "50 düşman güvenli çözülmeli")
	_expect(
		game.get_tree().get_nodes_in_group("projectiles").is_empty(),
		"80 mermi temizlenmeli"
	)
	_expect(
		game.get_tree().get_nodes_in_group("visual_effects").is_empty(),
		"Kısa ömürlü efektler birikmemeli"
	)
	print("REFACTOR_STRESS_PASS: 50 düşman, 80 mermi")


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
