extends SceneTree

var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager: Node = root.get_node("SaveManager")
	save_manager.set_save_path("/private/tmp/archer_vertical_slice_towers_save.json")
	save_manager.reset_defaults()
	var scene: PackedScene = load("res://scenes/3d/game/game_3d.tscn")
	var game := scene.instantiate() as Game3D
	game.auto_start_wave = false
	root.add_child(game)
	await process_frame
	await physics_frame

	_expect(game.tower_palette.tower_buttons.size() == 4, "Panel dört 3D kule kartı göstermeli")
	_expect(
		game.tower_palette.cost_labels[TowerData.ARCHER_ID].text == "15"
		and game.tower_palette.cost_labels[TowerData.CROSSBOW_ID].text == "30"
		and game.tower_palette.cost_labels[TowerData.ICE_ID].text == "35"
		and game.tower_palette.cost_labels[TowerData.BOMB_ID].text == "45",
		"Başlangıç kart maliyetleri TowerData ek maliyetlerini kullanmalı"
	)
	_expect(
		not game.tower_palette.tower_buttons[TowerData.ICE_ID].disabled,
		"35 altınla Buz Kulesi seçilebilir olmalı"
	)
	_expect(
		game.tower_palette.tower_buttons[TowerData.BOMB_ID].disabled,
		"45 altınlık Bomba Kulesi başlangıçta pasif olmalı"
	)

	await _click_tower_card(game, TowerData.CROSSBOW_ID)
	_expect(
		game.placement.selected_data.id == TowerData.CROSSBOW_ID,
		"Arbalet kartı gerçek mouse tıklamasıyla seçilmeli"
	)
	await _push_mouse_click(
		game.game_camera.unproject_position(game.map.build_pads[0].global_position)
	)
	var crossbow := game.towers[0] as CrossbowTower3D
	crossbow.target_scan_timer.stop()
	crossbow.attack_timer.stop()
	_expect(is_instance_valid(crossbow), "Arbalet kartı CrossbowTower3D kurmalı")
	_expect(crossbow.tower_data.id == TowerData.CROSSBOW_ID, "Arbalet TowerData değerlerini korumalı")
	_expect(game.economy.gold == 5, "Arbalet toplam 30 altını bir kez harcamalı")

	game.economy.add_gold(200)
	_expect(
		not game.tower_palette.tower_buttons[TowerData.BOMB_ID].disabled,
		"Altın kazanılınca Bomba Kulesi kartı etkinleşmeli"
	)
	await _click_tower_card(game, TowerData.ICE_ID)
	await _push_touch(
		game.game_camera.unproject_position(game.map.build_pads[1].global_position)
	)
	var ice := game.towers[1] as IceTower3D
	ice.target_scan_timer.stop()
	ice.attack_timer.stop()
	_expect(is_instance_valid(ice), "Buz kartı IceTower3D kurmalı")
	_expect(game.economy.gold == 165, "Buz Kulesi ikinci pad üzerinde 40 altın harcamalı")

	await _click_tower_card(game, TowerData.BOMB_ID)
	await _push_mouse_click(
		game.game_camera.unproject_position(game.map.build_pads[2].global_position)
	)
	var bomb := game.towers[2] as BombTower3D
	bomb.target_scan_timer.stop()
	bomb.attack_timer.stop()
	_expect(is_instance_valid(bomb), "Bomba kartı BombTower3D kurmalı")
	_expect(game.economy.gold == 110, "Bomba Kulesi üçüncü pad üzerinde 55 altın harcamalı")

	await _click_tower_card(game, TowerData.ARCHER_ID)
	await _push_touch(
		game.game_camera.unproject_position(game.map.build_pads[3].global_position)
	)
	var archer := game.towers[3] as ArcherTower3D
	archer.target_scan_timer.stop()
	archer.attack_timer.stop()
	_expect(is_instance_valid(archer), "Okçu kartı ArcherTower3D kurmalı")
	_expect(game.economy.gold == 80, "Dördüncü pad Okçu maliyeti 30 olmalı")
	var all_cards_disabled: bool = true
	for button in game.tower_palette.tower_buttons.values():
		if not button.disabled:
			all_cards_disabled = false
	_expect(
		all_cards_disabled,
		"Tüm platformlar dolunca dört kule kartı da pasif olmalı"
	)

	var ice_target: Enemy3D = game.spawn_enemy()
	ice_target.set_process(false)
	var ice_projectile := ice._create_projectile(ice_target) as ArrowProjectile3D
	ice_projectile.set_process(false)
	ice_projectile.global_position = ice_target.global_position + Vector3.UP
	var base_speed: float = ice_target.movement_speed
	ice_projectile._apply_impact_damage()
	_expect(ice_projectile.projectile_style == &"ice", "Buz Kulesi buz mermisi üretmeli")
	_expect(ice_target.health == 24.0, "Buz mermisi TowerData hasarını uygulamalı")
	_expect(
		ice_target.movement_speed < base_speed and ice_target.slow_tint > 0.0,
		"Buz mermisi düşmanı yavaşlatıp mavi görsel durum vermeli"
	)
	ice_target._process(ice.tower_data.slow_duration + 0.01)
	_expect(
		is_equal_approx(ice_target.movement_speed, base_speed),
		"Buz yavaşlatması süresi bitince hareket hızı geri gelmeli"
	)
	ice_projectile.queue_free()
	ice_target.resolve_defeated()
	await process_frame

	var blast_target_a: Enemy3D = game.spawn_enemy()
	var blast_target_b: Enemy3D = game.spawn_enemy()
	var blast_target_far: Enemy3D = game.spawn_enemy()
	for enemy in [blast_target_a, blast_target_b, blast_target_far]:
		enemy.set_process(false)
	blast_target_a.progress = 8.0
	blast_target_b.progress = 8.0
	blast_target_far.progress = 24.0
	var far_health_before: float = blast_target_far.health
	var bomb_projectile := bomb._create_projectile(blast_target_a) as ArrowProjectile3D
	bomb_projectile.set_process(false)
	bomb_projectile.global_position = blast_target_a.global_position + Vector3.UP
	bomb_projectile._apply_impact_damage()
	_expect(bomb_projectile.projectile_style == &"bomb", "Bomba Kulesi bomba modeli üretmeli")
	_expect(
		blast_target_a.has_resolved and blast_target_b.has_resolved,
		"Bomba yakın iki düşmana alan hasarı uygulamalı"
	)
	_expect(
		is_equal_approx(blast_target_far.health, far_health_before),
		"Bomba patlama yarıçapı dışındaki düşmana hasar vermemeli"
	)
	bomb_projectile.queue_free()
	blast_target_far.resolve_defeated()
	await process_frame

	var crossbow_target: Enemy3D = game.spawn_enemy()
	crossbow_target.set_process(false)
	var crossbow_projectile := crossbow._create_projectile(crossbow_target) as ArrowProjectile3D
	crossbow_projectile.set_process(false)
	crossbow_projectile.global_position = crossbow_target.global_position + Vector3.UP
	crossbow_projectile._apply_impact_damage()
	_expect(
		crossbow_projectile.projectile_style == &"crossbow",
		"Arbalet kalın bolt mermisi üretmeli"
	)
	_expect(
		is_equal_approx(crossbow_target.health, 2.0),
		"Arbalet mermisi 28 ağır hasar uygulamalı"
	)
	crossbow_projectile.queue_free()
	crossbow_target.resolve_defeated()
	await process_frame

	game.queue_free()
	await process_frame
	if failures == 0:
		print("VERTICAL_SLICE_3D_TOWERS_TEST_PASS")
		quit(0)
	else:
		push_error("VERTICAL_SLICE_3D_TOWERS_TEST_FAIL: %d" % failures)
		quit(1)


func _click_tower_card(game: Game3D, tower_id: StringName) -> void:
	var button: Button = game.tower_palette.tower_buttons[tower_id]
	await _push_mouse_click(button.get_global_rect().get_center())


func _to_window_position(viewport_position: Vector2) -> Vector2:
	return viewport_position * Vector2(root.size) / root.get_visible_rect().size


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


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		failures += 1
		push_error("FAIL: %s" % message)
