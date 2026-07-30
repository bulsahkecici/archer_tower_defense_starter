extends SceneTree

var failures: int = 0
var save_manager: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	save_manager = root.get_node("SaveManager")
	save_manager.set_save_path("/private/tmp/archer_stage10_save.json")
	save_manager.reset_defaults()

	var tutorial_game: Node = await _create_game(false)
	_expect(
		tutorial_game.tutorial_active
		and is_instance_valid(tutorial_game.ui_controller.tutorial_overlay),
		"Öğretici ilk açılışta başlamalı"
	)
	tutorial_game._complete_tutorial()
	await process_frame
	_expect(
		not tutorial_game.tutorial_active
		and not is_instance_valid(tutorial_game.ui_controller.tutorial_overlay),
		"Öğretici tamamlanınca kapanmalı"
	)
	_expect(
		save_manager.tutorial_completed,
		"Öğretici tamamlanma durumu SaveManager ile korunmalı"
	)
	tutorial_game.queue_free()
	await process_frame

	var game: Node = await _create_game(false)
	game.set_process(false)
	game.archer.stop_combat()
	_expect(
		not game.tutorial_active and is_instance_valid(game.ui_controller.wave_preview_panel),
		"Tamamlanan öğretici yeniden başlamamalı"
	)

	var summary: Dictionary = game.wave_manager.get_wave_summary(5)
	_expect(
		summary.normal == 8
		and summary.fast == 4
		and summary.boss == 1
		and summary.total == 13,
		"Dalga ön izlemesi WaveManager kompozisyonunu doğru göstermeli"
	)

	var first_wave: int = game.wave
	game.confirm_wave_preview_for_test()
	game.confirm_wave_preview_for_test()
	await process_frame
	_expect(
		game.wave == first_wave
		and game.wave_manager.current_wave == first_wave
		and game.wave_manager.state == WaveManager.WaveState.SPAWNING,
		"Hazırım düğmesi dalgayı yalnızca bir kez başlatmalı"
	)
	await _test_countdown_start()

	game.economy.add_gold(300)
	game._open_tower_selection(0)
	await process_frame
	game.tower_selection_panel.preview_tower(ShooterUnit.TowerType.BOMB)
	await process_frame
	var indicator: TowerRangeIndicator = game.tower_build_manager.range_indicator
	var bomb_data: TowerData = TowerData.create_bomb()
	_expect(
		is_instance_valid(indicator)
		and is_equal_approx(indicator.radius, bomb_data.get_attack_range(1)),
		"Kule menzil ön izlemesi gerçek TowerData yarıçapını kullanmalı"
	)
	_expect(
		game.tower_selection_panel.bomb_data.get_role_summary()
			== bomb_data.get_role_summary(),
		"Kule rol açıklaması TowerData ile uyumlu olmalı"
	)
	game._on_tower_selected(ShooterUnit.TowerType.ARCHER)
	await process_frame
	var tower: ShooterUnit = game.towers[0] as ShooterUnit
	game.tower_build_manager.open_tower_upgrade(0)
	await process_frame
	var old_range: float = tower.attack_range
	_expect(
		is_equal_approx(indicator.radius, old_range)
		and indicator.next_radius > indicator.radius,
		"Kurulu kule ve sonraki seviye menzilleri gösterilmeli"
	)
	game.tower_build_manager._upgrade_selected_tower()
	await process_frame
	_expect(
		tower.attack_range > old_range
		and is_equal_approx(indicator.radius, tower.attack_range),
		"Yükseltme sonrası menzil göstergesi güncellenmeli"
	)
	_expect(
		game.find_children("TowerRangeIndicator", "", true, false).size() == 1,
		"Aynı anda yalnızca bir menzil göstergesi bulunmalı"
	)
	game._close_tower_panel()
	await process_frame

	var armored: PathEnemy = game._spawn_enemy(WaveManager.ARMORED_ID)
	armored.set_process(false)
	var normal: PathEnemy = game._spawn_enemy(WaveManager.NORMAL_ID)
	normal.set_process(false)
	_expect(
		armored.has_status_icon(&"armor") and not normal.has_status_icon(&"armor"),
		"Zırh simgesi yalnızca zırhlı düşmanda görünmeli"
	)
	normal.apply_slow(0.25, 0.2)
	_expect(normal.has_status_icon(&"slow"), "Slow simgesi etki sırasında görünmeli")
	normal.set_process(true)
	normal._process(0.3)
	normal.set_process(false)
	_expect(not normal.has_status_icon(&"slow"), "Slow simgesi süre sonunda kapanmalı")

	game._set_game_speed(2.0)
	_expect(
		is_equal_approx(Engine.time_scale, 2.0)
		and game.ui_controller.speed_button.text == "2×",
		"Oyun hızı 1× ve 2× arasında geçebilmeli"
	)
	game._pause_game()
	_expect(
		paused and is_equal_approx(Engine.time_scale, 1.0),
		"Pause hız sistemini güvenli yönetmeli"
	)
	game._resume_game()
	_expect(
		not paused and is_equal_approx(Engine.time_scale, 2.0),
		"Pause kapanınca seçilen hız geri gelmeli"
	)
	game._set_game_speed(1.0)

	var damage_count_before: int = game.damage_number_spawn_count
	normal.take_damage(3.0)
	await process_frame
	_expect(
		game.damage_number_spawn_count == damage_count_before + 1,
		"Hasar sayısı hasar olayıyla oluşturulmalı"
	)
	_expect(
		game.damage_number_spawn_count == damage_count_before + 1,
		"Aynı hasar olayı iki hasar sayısı oluşturmamalı"
	)
	await create_timer(0.9).timeout
	var remaining_damage_numbers: int = 0
	for effect in get_nodes_in_group("visual_effects"):
		if (
			is_instance_valid(effect)
			and effect.get("effect_type") == VisualEffect.EffectType.DAMAGE_NUMBER
		):
			remaining_damage_numbers += 1
	_expect(
		remaining_damage_numbers == 0,
		"Hasar sayıları kısa ömür sonunda temizlenmeli"
	)

	var boss: PathEnemy = game._spawn_enemy(WaveManager.BOSS_ID)
	boss.set_process(false)
	await process_frame
	_expect(
		game.ui_controller.boss_bar_container.visible,
		"Boss can barı boss spawn olduğunda açılmalı"
	)
	boss.resolve_at_base()
	await process_frame
	await process_frame
	_expect(
		not game.ui_controller.boss_bar_container.visible,
		"Boss can barı boss çözülünce kapanmalı"
	)

	game.ui_controller.update_ability_cooldown(18.0)
	_expect(
		"18 sn" in game.ui_controller.ability_button.text
		and game.ui_controller.ability_button.disabled,
		"Ok Yağmuru cooldown metni gerçek kalan süreyi göstermeli"
	)
	game.ui_controller.update_ability_cooldown(0.0)
	_expect(
		"HAZIR" in game.ui_controller.ability_button.text
		and not game.ui_controller.ability_button.disabled,
		"Ok Yağmuru hazır durumu açık görünmeli"
	)

	Engine.time_scale = 2.0
	var menu := MainMenu.new()
	root.add_child(menu)
	await process_frame
	_expect(
		is_equal_approx(Engine.time_scale, 1.0),
		"Ana menüye dönünce time_scale 1.0 olmalı"
	)
	menu.queue_free()
	game.queue_free()
	await process_frame

	if failures == 0:
		print("STAGE10_TEST_PASS")
	else:
		push_error("STAGE10_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _create_game(complete_tutorial: bool) -> Node:
	if complete_tutorial:
		save_manager.tutorial_completed = true
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	return game


func _test_countdown_start() -> void:
	var panel := WavePreviewPanel.new()
	root.add_child(panel)
	panel.setup(
		{
			"wave": 2,
			"normal": 8,
			"fast": 2,
			"armored": 0,
			"swarm": 0,
			"boss": 0,
			"has_boss": false,
			"total": 10
		},
		10,
		3.0
	)
	var ready_count: Array[int] = [0]
	panel.ready_pressed.connect(func() -> void: ready_count[0] += 1)
	panel.advance_countdown_for_test(3.1)
	panel.advance_countdown_for_test(3.1)
	await process_frame
	_expect(ready_count[0] == 1, "Geri sayım sonunda dalga yalnızca bir kez başlamalı")
	panel.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
