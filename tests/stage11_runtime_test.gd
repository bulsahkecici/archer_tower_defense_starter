extends SceneTree

var failures: int = 0
var save_manager: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	save_manager = root.get_node("SaveManager")
	save_manager.set_save_path("/private/tmp/archer_stage11_save.json")
	save_manager.reset_defaults()
	save_manager.tutorial_completed = true
	var game: Node = await _create_game()
	game.set_process(false)
	game.archer.stop_combat()

	var synergy := TowerSynergyManager.new()
	game.add_child(synergy)
	var ice: ShooterUnit = _create_tower(game, ShooterUnit.TowerType.ICE, Vector2(300.0, 900.0))
	var bomb: ShooterUnit = _create_tower(game, ShooterUnit.TowerType.BOMB, Vector2(430.0, 900.0))
	var synergy_towers: Array[Node2D] = [ice, bomb]
	synergy.recompute(synergy_towers)
	_expect(
		is_equal_approx(bomb.slowed_target_damage_multiplier, 1.20),
		"Buz + Bomba sinerjisi yavaş hedef hasar bonusu vermeli"
	)

	var target: PathEnemy = game._spawn_enemy(WaveManager.NORMAL_ID)
	target.set_process(false)
	target.global_position = Vector2(520.0, 900.0)
	target.apply_slow(0.25, 2.0)
	var health_before: float = target.health
	var bomb_arrow: Node2D = load("res://scripts/arrow.gd").new()
	game.projectiles.add_child(bomb_arrow)
	bomb_arrow.setup(
		target,
		10.0,
		700.0,
		true,
		0.0,
		0.0,
		80.0,
		false,
		TowerData.BOMB_ID,
		bomb.slowed_target_damage_multiplier
	)
	bomb_arrow._apply_area_damage(target.global_position)
	_expect(
		is_equal_approx(health_before - target.health, 12.0),
		"Yavaşlatılmış düşman Bomba Kulesinden %20 fazla hasar almalı"
	)
	target.resolve_defeated()
	await process_frame
	var plain_target: PathEnemy = game._spawn_enemy(WaveManager.NORMAL_ID)
	plain_target.set_process(false)
	plain_target.global_position = Vector2(520.0, 900.0)
	health_before = plain_target.health
	bomb_arrow = load("res://scripts/arrow.gd").new()
	game.projectiles.add_child(bomb_arrow)
	bomb_arrow.setup(
		plain_target, 10.0, 700.0, true, 0.0, 0.0, 80.0, false,
		TowerData.BOMB_ID, bomb.slowed_target_damage_multiplier
	)
	bomb_arrow._apply_area_damage(plain_target.global_position)
	_expect(
		is_equal_approx(health_before - plain_target.health, 10.0),
		"Slow yokken Buz + Bomba bonusu uygulanmamalı"
	)

	var archer: ShooterUnit = _create_tower(
		game, ShooterUnit.TowerType.ARCHER, Vector2(200.0, 600.0)
	)
	var crossbow: ShooterUnit = _create_tower(
		game, ShooterUnit.TowerType.CROSSBOW, Vector2(360.0, 600.0)
	)
	var archer_base_interval: float = archer.base_fire_interval_stat
	var pair_towers: Array[Node2D] = [archer, crossbow]
	synergy.recompute(pair_towers)
	_expect(
		is_equal_approx(archer.fire_interval, archer_base_interval * 0.92)
		and crossbow.fire_interval < crossbow.base_fire_interval_stat,
		"Okçu + Arbalet saldırı hızı bonusu uygulanmalı"
	)
	pair_towers.erase(crossbow)
	synergy.recompute(pair_towers)
	_expect(
		is_equal_approx(archer.fire_interval, archer_base_interval),
		"Sinerji ortağı satılınca bonus kaldırılmalı"
	)

	ice.level = 3
	ice.apply_level_stats()
	var aura_recipient: ShooterUnit = _create_tower(
		game, ShooterUnit.TowerType.ARCHER, Vector2(340.0, 900.0)
	)
	var second_ice: ShooterUnit = _create_tower(
		game, ShooterUnit.TowerType.ICE, Vector2(380.0, 940.0), 3
	)
	var aura_towers: Array[Node2D] = [ice, second_ice, aura_recipient]
	synergy.recompute(aura_towers)
	_expect(
		is_equal_approx(
			aura_recipient.attack_range,
			aura_recipient.base_range_stat * 1.08
		),
		"Seviye 3 Buz menzil bonusu uygulanmalı"
	)
	_expect(
		aura_recipient.attack_range <= aura_recipient.base_range_stat * 1.081,
		"Aynı tür menzil bonusu kontrolsüz birikmemeli"
	)

	var boss: PathEnemy = game._spawn_enemy(WaveManager.BOSS_ID)
	boss.set_process(false)
	var boss_behavior: BossBehavior = boss.get_children().filter(
		func(child: Node) -> bool: return child is BossBehavior
	)[0] as BossBehavior
	var boss_base_speed: float = boss.base_speed
	boss.take_damage(boss.max_health * 0.55)
	boss.take_damage(1.0)
	_expect(
		boss_behavior.threshold_trigger_count == 1
		and is_equal_approx(boss.base_speed, boss_base_speed * 1.20),
		"Boss %50 can davranışı yalnızca bir kez tetiklenmeli"
	)

	var aura_boss: PathEnemy = _create_manual_enemy(game, WaveManager.BOSS_ID, 140.0)
	var aura_enemy: PathEnemy = _create_manual_enemy(game, WaveManager.NORMAL_ID, 140.0)
	var armor_behavior := BossBehavior.new()
	aura_boss.add_child(armor_behavior)
	armor_behavior.configure(aura_boss, game, 2)
	armor_behavior.apply_armor_aura_once()
	_expect(
		is_equal_approx(aura_enemy.armor_ratio, 0.15),
		"Zırh Lordu yakındaki normal düşmana zırh vermeli"
	)
	armor_behavior.cleanup()
	_expect(
		is_equal_approx(aura_enemy.armor_ratio, aura_enemy.base_armor_ratio),
		"Boss ölünce zırh bonusu temizlenmeli"
	)

	var summon_boss: PathEnemy = _create_manual_enemy(game, WaveManager.BOSS_ID, 240.0)
	var summon_behavior := BossBehavior.new()
	summon_boss.add_child(summon_behavior)
	summon_behavior.configure(summon_boss, game, 4)
	var active_before: int = game.active_enemy_count
	var summoned: int = summon_behavior.trigger_summon()
	_expect(
		summoned == 4 and game.active_enemy_count == active_before + 4,
		"Orman Cadısı çağırma mekaniği doğru düşman sayısını üretmeli"
	)

	var frozen_enemy: PathEnemy = _create_manual_enemy(game, WaveManager.NORMAL_ID, 0.0)
	frozen_enemy.configure_level_mechanic(3)
	frozen_enemy.progress = frozen_enemy.get_parent().curve.get_baked_length() * 0.45
	frozen_enemy._process(0.0)
	_expect(
		is_equal_approx(frozen_enemy.natural_slow_ratio, 0.15),
		"Donmuş Yol doğal %15 slow uygulamalı"
	)
	frozen_enemy.apply_slow(0.25, 1.0)
	_expect(
		is_equal_approx(frozen_enemy.get_effective_slow_ratio(), 0.25),
		"Doğal slow ve Buz slow güvenli birleşmeli"
	)

	var level_wave_manager := WaveManager.new()
	game.add_child(level_wave_manager)
	await process_frame
	level_wave_manager.configure_level(4)
	_expect(
		level_wave_manager.get_wave_composition(4).count(WaveManager.SWARM_ID) >= 4,
		"Kızıl Orman daha yoğun sürü kompozisyonu kullanmalı"
	)

	var choices: Array[Dictionary] = game.run_modifier_manager.get_reward_choices(3)
	var choice_ids: Dictionary[StringName, bool] = {}
	for choice in choices:
		choice_ids[StringName(choice.id)] = true
	_expect(
		choices.size() == 3 and choice_ids.size() == 3,
		"Ödül paneli üç farklı seçenek üretmeli"
	)
	var save_before: Dictionary = save_manager.to_dictionary().duplicate(true)
	game.wave = 3
	_expect(
		game._open_reward_if_due()
		and is_instance_valid(game.ui_controller.reward_panel),
		"Ödül paneli doğru dalgada açılmalı"
	)
	var panel: RewardChoicePanel = game.ui_controller.reward_panel
	var selected_id: StringName = StringName(panel.choices[0].id)
	var first_selection: bool = panel.choose_reward(selected_id)
	var second_selection: bool = panel.choose_reward(selected_id)
	_expect(
		first_selection
		and not second_selection
		and game.run_modifier_manager.apply_count == 1,
		"Yalnızca bir koşu ödülü uygulanmalı"
	)
	_expect(
		save_manager.to_dictionary() == save_before,
		"Koşu ödülü kalıcı save verisini etkilememeli"
	)
	game._prepare_restart()
	_expect(
		game.run_modifier_manager.applied_rewards.is_empty()
		and is_equal_approx(game.run_modifier_manager.archer_damage_multiplier, 1.0),
		"Run modifier restart ile temizlenmeli"
	)
	game.queue_free()
	await process_frame

	save_manager.unlocked_level = 5
	save_manager.last_level = 5
	save_manager.tutorial_completed = true
	var route_game: Node = await _create_game()
	route_game.set_process(false)
	var route_enemy_a: PathEnemy = route_game._spawn_enemy(WaveManager.NORMAL_ID)
	var route_enemy_b: PathEnemy = route_game._spawn_enemy(WaveManager.NORMAL_ID)
	_expect(
		route_game.enemy_paths.size() == 2
		and route_enemy_a.get_parent() != route_enemy_b.get_parent(),
		"Son Kale iki veri tabanlı rota varyasyonunu kullanmalı"
	)
	route_game.queue_free()
	await process_frame

	if failures == 0:
		print("STAGE11_TEST_PASS")
	else:
		push_error("STAGE11_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _create_game() -> Node:
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.confirm_wave_preview_for_test()
	await process_frame
	return game


func _create_tower(
	game: Node,
	type: ShooterUnit.TowerType,
	world_position: Vector2,
	level: int = 1
) -> ShooterUnit:
	var tower := ShooterUnit.new()
	game.add_child(tower)
	tower.set_projectile_parent(game.projectiles)
	tower.global_position = world_position
	tower.setup_tower(type, level)
	tower.set_process(false)
	return tower


func _create_manual_enemy(
	game: Node,
	enemy_id: StringName,
	path_progress: float
) -> PathEnemy:
	var enemy := PathEnemy.new()
	game.enemy_path.add_child(enemy)
	enemy.setup(game.wave_manager.get_enemy_data(enemy_id))
	enemy.progress = path_progress
	enemy.h_offset = 0.0
	enemy.set_process(false)
	return enemy


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
