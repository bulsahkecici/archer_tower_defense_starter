extends SceneTree

var failures: int = 0
var save_manager: Node
var achievement_manager: Node
var cosmetic_manager: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	save_manager = root.get_node("SaveManager")
	achievement_manager = root.get_node("AchievementManager")
	cosmetic_manager = root.get_node("CosmeticManager")
	save_manager.set_save_path("/private/tmp/archer_stage12_save.json")
	save_manager.reset_defaults()
	save_manager.tutorial_completed = true
	_expect(
		not save_manager.is_endless_unlocked(),
		"Sonsuz mod beşinci bölüm tamamlanmadan kilitli olmalı"
	)
	save_manager.level_stars["5"] = 3
	_expect(
		save_manager.is_endless_unlocked(),
		"Sonsuz mod beşinci bölüm tamamlanınca açılmalı"
	)

	var endless_waves := WaveManager.new()
	root.add_child(endless_waves)
	await process_frame
	endless_waves.configure_endless(true)
	var composition_25: Array[StringName] = endless_waves.get_wave_composition(25)
	var composition_50: Array[StringName] = endless_waves.get_wave_composition(50)
	var composition_100: Array[StringName] = endless_waves.get_wave_composition(100)
	_expect(
		not composition_25.is_empty()
		and not composition_50.is_empty()
		and not composition_100.is_empty()
		and composition_100.size() <= 71,
		"Sonsuz dalga 25, 50 ve 100 kontrollü kompozisyon üretmeli"
	)
	_expect(
		WaveManager.BOSS_ID in composition_25
		and WaveManager.BOSS_ID in composition_50
		and WaveManager.BOSS_ID in composition_100
		and WaveManager.BOSS_ID not in endless_waves.get_wave_composition(26),
		"Sonsuz modda her 5 dalgada boss gelmeli"
	)
	_expect(
		endless_waves.get_health_multiplier(100) <= 25.0,
		"Yüksek dalga sağlık ölçeği kontrollü üst sınıra sahip olmalı"
	)

	_expect(
		save_manager.update_endless_high_wave(30)
		and not save_manager.update_endless_high_wave(12)
		and save_manager.endless_high_wave == 30,
		"En yüksek sonsuz dalga kaydı düşmemeli"
	)
	var story_stars_before: Dictionary = save_manager.level_stars.duplicate(true)
	save_manager.selected_game_mode = &"endless"
	var game: Node = await _create_game()
	game.set_process(false)
	game.archer.stop_combat()
	_expect(
		game.endless_mode
		and game.total_waves == 0
		and "DALGA" in game.ui_controller.wave_label.text,
		"Sonsuz mod oyun ve HUD durumunu doğru başlatmalı"
	)
	game.wave = 27
	game.enemies_defeated = 83
	game.bosses_defeated = 5
	game.towers_built_count = 7
	game.upgrades_count = 4
	game.arrow_rain_uses = 3
	var summary: Dictionary = game.get_run_summary()
	_expect(
		summary.wave == 27
		and summary.enemies_defeated == 83
		and summary.bosses_defeated == 5
		and summary.towers_built == 7
		and summary.upgrades == 4
		and summary.arrow_rain_uses == 3,
		"Sonsuz koşu özeti doğru istatistikleri göstermeli"
	)
	game._finish_game()
	await process_frame
	_expect(
		save_manager.level_stars == story_stars_before,
		"Sonsuz mod hikâye yıldızlarını değiştirmemeli"
	)

	var builder_before: int = achievement_manager.get_progress(&"master_builder")
	achievement_manager.record_event(&"tower_built", 3)
	_expect(
		achievement_manager.get_progress(&"master_builder") == builder_before + 3,
		"Başarım ilerlemesi oyun olaylarıyla artmalı"
	)
	var notification_before: int = game.ui_controller.achievement_notification_count
	achievement_manager.record_event(&"boss_defeated", 10)
	var boss_notifications: int = game.ui_controller.achievement_notification_count
	achievement_manager.record_event(&"boss_defeated", 10)
	_expect(
		achievement_manager.is_unlocked(&"boss_hunter")
		and boss_notifications == notification_before + 1
		and game.ui_controller.achievement_notification_count == boss_notifications,
		"Başarım yalnızca bir kez açılıp bir kez bildirim göstermeli"
	)
	achievement_manager.record_event(
		&"level_completed",
		1,
		{"level_id": 1, "perfect": true}
	)
	_expect(
		achievement_manager.is_unlocked(&"perfect_victory"),
		"Kusursuz Zafer doğru koşulda açılmalı"
	)
	achievement_manager.record_event(&"bomb_multi_hit", 4)
	var blast_before: bool = achievement_manager.is_unlocked(&"big_blast")
	achievement_manager.record_event(&"bomb_multi_hit", 5)
	_expect(
		not blast_before and achievement_manager.is_unlocked(&"big_blast"),
		"Büyük Patlama tek olayda en az beş hedefi ölçmeli"
	)
	await create_timer(2.4).timeout
	_expect(
		not is_instance_valid(game.ui_controller.achievement_notification),
		"Başarım bildirimi oynanışı durdurmadan temizlenmeli"
	)

	_expect(
		not cosmetic_manager.select_cosmetic(&"gold_arrow"),
		"Kilitli kozmetik seçilememeli"
	)
	_expect(
		cosmetic_manager.select_cosmetic(&"blue_roof"),
		"Açılmış kozmetik seçilebilmeli"
	)
	_expect(
		save_manager.selected_cosmetics["castle_roof"] == "blue_roof"
		and save_manager.to_dictionary().selected_cosmetics["castle_roof"] == "blue_roof",
		"Kozmetik seçimi SaveManager içinde saklanmalı"
	)
	var tower_stats_before: Array[float] = [
		TowerData.create_archer().damage,
		TowerData.create_archer().attack_range,
		TowerData.create_archer().fire_interval
	]
	cosmetic_manager.select_cosmetic(&"green_roof")
	var tower_stats_after: Array[float] = [
		TowerData.create_archer().damage,
		TowerData.create_archer().attack_range,
		TowerData.create_archer().fire_interval
	]
	_expect(
		tower_stats_before == tower_stats_after,
		"Kozmetik seçimi oyun istatistiklerini değiştirmemeli"
	)
	save_manager.selected_cosmetics["arrow_trail"] = "gecersiz"
	cosmetic_manager.validate_selection()
	_expect(
		cosmetic_manager.get_selected(&"arrow_trail") == &"default_arrow",
		"Geçersiz kozmetik kaydı varsayılana dönmeli"
	)

	var achievements_scene: PackedScene = load("res://scenes/achievements.tscn")
	var cosmetics_scene: PackedScene = load("res://scenes/cosmetics.tscn")
	var achievements_menu: AchievementsMenu = achievements_scene.instantiate()
	var cosmetics_menu: CosmeticsMenu = cosmetics_scene.instantiate()
	root.add_child(achievements_menu)
	root.add_child(cosmetics_menu)
	await process_frame
	_expect(
		achievements_menu.rows.size() == 10
		and cosmetics_menu.selection_buttons.size() == 7,
		"Başarım ve kozmetik ekranları açılıp tüm öğeleri göstermeli"
	)
	achievements_menu.queue_free()
	cosmetics_menu.queue_free()
	await process_frame

	game.run_modifier_manager.applied_rewards.append(&"gold")
	game.enemies_defeated = 20
	game._prepare_restart()
	_expect(
		game.run_modifier_manager.applied_rewards.is_empty()
		and game.enemies_defeated == 0
		and game.wave == 0,
		"Restart sonsuz koşu geçici durumlarını temizlemeli"
	)
	_expect(
		composition_100.size() > 0
		and endless_waves.get_wave_balance(100).total_health > 0.0,
		"100 dalga veri üretimi hata vermemeli"
	)
	game.queue_free()
	endless_waves.queue_free()
	await process_frame

	if failures == 0:
		print("STAGE12_TEST_PASS")
	else:
		push_error("STAGE12_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _create_game() -> Node:
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.confirm_wave_preview_for_test()
	await process_frame
	return game


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
