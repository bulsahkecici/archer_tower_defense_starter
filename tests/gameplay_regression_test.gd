extends SceneTree

var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_real_automatic_gameplay_flow()
	var game: Node = await _create_game()
	game.set_process(false)
	game.archer.stop_combat()
	await _test_mouse_build_flow(game)
	await _test_touch_and_modal_flow(game)
	await _test_main_archer_projectile(game)
	await _test_tower_projectile(game, ShooterUnit.TowerType.ARCHER)
	await _test_tower_projectile(game, ShooterUnit.TowerType.CROSSBOW)
	await _test_invalid_target_cleanup(game)
	game.queue_free()
	await process_frame

	if failures == 0:
		print("GAMEPLAY_REGRESSION_TEST_PASS")
	else:
		push_error("GAMEPLAY_REGRESSION_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _create_game() -> Node:
	var scene_resource: PackedScene = load("res://main.tscn")
	var game: Node = scene_resource.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	return game


func _test_mouse_build_flow(game: Node) -> void:
	var safe_ui: Control = game.ui_controller.interface_layer.get_node("SafeUI")
	_expect(
		safe_ui.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"Pasif tam ekran SafeUI dünya girişini engellememeli"
	)
	_expect(game.is_processing_input(), "Main aktif _input almalı")
	_expect(
		game.tower_build_manager.is_inside_tree()
		and game.tower_build_manager.process_mode != Node.PROCESS_MODE_DISABLED,
		"TowerBuildManager aktif sahne ağacında olmalı"
	)

	var screen_position: Vector2 = _build_spot_screen_position(game, 0)
	var expected_local: Vector2 = game.tower_build_manager._screen_to_local(screen_position)
	_expect(
		expected_local.is_equal_approx(game.build_spots[0]),
		"Ekran koordinatı BuildSpot yerel/dünya koordinatına doğru çevrilmeli"
	)
	_dispatch_mouse_click(screen_position)
	await process_frame
	await process_frame
	_expect(game.selected_build_spot == 0, "Gerçek mouse olayı doğru BuildSpot indexini seçmeli")
	_expect(
		is_instance_valid(game.tower_selection_panel)
		and game.tower_selection_panel.get_parent() == game.ui_controller.interface_layer
		and game.tower_selection_panel.visible,
		"Gerçek mouse olayı CanvasLayer altında tek görünür panel açmalı"
	)
	if not is_instance_valid(game.tower_selection_panel):
		return
	_expect(
		not game.tower_selection_panel.archer_button.disabled
		and not game.tower_selection_panel.crossbow_button.disabled,
		"Kolay başlangıç altında Okçu ve Arbalet erişilebilir olmalı"
	)

	var gold_before: int = game.economy.gold
	var tower_count_before: int = game.towers.size()
	_dispatch_mouse_click(game.tower_selection_panel.archer_button.get_global_rect().get_center())
	await process_frame
	await process_frame
	_expect(game.towers.size() == tower_count_before + 1, "Kart tıklaması tek kule kurmalı")
	_expect(game.built_spots[0], "Kurulan BuildSpot dolu işaretlenmeli")
	_expect(game.economy.gold == gold_before - 15, "Ekonomi kule bedelini yalnızca bir kez harcamalı")
	await create_timer(0.36).timeout
	_expect(
		game.towers[0].position.is_equal_approx(game.build_spots[0]),
		"Kule seçilen BuildSpot konumunda kurulmalı"
	)
	_dispatch_mouse_click(screen_position)
	await process_frame
	_expect(
		not is_instance_valid(game.tower_selection_panel)
		and is_instance_valid(game.tower_upgrade_panel),
		"Dolu BuildSpot kurma yerine yükseltme paneli açmalı"
	)
	game._close_tower_panel()
	await process_frame


func _test_touch_and_modal_flow(game: Node) -> void:
	game.economy.add_gold(100)
	_dispatch_touch(_build_spot_screen_position(game, 1))
	await process_frame
	await process_frame
	_expect(
		is_instance_valid(game.tower_selection_panel) and game.selected_build_spot == 1,
		"Gerçek dokunmatik olay boş BuildSpot panelini açmalı"
	)
	var selected_before: int = game.selected_build_spot
	_dispatch_touch(_build_spot_screen_position(game, 2))
	await process_frame
	_expect(
		(game.selected_build_spot == selected_before or game.selected_build_spot == -1)
		and not game.built_spots[2],
		"Modal panel açıkken dokunma alttaki BuildSpot'a geçmemeli"
	)
	game._close_tower_panel()
	await process_frame


func _test_main_archer_projectile(game: Node) -> void:
	game.archer.combat_enabled = true
	game.archer.cooldown = 0.0
	var enemy: PathEnemy = _spawn_stationary_enemy(
		game,
		game.archer.global_position + Vector2(300.0, -20.0)
	)
	var health_before: float = enemy.health
	game.archer._process(0.016)
	var arrow: Node2D = game.archer.last_projectile
	await _verify_projectile(game, game.archer, arrow, enemy, false, "Ana okçu")
	await _wait_for_projectile_cleanup(arrow, 90)
	_expect(enemy.health < health_before, "Ana okçu oku hedefe hasar vermeli")
	_expect(not is_instance_valid(arrow), "Vuran ana okçu oku sahneden temizlenmeli")
	if is_instance_valid(enemy):
		enemy.resolve_defeated()
	await process_frame
	game.archer.stop_combat()


func _test_tower_projectile(game: Node, tower_type: ShooterUnit.TowerType) -> void:
	var tower := ShooterUnit.new()
	game.add_child(tower)
	tower.set_projectile_parent(game.projectiles)
	tower.position = Vector2(430.0, 980.0)
	tower.setup_tower(tower_type)
	tower.cooldown = 0.0
	var enemy: PathEnemy = _spawn_stationary_enemy(
		game,
		tower.global_position + Vector2(250.0, -10.0)
	)
	var health_before: float = enemy.health
	tower._process(0.016)
	var projectile: Node2D = tower.last_projectile
	var label: String = (
		"Arbalet Kulesi"
		if tower_type == ShooterUnit.TowerType.CROSSBOW
		else "Okçu Kulesi"
	)
	await _verify_projectile(
		game,
		tower,
		projectile,
		enemy,
		tower_type == ShooterUnit.TowerType.CROSSBOW,
		label
	)
	await _wait_for_projectile_cleanup(projectile, 90)
	_expect(enemy.health < health_before, "%s mermisi hedefe hasar vermeli" % label)
	_expect(not is_instance_valid(projectile), "%s mermisi vuruşta temizlenmeli" % label)
	if is_instance_valid(enemy):
		enemy.resolve_defeated()
	tower.queue_free()
	await process_frame


func _test_real_automatic_gameplay_flow() -> void:
	var game: Node = await _create_game()
	var spot_screen: Vector2 = _build_spot_screen_position(game, 0)
	_dispatch_mouse_click(spot_screen)
	await process_frame
	await process_frame
	_expect(
		is_instance_valid(game.tower_selection_panel),
		"Gerçek akış 15 altınlık BuildSpot panelini açmalı"
	)
	if not is_instance_valid(game.tower_selection_panel):
		game.queue_free()
		await process_frame
		return
	_dispatch_mouse_click(game.tower_selection_panel.archer_button.get_global_rect().get_center())
	await process_frame
	await process_frame
	_expect(game.towers.size() == 1, "Gerçek panel seçimi Okçu Kulesi kurmalı")
	if game.towers.is_empty():
		game.queue_free()
		await process_frame
		return

	var tower: ShooterUnit = game.towers[0]
	await create_timer(0.36).timeout
	_expect(tower.combat_enabled, "İnşa animasyonu combat_enabled değerini açmalı")
	_expect(tower.is_processing(), "Kurulan Okçu Kulesi process almaya devam etmeli")
	_expect(
		tower.build_tween == null or not tower.build_tween.is_valid(),
		"İnşa Tween'i tamamlanmalı"
	)

	var tower_arrow: Node2D
	var tower_arrow_start: Vector2
	var tower_arrow_frames: int = 0
	var tower_target: PathEnemy
	var tower_target_health: float = 0.0
	var tower_moved: bool = false
	var tower_damaged: bool = false
	var hero_arrow: Node2D
	var hero_arrow_start: Vector2
	var hero_arrow_frames: int = 0
	var hero_target: PathEnemy
	var hero_target_health: float = 0.0
	var hero_moved: bool = false
	var hero_damaged: bool = false
	var tower_cooldown_reset: bool = false

	for frame in range(6000):
		await process_frame
		if tower_arrow == null and is_instance_valid(tower.last_projectile):
			tower_arrow = tower.last_projectile
			tower_arrow_start = tower_arrow.global_position
			tower_target = tower_arrow.target as PathEnemy
			tower_target_health = tower_target.health
			tower_cooldown_reset = tower.cooldown > 0.0
		if is_instance_valid(tower_arrow) and tower_arrow_frames < 10:
			tower_arrow_frames += 1
			if tower_arrow_frames == 10:
				tower_moved = tower_arrow_start.distance_to(tower_arrow.global_position) > 5.0
		if is_instance_valid(tower_target) and tower_target.health < tower_target_health:
			tower_damaged = true

		if hero_arrow == null and is_instance_valid(game.archer.last_projectile):
			hero_arrow = game.archer.last_projectile
			hero_arrow_start = hero_arrow.global_position
			hero_target = hero_arrow.target as PathEnemy
			hero_target_health = hero_target.health
		if is_instance_valid(hero_arrow) and hero_arrow_frames < 10:
			hero_arrow_frames += 1
			if hero_arrow_frames == 10:
				hero_moved = hero_arrow_start.distance_to(hero_arrow.global_position) > 5.0
		if is_instance_valid(hero_target) and hero_target.health < hero_target_health:
			hero_damaged = true

		if tower_moved and tower_damaged and hero_moved and hero_damaged:
			break

	_expect(is_instance_valid(tower_arrow) or tower_moved, "Kurulan Okçu Kulesi kendiliğinden ateş etmeli")
	_expect(tower_cooldown_reset, "Otomatik kule atışı cooldown değerini yenilemeli")
	_expect(tower_moved, "Otomatik kule oku en az 10 gerçek framede ilerlemeli")
	_expect(tower_damaged, "Otomatik kule oku gerçek düşmanın canını azaltmalı")
	_expect(hero_moved, "Ana okçunun otomatik oku en az 10 gerçek framede ilerlemeli")
	_expect(hero_damaged, "Ana okçunun otomatik oku gerçek düşmanın canını azaltmalı")
	_expect(
		tower.projectile_parent == game.projectiles
		and game.archer.projectile_parent == game.projectiles
		and game.projectiles.get_parent() == game,
		"ShooterUnit projectile parent bağlantıları açık ve güvenli olmalı"
	)
	_expect(
		game.projectiles.z_index == 2000
		and game.projectiles.process_mode != Node.PROCESS_MODE_DISABLED,
		"Projectiles container görünür ve aktif dünya katmanında olmalı"
	)
	_expect(
		tower.build_tween != tower.fire_tween,
		"Build ve fire Tween referansları birbirinden bağımsız olmalı"
	)
	game.queue_free()
	await process_frame


func _verify_projectile(
	game: Node,
	shooter: ShooterUnit,
	projectile: Node2D,
	enemy: PathEnemy,
	expect_heavy: bool,
	label: String
) -> void:
	_expect(is_instance_valid(projectile), "%s gerçek combat akışında mermi üretmeli" % label)
	if not is_instance_valid(projectile):
		return
	var start_position: Vector2 = projectile.global_position
	_expect(
		start_position.is_equal_approx(shooter.muzzle.global_position),
		"%s mermisi gerçek Muzzle.global_position konumundan çıkmalı" % label
	)
	_expect(
		projectile.get_parent() == game.projectiles
		and projectile.get_parent() != shooter
		and projectile.get_parent() != shooter.turret_head
		and projectile.get_parent() != shooter.static_base,
		"%s mermisi aktif Projectiles container altında olmalı" % label
	)
	_expect(
		projectile.is_processing()
		and projectile.speed > 0.0
		and projectile.target == enemy,
		"%s mermisinin process, hız ve hedef durumu geçerli olmalı" % label
	)
	_expect(projectile.is_heavy == expect_heavy, "%s ağır mermi ayarı doğru olmalı" % label)
	var expected_angle: float = start_position.direction_to(enemy.global_position).angle()
	_expect(
		is_equal_approx(projectile.global_rotation, expected_angle),
		"%s mermisinin başlangıç yönü hedefle uyumlu olmalı" % label
	)
	for frame in range(10):
		await process_frame
	var moved_position: Vector2 = projectile.global_position if is_instance_valid(projectile) else start_position
	_expect(
		start_position.distance_to(moved_position) > 5.0,
		"%s mermisi 10 gerçek process frame içinde ilerlemeli" % label
	)
	if is_instance_valid(projectile):
		var independent_position: Vector2 = projectile.global_position
		shooter.turret_head.rotation += 0.7
		shooter.position += Vector2(25.0, 15.0)
		_expect(
			projectile.global_position.is_equal_approx(independent_position),
			"%s uçuşu shooter dönüşümünden bağımsız olmalı" % label
		)


func _test_invalid_target_cleanup(game: Node) -> void:
	var enemy: PathEnemy = _spawn_stationary_enemy(
		game,
		game.archer.global_position + Vector2(280.0, 0.0)
	)
	game.archer._shoot(enemy)
	var arrow: Node2D = game.archer.last_projectile
	enemy.queue_free()
	await process_frame
	await process_frame
	_expect(
		not is_instance_valid(arrow),
		"Hedef sahneden ayrıldığında uçan mermi güvenli temizlenmeli"
	)


func _spawn_stationary_enemy(game: Node, world_position: Vector2) -> PathEnemy:
	var enemy: PathEnemy = game._spawn_enemy(WaveManager.BOSS_ID)
	enemy.set_process(false)
	enemy.global_position = world_position
	return enemy


func _wait_for_projectile_cleanup(projectile: Node2D, frame_limit: int) -> void:
	for frame in range(frame_limit):
		if not is_instance_valid(projectile):
			return
		await process_frame


func _build_spot_screen_position(game: Node, index: int) -> Vector2:
	var world_position: Vector2 = game.tower_build_manager.to_global(game.build_spots[index])
	return game.get_viewport().get_canvas_transform() * world_position


func _dispatch_mouse_click(position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.position = position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)


func _dispatch_touch(position: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.position = position
	press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventScreenTouch
	release.pressed = false
	root.push_input(release, true)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
