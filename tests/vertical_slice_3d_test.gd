extends SceneTree

var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager: Node = root.get_node("SaveManager")
	save_manager.set_save_path("/private/tmp/archer_vertical_slice_3d_save.json")
	save_manager.reset_defaults()

	var scene_resource: PackedScene = load("res://scenes/3d/game/game_3d.tscn")
	_expect(scene_resource != null, "3D dikey kesit sahnesi yüklenebilmeli")
	var game := scene_resource.instantiate() as Game3D
	game.auto_start_wave = false
	root.add_child(game)
	await process_frame
	await physics_frame

	_expect(game.game_camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Kamera ortografik olmalı")
	_expect(is_equal_approx(game.game_camera.size, 66.0), "Kamera ölçeği sabit olmalı")
	_expect(game.game_camera.current, "Sabit 3D kamera etkin olmalı")
	_expect(game.enemy_route.curve.point_count == 9, "Tek kıvrımlı 3D rota dokuz kontrol noktası içermeli")
	_expect(game.map.build_pads.size() == 4, "Dört sabit inşa noktası bulunmalı")
	_expect(game.map.build_pads[0].build_cost == 15, "İlk inşa maliyeti görünür veriyle 15 olmalı")
	_expect(
		game.map.build_pads[0].collision_layer == CollisionLayers3D.BUILDABLE,
		"İnşa noktası yalnızca Buildable katmanında olmalı"
	)
	_expect(
		CollisionLayers3D.PLACEMENT_RAY_MASK == CollisionLayers3D.BUILDABLE,
		"Yerleştirme ray'i yalnızca Buildable katmanını sorgulamalı"
	)
	_expect(game.castle.model_root.name == "ModelRoot", "Kale görseli değiştirilebilir ModelRoot altında olmalı")
	_expect(
		game.map.get_node_or_null("NonBuildableTerrain") != null,
		"Harita build edilemeyen arazi çarpışmasına sahip olmalı"
	)

	var viewport_rect: Rect2 = game.get_viewport().get_visible_rect()
	for point in [GreenValleyMap3D.ROUTE_POINTS[0], GreenValleyMap3D.ROUTE_POINTS[-1]]:
		var screen_point: Vector2 = game.game_camera.unproject_position(point)
		_expect(viewport_rect.has_point(screen_point), "Rota girişi ve kale hedefi kamera kadrajında kalmalı")

	var first_pad: BuildPad3D = game.map.build_pads[0]
	var first_pad_screen: Vector2 = game.game_camera.unproject_position(first_pad.global_position)
	await _push_mouse_click(
		game.tower_palette.archer_button.get_global_rect().get_center()
	)
	_expect(game.placement.selected_data != null, "Mobil kule kartı Okçu Kulesi seçimini başlatmalı")
	_expect(
		game.tower_palette.archer_button.button_pressed,
		"Seçilen kule kartı görsel olarak basılı durumda kalmalı"
	)
	_expect(
		first_pad.pad_material.albedo_color.is_equal_approx(Color("73c989")),
		"Seçimden sonra satın alınabilir platformlar yeşil vurgulanmalı"
	)
	_expect(
		game.placement.raycast_build_pad(first_pad_screen) == first_pad,
		"Kamera ray'i ekrandaki inşa noktasını bulmalı"
	)
	var road_screen: Vector2 = game.game_camera.unproject_position(
		GreenValleyMap3D.ROUTE_POINTS[1]
	)
	_expect(
		game.placement.raycast_build_pad(road_screen) == null,
		"Road katmanı geçerli bir inşa hedefi olarak dönmemeli"
	)
	_expect(
		not game.placement.update_ghost_from_screen(road_screen)
		and game.placement.ghost_root.visible,
		"Yol üzerindeki ghost kırmızı/geçersiz durumda gösterilmeli"
	)
	await _push_mouse_click(first_pad_screen)
	_expect(first_pad.occupied, "Mouse girişiyle seçilen noktaya kule kurulmalı")
	_expect(game.economy.gold == 20, "15 altınlık kurulum maliyeti tam bir kez harcanmalı")
	_expect(game.towers.size() == 1, "İlk yerleştirme yalnızca bir kule üretmeli")

	var gold_after_first_build: int = game.economy.gold
	game.placement.select_archer()
	_expect(game.placement.place_on_pad(first_pad) == null, "Dolu inşa noktasına ikinci kule kurulamamalı")
	_expect(game.economy.gold == gold_after_first_build, "Reddedilen kurulum altın harcamamalı")
	game.placement.cancel()

	var second_pad: BuildPad3D = game.map.build_pads[1]
	game.economy.add_gold(20)
	await _push_mouse_click(
		game.tower_palette.archer_button.get_global_rect().get_center()
	)
	await _push_touch(
		game.game_camera.unproject_position(second_pad.global_position)
	)
	_expect(second_pad.occupied, "Dokunmatik girişle kule kurulmalı")
	_expect(game.towers.size() == 2, "Mouse ve dokunmatik kurulumları ayrı kuleler üretmeli")
	var gold_before_unaffordable: int = game.economy.gold
	game.placement.select_archer()
	_expect(
		game.placement.place_on_pad(game.map.build_pads[3]) == null,
		"Yetersiz altınla pahalı inşa noktası reddedilmeli"
	)
	_expect(
		game.economy.gold == gold_before_unaffordable,
		"Yetersiz altın reddi bakiyeyi değiştirmemeli"
	)
	await _push_mouse_click(
		game.tower_palette.cancel_button.get_global_rect().get_center()
	)
	_expect(game.placement.selected_data == null, "Mobil İptal düğmesi yerleştirmeyi temizlemeli")

	for tower in game.towers:
		tower.target_scan_timer.stop()
		tower.attack_timer.stop()
	var tower: ArcherTower3D = game.towers[0]
	_expect(tower.model_root.name == "ModelRoot", "Kule görseli değiştirilebilir ModelRoot altında olmalı")
	_expect(tower.fire_point.name == "FirePoint", "Kule okun çıkacağı FirePoint kancasına sahip olmalı")
	_expect(
		is_instance_valid(tower.range_area) and is_instance_valid(tower.selection_area),
		"Yeniden kullanılabilir Tower3D menzil ve seçim alanlarına sahip olmalı"
	)

	var target: Enemy3D = game.spawn_enemy()
	target.set_process(false)
	target.progress = 7.5
	var trailing_target: Enemy3D = game.spawn_enemy()
	trailing_target.set_process(false)
	trailing_target.progress = 2.0
	await process_frame
	_expect(
		tower._scan_for_target() == target,
		"Okçu Kulesi rotada en ilerideki menzil içi düşmanı seçmeli"
	)
	var health_before_arrow: float = target.health
	_expect(tower._attempt_fire(), "Okçu Kulesi hedefe ok atabilmeli")
	var flat_direction: Vector3 = (
		Vector3(target.global_position.x, tower.rotating_head.global_position.y, target.global_position.z)
		- tower.rotating_head.global_position
	).normalized()
	_expect(
		(-tower.rotating_head.global_basis.z).dot(flat_direction) > 0.98,
		"Yalnızca kulenin RotatingHead bölümü hedefe dönmeli"
	)
	var arrow: ArrowProjectile3D = tower.last_projectile
	_expect(
		arrow.start_position.distance_to(tower.fire_point.global_position) < 0.02,
		"Ok dünya orijininden değil FirePoint konumundan başlamalı"
	)
	for _step in 20:
		if arrow.has_impacted:
			break
		arrow._process(0.08)
	_expect(arrow.has_impacted, "3D ok hedefe ulaşıp tek bir çarpışma çözmeli")
	_expect(target.health < health_before_arrow, "Ok çarpması düşman sağlığını azaltmalı")
	_expect(target.hit_flash > 0.0, "Hasar alan düşmanda okunabilir hit-flash tetiklenmeli")
	var health_after_impact: float = target.health
	arrow._process(0.5)
	_expect(
		is_equal_approx(target.health, health_after_impact),
		"Çarpmış ok aynı hedefe ikinci kez hasar vermemeli"
	)
	await process_frame

	var gold_before_kill: int = game.economy.gold
	target.take_damage(999.0)
	target.take_damage(999.0)
	await process_frame
	_expect(game.economy.gold == gold_before_kill + 3, "Düşman ödülü yalnızca bir kez eklenmeli")
	trailing_target.take_damage(999.0)
	await process_frame
	_expect(game.active_enemies == 0, "Ölen düşmanlar aktif düşman sayısından düşmeli")
	_expect(not tower._attempt_fire(), "Hedefler öldüğünde kule geçersiz hedefi güvenle temizlemeli")

	var castle_health_before: int = game.castle.health
	var runner: Enemy3D = game.spawn_enemy()
	runner.progress = game.enemy_route.curve.get_baked_length()
	runner._process(0.01)
	await process_frame
	_expect(game.castle.health == castle_health_before - 5, "Rotayı tamamlayan düşman kaleye hasar vermeli")
	_expect(game.active_enemies == 0, "Kaleye ulaşan düşman aktif listeden kaldırılmalı")

	var ability_target: Enemy3D = game.spawn_enemy()
	ability_target.set_process(false)
	var projectile_count_before: int = game.projectile_container.get_child_count()
	_expect(game._use_arrow_rain(), "Ok Yağmuru en az bir hedef varken kullanılabilmeli")
	_expect(
		game.projectile_container.get_child_count() > projectile_count_before,
		"Ok Yağmuru 3D ok mermileri üretmeli"
	)
	_expect(
		is_equal_approx(game.ability_cooldown_remaining, Game3D.ABILITY_COOLDOWN),
		"Ok Yağmuru cooldown durumunu başlatmalı"
	)
	ability_target.take_damage(999.0)
	await process_frame
	for projectile in game.projectile_container.get_children():
		projectile.queue_free()
	await process_frame

	var pause_runner: Enemy3D = game.spawn_enemy()
	pause_runner.progress = 2.0
	var snapshot_before_pause: Dictionary = game.get_state_snapshot()
	game._pause_game()
	_expect(paused, "Duraklat düğmesi SceneTree'yi duraklatmalı")
	_expect(is_instance_valid(game.ui_controller.pause_layer), "Duraklatma katmanı açılmalı")
	var paused_progress: float = pause_runner.progress
	await process_frame
	await process_frame
	await process_frame
	_expect(
		is_equal_approx(pause_runner.progress, paused_progress),
		"Duraklatma sırasında 3D düşman hareketi tamamen durmalı"
	)
	var settings_menu: SettingsMenu = game.ui_controller.show_pause_settings()
	_expect(is_instance_valid(settings_menu), "Ayarlar duraklatma ekranının üstünde açılmalı")
	_expect(
		game.get_state_snapshot().gold == snapshot_before_pause.gold
		and game.get_state_snapshot().castle_health == snapshot_before_pause.castle_health
		and game.get_state_snapshot().wave == snapshot_before_pause.wave
		and game.get_state_snapshot().active_enemies == snapshot_before_pause.active_enemies
		and game.get_state_snapshot().towers == snapshot_before_pause.towers,
		"Ayarlar açılıp kapanırken altın/kale/dalga/düşman/kule durumu korunmalı"
	)
	game.ui_controller.hide_pause_settings()
	_expect(
		is_instance_valid(game.ui_controller.pause_layer),
		"Ayarlardan geri dönünce aynı duraklatma menüsü açık kalmalı"
	)
	game._resume_game()
	_expect(not paused, "Devam et oyunun duraklatmasını kaldırmalı")
	pause_runner.take_damage(999.0)
	await process_frame

	_expect(game.start_vertical_slice_wave(), "Tek dikey kesit dalgası başlatılabilmeli")
	var normal_enemies_only: bool = true
	for enemy_id in game.wave_manager.spawn_queue:
		if enemy_id != WaveManager.NORMAL_ID:
			normal_enemies_only = false
	_expect(
		normal_enemies_only,
		"İlk 3D dikey kesit dalgası yalnızca tek normal düşman türü içermeli"
	)
	game.wave_manager.spawn_queue.clear()
	game.wave_manager.state = WaveManager.WaveState.ACTIVE
	game.active_enemies = 0
	_expect(game._check_wave_completion(), "Kuyruk ve aktif düşmanlar bitince zafer açılmalı")
	_expect(game.victory_shown, "Zafer durumu yalnızca tamamlanmış dalgada görünmeli")

	game.queue_free()
	await process_frame
	await process_frame

	var defeat_game := scene_resource.instantiate() as Game3D
	defeat_game.auto_start_wave = false
	root.add_child(defeat_game)
	await process_frame
	defeat_game.castle.take_damage(defeat_game.castle.max_health)
	await process_frame
	_expect(defeat_game.game_over, "Kale sağlığı sıfır olduğunda yenilgi durumu açılmalı")
	_expect(
		defeat_game.wave_manager.state == WaveManager.WaveState.GAME_OVER,
		"Yenilgi WaveManager durumunu GAME_OVER yapmalı"
	)
	defeat_game.queue_free()
	await process_frame

	if failures == 0:
		print("VERTICAL_SLICE_3D_TEST_PASS")
		quit(0)
	else:
		push_error("VERTICAL_SLICE_3D_TEST_FAIL: %d" % failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		failures += 1
		push_error("FAIL: %s" % message)


func _to_window_position(viewport_position: Vector2) -> Vector2:
	return (
		viewport_position
		* Vector2(root.size)
		/ root.get_visible_rect().size
	)


func _push_mouse_click(viewport_position: Vector2) -> void:
	var window_position: Vector2 = _to_window_position(viewport_position)
	var motion := InputEventMouseMotion.new()
	motion.position = window_position
	root.push_input(motion)
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = window_position
	press.pressed = true
	root.push_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = window_position
	release.pressed = false
	root.push_input(release)
	await process_frame


func _push_touch(viewport_position: Vector2) -> void:
	var window_position: Vector2 = _to_window_position(viewport_position)
	var press := InputEventScreenTouch.new()
	press.position = window_position
	press.pressed = true
	root.push_input(press)
	var release := InputEventScreenTouch.new()
	release.position = window_position
	release.pressed = false
	root.push_input(release)
	await process_frame
