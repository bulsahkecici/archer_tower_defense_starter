extends SceneTree

var failures: int = 0
var save_manager: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	save_manager = root.get_node("SaveManager")
	save_manager.set_save_path("/private/tmp/archers_last_castle_combat_feedback_save.json")
	save_manager.reset_defaults()
	save_manager.tutorial_completed = true
	save_manager.screen_shake_enabled = false
	var game: Node = await _create_game()
	await _test_enemy_feedback(game)
	await _test_ability_icon(game)
	await _test_arrow_rain_sync_and_cleanup(game)
	await _test_stress_cleanup(game)
	game.queue_free()
	await process_frame
	if failures == 0:
		print("PLAYTEST_COMBAT_FEEDBACK_TEST_PASS")
	else:
		push_error("PLAYTEST_COMBAT_FEEDBACK_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _create_game() -> Node:
	save_manager.selected_game_mode = &"story"
	var game: Node = load(MenuNavigation.GAME).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	if game.wave_preview_pending:
		game.confirm_wave_preview_for_test()
		await process_frame
	game.set_process(false)
	game.archer.stop_combat()
	return game


func _test_enemy_feedback(game: Node) -> void:
	var enemy: PathEnemy = _spawn_stationary(
		game,
		WaveManager.BOSS_ID,
		Vector2(520.0, 820.0)
	)
	var enemy_source: String = _read_text("res://scripts/enemy.gd")
	_expect(
		not enemy.has_health_bar_visual()
		and "bar_rect" not in enemy_source
		and "health / max_health" not in enemy_source,
		"Normal düşman çizimi sürekli health bar içermemeli"
	)
	var health_before: float = enemy.health
	enemy.take_damage(4.0)
	_expect(
		enemy.health < health_before,
		"Health bar kaldırılırken sayısal enemy health çalışmaya devam etmeli"
	)
	var first_tween: Tween = enemy.damage_tween
	_expect(
		enemy.hit_flash_strength > 0.9
		and first_tween != null
		and first_tween.is_valid(),
		"Hasar vuruşunda beyaz flash Tween başlamalı"
	)
	enemy.take_damage(3.0)
	_expect(
		enemy.damage_tween != null
		and enemy.damage_tween != first_tween
		and enemy.damage_tween.is_valid()
		and enemy.hit_flash_strength > 0.9,
		"Arka arkaya vuruş önceki Tween'i güvenle yenilemeli"
	)
	await create_timer(0.18).timeout
	_expect(
		enemy.hit_flash_strength <= 0.001
		and enemy.scale.is_equal_approx(Vector2.ONE),
		"Hit efekti sonunda düşman normal görünümüne dönmeli"
	)
	enemy.take_damage(1.0)
	enemy.take_damage(99999.0)
	_expect(
		enemy.has_resolved
		and enemy.damage_tween == null
		and enemy.hit_flash_strength <= 0.001,
		"Ölüm sırasında hit Tween ve beyaz flash kalmamalı"
	)
	await create_timer(0.32).timeout


func _test_ability_icon(game: Node) -> void:
	var ui: UIController = game.ui_controller
	ui.set_ability_cooldown_duration(20.0)
	ui.update_ability_cooldown(20.0)
	_expect(
		is_instance_valid(ui.ability_icon)
		and ui.ability_button.disabled
		and ui.ability_icon.ready_fill <= 0.001
		and not ui.ability_icon.is_ready,
		"Ok Yağmuru cooldown'da ikonlu, soluk ve pasif olmalı"
	)
	ui.update_ability_cooldown(10.0)
	_expect(
		is_equal_approx(ui.ability_icon.ready_fill, 0.5),
		"İkon ilerlemesi gerçek remaining/duration değerini takip etmeli"
	)
	ui.update_ability_cooldown(0.0)
	_expect(
		not ui.ability_button.disabled
		and ui.ability_icon.is_ready
		and is_equal_approx(ui.ability_icon.ready_fill, 1.0),
		"Cooldown bitince ikon tamamen dolu ve düğme aktif olmalı"
	)


func _test_arrow_rain_sync_and_cleanup(game: Node) -> void:
	game.ability_cooldown = 0.0
	var enemy: PathEnemy = _spawn_stationary(
		game,
		WaveManager.BOSS_ID,
		Vector2(620.0, 860.0)
	)
	var health_before: float = enemy.health
	var spawn_before: int = game.ability_arrow_spawn_count
	_expect(game._use_arrow_rain(), "Ability geçerli hedefte kullanılabilmeli")
	var arrows: Array[Node] = get_nodes_in_group("ability_arrows")
	_expect(
		not arrows.is_empty()
		and game.ability_arrow_spawn_count > spawn_before,
		"Ability kullanıldığında görsel yağmur okları oluşmalı"
	)
	var first_arrow: ArrowRainProjectile = arrows[0] as ArrowRainProjectile
	var start: Vector2 = first_arrow.global_position
	_expect(start.y < 0.0, "Ok Yağmuru oku dünya görünümünün üstünden doğmalı")
	_expect(
		is_equal_approx(enemy.health, health_before),
		"Hasar ok görseli varmadan önce uygulanmamalı"
	)
	first_arrow._process(0.05)
	_expect(
		first_arrow.global_position.y > start.y,
		"Ok üstten hedefe doğru hareket etmeli"
	)
	await _advance_ability_arrows()
	_expect(
		enemy.health < health_before,
		"Ok Yağmuru hasarı görsel varışla senkron uygulanmalı"
	)
	_expect(
		get_nodes_in_group("ability_arrows").is_empty(),
		"Varış sonrası bütün ability okları temizlenmeli"
	)
	enemy.resolve_defeated()
	await create_timer(0.32).timeout

	game.ability_cooldown = 0.0
	var doomed: PathEnemy = _spawn_stationary(
		game,
		WaveManager.BOSS_ID,
		Vector2(400.0, 760.0)
	)
	_expect(game._use_arrow_rain(), "Hedef kaybı temizleme senaryosu başlatılmalı")
	doomed.resolve_defeated()
	await _advance_ability_arrows()
	_expect(
		get_nodes_in_group("ability_arrows").is_empty(),
		"Hedef ölürse ok hedef konumuna ilerleyip güvenle temizlenmeli"
	)
	await create_timer(0.32).timeout


func _test_stress_cleanup(game: Node) -> void:
	game.ability_cooldown = 0.0
	game.game_over = false
	game.wave_manager.state = WaveManager.WaveState.SPAWNING
	var enemies: Array[PathEnemy] = []
	for index in range(75):
		var enemy: PathEnemy = _spawn_stationary(
			game,
			WaveManager.BOSS_ID,
			Vector2(120.0 + float(index % 10) * 82.0, 600.0 + float(index % 8) * 100.0)
		)
		enemies.append(enemy)
	_expect(game._use_arrow_rain(), "75 düşman stresinde ability kullanılabilmeli")
	_expect(
		get_nodes_in_group("ability_arrows").size() <= 12,
		"Ability aktif ok sayısı performans için 12 ile sınırlı olmalı"
	)
	await _advance_ability_arrows(80)
	_expect(
		get_nodes_in_group("ability_arrows").is_empty(),
		"75 düşman stresinde ability arrow node birikimi olmamalı"
	)
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.has_resolved:
			enemy.resolve_defeated()
	await create_timer(0.4).timeout
	game.world_shake_tween = null
	game.position = Vector2.ZERO
	game._on_bomb_explosion(Vector2(500.0, 900.0), 4)
	_expect(
		game.world_shake_tween == null and game.position == Vector2.ZERO,
		"Ekran sarsıntısı kapalıyken shake oluşmamalı"
	)


func _advance_ability_arrows(max_steps: int = 60) -> void:
	for _step in range(max_steps):
		var arrows: Array[Node] = get_nodes_in_group("ability_arrows")
		if arrows.is_empty():
			return
		for node in arrows:
			if is_instance_valid(node) and not node.is_queued_for_deletion():
				(node as ArrowRainProjectile)._process(0.05)
		await process_frame


func _spawn_stationary(
	game: Node,
	enemy_id: StringName,
	world_position: Vector2
) -> PathEnemy:
	var enemy: PathEnemy = game._spawn_enemy(enemy_id)
	enemy.set_process(false)
	enemy.global_position = world_position
	return enemy


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
