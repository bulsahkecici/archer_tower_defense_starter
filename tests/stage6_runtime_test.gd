extends SceneTree

var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_use_clean_level_one_save("stage6")
	var game: Node = await _create_game()
	game.set_process(false)
	game.archer.stop_combat()
	game.economy.add_gold(200)

	_click(_spot_screen(game, 0))
	await process_frame
	await process_frame
	_click(game.tower_selection_panel.archer_button.get_global_rect().get_center())
	await process_frame
	await create_timer(0.36).timeout
	var tower: ShooterUnit = game.towers[0] as ShooterUnit
	_expect(game.built_spots[0] and tower.level == 1, "Gerçek input ile seviye 1 kule kurulmalı")

	_touch(_spot_screen(game, 0))
	await process_frame
	await process_frame
	var panel: TowerUpgradePanel = game.tower_upgrade_panel
	_expect(is_instance_valid(panel), "Kurulmuş kule touch ile seçilip yükseltme paneli açılmalı")
	_expect(
		panel.title_label.text.contains("Okçu") and panel.level_label.text.contains("1"),
		"Panel doğru kule ve seviye değerini göstermeli"
	)
	var gold_before_upgrade: int = game.economy.gold
	var damage_before: float = tower.damage
	var range_before: float = tower.attack_range
	var interval_before: float = tower.fire_interval
	_click(panel.upgrade_button.get_global_rect().get_center())
	await process_frame
	_expect(tower.level == 2, "Kule seviye 1'den 2'ye yükselmeli")
	_expect(
		game.economy.gold == gold_before_upgrade - 20,
		"Seviye 2 maliyeti yalnızca bir kez harcanmalı"
	)
	_expect(tower.damage > damage_before, "Yükseltme hasarı artırmalı")
	_expect(tower.attack_range > range_before, "Yükseltme menzili artırmalı")
	_expect(tower.fire_interval < interval_before, "Yükseltme atış aralığını düşürmeli")

	var gold_before_second: int = game.economy.gold
	_click(panel.upgrade_button.get_global_rect().get_center())
	await process_frame
	_expect(tower.level == 3, "Kule seviye 3'e yükselmeli")
	_expect(game.economy.gold == gold_before_second - 35, "Seviye 3 maliyeti doğru harcanmalı")
	var gold_at_max: int = game.economy.gold
	_expect(panel.upgrade_button.disabled, "Maksimum seviyede yükseltme düğmesi pasif olmalı")
	panel.upgrade_requested.emit()
	await process_frame
	_expect(
		tower.level == 3 and game.economy.gold == gold_at_max,
		"Maksimum seviyede ek seviye veya harcama olmamalı"
	)

	game.economy.setup(0)
	panel.refresh()
	_expect(panel.upgrade_button.disabled, "Yetersiz altın yükseltmeyi engellemeli")
	game.economy.add_gold(100)

	var enemy: PathEnemy = game._spawn_enemy(WaveManager.BOSS_ID)
	enemy.set_process(false)
	enemy.global_position = tower.global_position + Vector2(250.0, 0.0)
	var health_before: float = enemy.health
	tower.cooldown = 0.0
	var projectile: Node2D
	for frame in range(30):
		await process_frame
		if is_instance_valid(tower.last_projectile):
			projectile = tower.last_projectile
			break
	_expect(is_instance_valid(projectile), "Yükseltilmiş kule otomatik ateş etmeye devam etmeli")
	var projectile_start: Vector2 = projectile.global_position if is_instance_valid(projectile) else Vector2.ZERO
	for frame in range(10):
		await process_frame
	_expect(
		is_instance_valid(projectile)
		and projectile_start.distance_to(projectile.global_position) > 5.0,
		"Yükseltilmiş kulenin mermisi hareket etmeli"
	)
	for frame in range(90):
		if not is_instance_valid(projectile):
			break
		await process_frame
	_expect(enemy.health < health_before, "Yükseltilmiş kule mermisi hasar vermeli")
	if is_instance_valid(enemy):
		enemy.resolve_defeated()

	var expected_refund: int = tower.get_sell_refund()
	var gold_before_sell: int = game.economy.gold
	panel = game.tower_upgrade_panel
	panel.sell_requested.emit()
	await process_frame
	await process_frame
	_expect(game.economy.gold == gold_before_sell + expected_refund, "Satış doğru geri ödemeyi eklemeli")
	_expect(not game.built_spots[0], "Satılan BuildSpot tekrar boş olmalı")
	_expect(not is_instance_valid(tower), "Satılan kule güvenli temizlenmeli")
	_expect(not is_instance_valid(game.tower_upgrade_panel), "Satış paneli kapanmalı")

	_touch(_spot_screen(game, 0))
	await process_frame
	_expect(
		is_instance_valid(game.tower_selection_panel),
		"Satış sonrası BuildSpot yeniden kurma paneli açmalı"
	)
	game._prepare_restart()
	await process_frame
	_expect(
		game.towers.is_empty()
		and not is_instance_valid(game.tower_upgrade_panel)
		and game.built_spots.all(func(value: bool) -> bool: return not value),
		"Restart kule seviyelerini, panelleri ve BuildSpot durumunu temizlemeli"
	)
	game.queue_free()
	await process_frame

	if failures == 0:
		print("STAGE6_TEST_PASS")
	else:
		push_error("STAGE6_TEST_FAIL: %d hata" % failures)
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
	game.confirm_wave_preview_for_test()
	await process_frame
	return game


func _spot_screen(game: Node, index: int) -> Vector2:
	var world: Vector2 = game.tower_build_manager.to_global(game.build_spots[index])
	return game.get_viewport().get_canvas_transform() * world


func _click(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	var release := event.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)


func _touch(position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = true
	root.push_input(event, true)
	var release := event.duplicate() as InputEventScreenTouch
	release.pressed = false
	root.push_input(release, true)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
