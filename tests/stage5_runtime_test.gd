extends SceneTree

const ArrowScript = preload("res://scripts/arrow.gd")
const VisualEffectScript = preload("res://scripts/visual_effect.gd")

var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = await _create_game()
	game.set_process(false)
	game.archer.stop_combat()

	await _test_damage_and_death(game)
	await _test_projectile_and_fire_feedback(game)
	await _test_gold_and_build_feedback(game)
	await _test_panel_and_boss_warning(game)
	await _test_game_over_and_restart_cleanup(game)
	game.queue_free()
	await process_frame

	var stress_game: Node = await _create_game()
	stress_game.set_process(false)
	stress_game.archer.stop_combat()
	await _test_visual_stress(stress_game)
	stress_game.queue_free()
	await process_frame

	if failures == 0:
		print("STAGE5_TEST_PASS")
	else:
		push_error("STAGE5_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _create_game() -> Node:
	var scene_resource: PackedScene = load("res://main.tscn")
	var game: Node = scene_resource.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	return game


func _test_damage_and_death(game: Node) -> void:
	var enemy: PathEnemy = game._spawn_enemy(WaveManager.NORMAL_ID)
	enemy.take_damage(1.0)
	_expect(enemy.modulate != Color.WHITE, "Hasar flash efekti başlamalı")
	await create_timer(0.16).timeout
	_expect(enemy.modulate.is_equal_approx(Color.WHITE), "Hasar flash efekti güvenli bitmeli")

	var reward_before: int = game.economy.gold
	var first_resolution: bool = enemy.resolve_defeated()
	var second_resolution: bool = enemy.resolve_defeated()
	_expect(first_resolution and not second_resolution, "Ölüm sırasında ikinci çözülme engellenmeli")
	_expect(
		game.economy.gold == reward_before + enemy.reward,
		"Ölüm animasyonu ödülü yalnızca bir kez vermeli"
	)
	_expect(is_instance_valid(enemy), "Düşman kısa ölüm animasyonu sırasında sahnede kalmalı")
	await create_timer(0.34).timeout
	_expect(not is_instance_valid(enemy), "Ölüm animasyonu sonunda düşman temizlenmeli")


func _test_projectile_and_fire_feedback(game: Node) -> void:
	var target: PathEnemy = game._spawn_enemy(WaveManager.BOSS_ID)
	target.set_process(false)
	var normal_arrow := ArrowScript.new()
	game.add_child(normal_arrow)
	normal_arrow.setup(target, 2.0, 760.0, false)
	var heavy_bolt := ArrowScript.new()
	game.add_child(heavy_bolt)
	heavy_bolt.setup(target, 28.0, 900.0, true)
	_expect(
		not normal_arrow.is_heavy and heavy_bolt.is_heavy,
		"Normal ok ve ağır bolt farklı ayarlara sahip olmalı"
	)
	_expect(
		heavy_bolt.damage > normal_arrow.damage and heavy_bolt.speed > normal_arrow.speed,
		"Ağır bolt hasar ve hız ayarlarıyla ayrışmalı"
	)
	normal_arrow.queue_free()
	heavy_bolt.queue_free()

	var tower := ShooterUnit.new()
	game.add_child(tower)
	tower.setup_tower(ShooterUnit.TowerType.CROSSBOW)
	tower.set_process(false)
	tower.position = Vector2(300.0, 900.0)
	var original_position: Vector2 = tower.position
	tower._shoot(target)
	await create_timer(0.32).timeout
	_expect(
		tower.position.is_equal_approx(original_position),
		"Kule ateş animasyonu kalıcı pozisyon kayması oluşturmamalı"
	)
	_expect(tower.scale.is_equal_approx(Vector2.ONE), "Kule geri tepme sonrası ölçeğini korumalı")
	tower.queue_free()
	target.resolve_defeated()
	await create_timer(0.32).timeout


func _test_gold_and_build_feedback(game: Node) -> void:
	game._spawn_floating_gold(Vector2(400.0, 700.0), 7)
	_expect(
		game.get_tree().get_nodes_in_group("visual_effects").size() > 0,
		"Floating gold efekti oluşturulmalı"
	)
	await create_timer(0.82).timeout
	_expect(
		game.get_tree().get_nodes_in_group("visual_effects").is_empty(),
		"Floating gold text süre sonunda temizlenmeli"
	)

	game.economy.add_gold(100)
	game._open_tower_selection(0)
	await process_frame
	game._on_tower_selected(ShooterUnit.TowerType.ARCHER)
	_expect(game.towers.size() == 1, "Kule kurma animasyonu yalnızca bir kule oluşturmalı")
	_expect(game.built_spots[0], "Kurulan BuildSpot dolu hale gelmeli")
	game._open_tower_selection(0)
	_expect(not is_instance_valid(game.tower_selection_panel), "Dolu BuildSpot tekrar kullanılamamalı")
	await create_timer(0.40).timeout
	_expect(game.towers[0].scale.is_equal_approx(Vector2.ONE), "Kule kurma animasyonu tamamlanmalı")


func _test_panel_and_boss_warning(game: Node) -> void:
	game._open_tower_selection(1)
	await process_frame
	_expect(is_instance_valid(game.tower_selection_panel), "Kule seçim paneli açılabilmeli")
	var selected_before: int = game.selected_build_spot
	var touch := InputEventScreenTouch.new()
	touch.position = game.build_spots[2]
	touch.pressed = true
	game._unhandled_input(touch)
	_expect(
		game.selected_build_spot == selected_before and not game.built_spots[2],
		"Panel açıkken alttaki oyun alanı girişi engellenmeli"
	)
	game._close_tower_panel()
	await process_frame
	_expect(not is_instance_valid(game.tower_selection_panel), "Kule seçim paneli kapanabilmeli")

	game.wave = 5
	game._show_boss_warning()
	var first_tween: Tween = game.boss_warning_tween
	game._show_boss_warning()
	_expect(game.boss_warning_tween == first_tween, "Boss uyarısı aynı dalgada yalnızca bir kez gösterilmeli")
	_expect(game.boss_warning_label.visible, "Boss uyarısı görünür olmalı")
	await create_timer(2.2).timeout
	_expect(not game.boss_warning_label.visible, "Boss uyarısı süre sonunda kapanmalı")


func _test_game_over_and_restart_cleanup(game: Node) -> void:
	game._finish_game()
	var original_layer: CanvasLayer = game.game_over_layer
	game._finish_game()
	_expect(game.game_over_layer == original_layer, "Game over paneli yalnızca bir kez açılmalı")

	var lingering_effect := VisualEffectScript.new()
	game.add_child(lingering_effect)
	lingering_effect.setup_build_dust()
	game._prepare_restart()
	await process_frame
	_expect(
		game.get_tree().get_nodes_in_group("visual_effects").is_empty(),
		"Restart bütün efekt düğümlerini temizlemeli"
	)


func _test_visual_stress(game: Node) -> void:
	game.wave = 10
	game.wave_manager.state = WaveManager.WaveState.SPAWNING
	var enemies: Array[PathEnemy] = []
	for index in range(50):
		var enemy_id: StringName = (
			WaveManager.FAST_ID if index % 3 == 0 else WaveManager.NORMAL_ID
		)
		var enemy: PathEnemy = game._spawn_enemy(enemy_id)
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
	_expect(game.active_enemy_count == 0, "50 düşman görsel stres sırasında güvenli çözülmeli")
	await create_timer(1.05).timeout
	_expect(
		game.get_tree().get_nodes_in_group("visual_effects").is_empty(),
		"Kısa ömürlü efektler stres sonrası birikmemeli"
	)
	_expect(
		game.get_tree().get_nodes_in_group("projectiles").is_empty(),
		"Çoklu mermiler stres sonrası temizlenmeli"
	)
	print("STAGE5_STRESS_PASS: 50 düşman, 80 mermi")


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
