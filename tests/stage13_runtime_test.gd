extends SceneTree

var failures: int = 0
var save_manager: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	save_manager = root.get_node("SaveManager")
	save_manager.set_save_path("/private/tmp/archer_stage13_save.json")
	save_manager.reset_defaults()
	save_manager.tutorial_completed = true
	var game: Node = await _create_game()
	game.set_process(false)
	game.archer.stop_combat()

	_expect(
		game.ui_controller.wave_label.text == "1 / 10",
		"HUD hikâye modunda dalga/toplam dalga göstermeli"
	)
	game.ui_controller.update_status(27, game.base.health, -1, 0)
	_expect(
		game.ui_controller.wave_label.text == "DALGA 27",
		"Sonsuz mod HUD formatı doğru olmalı"
	)
	game.ui_controller.update_status(1, game.base.health, -1, 10)

	game.economy.add_gold(500)
	game._open_tower_selection(0)
	await process_frame
	game._on_tower_selected(ShooterUnit.TowerType.ARCHER)
	await process_frame
	var archer: ShooterUnit = game.towers[0] as ShooterUnit
	game.tower_build_manager.open_tower_upgrade(0)
	await process_frame
	var panel: TowerUpgradePanel = game.tower_upgrade_panel
	_expect(
		"Hasar:" in panel.next_stats_label.text
		and "Menzil:" in panel.next_stats_label.text
		and "Atış:" in panel.next_stats_label.text
		and "→" in panel.next_stats_label.text,
		"Yükseltme paneli önce ve sonraki değerleri göstermeli"
	)
	_expect(
		panel.sell_button.text == "SAT: +%d ALTIN" % archer.get_sell_refund(),
		"Satış düğmesi gerçek iadeyi göstermeli"
	)
	game._close_tower_panel()
	game._open_tower_selection(1)
	await process_frame
	game._on_tower_selected(ShooterUnit.TowerType.CROSSBOW)
	await process_frame
	var crossbow: ShooterUnit = game.towers[1] as ShooterUnit
	crossbow.global_position = archer.global_position + Vector2(120.0, 0.0)
	game.tower_build_manager.synergy_manager.recompute(game.towers)
	game.tower_build_manager.open_tower_upgrade(0)
	await process_frame
	panel = game.tower_upgrade_panel
	panel.refresh()
	_expect(
		"Okçu + Arbalet" in panel.synergy_label.text,
		"Aktif sinerji yükseltme panelinde görünmeli"
	)
	_expect(
		is_instance_valid(panel.target_mode_selector)
		and panel.target_mode_selector.item_count == 4,
		"Hedefleme modu panelde görünür olmalı"
	)
	game._close_tower_panel()

	game.wave = 8
	game.enemies_defeated = 42
	game.bosses_defeated = 2
	game.towers_built_count = 5
	game.upgrades_count = 3
	game.towers_sold_count = 1
	game.arrow_rain_uses = 2
	var run_summary: Dictionary = game.get_run_summary()
	game.ui_controller.show_game_over(
		game.wave,
		game.economy.total_gold_earned,
		run_summary
	)
	_expect(
		"Dalga: 8" in game.ui_controller.last_summary_text
		and "Düşman: 42" in game.ui_controller.last_summary_text
		and "Yükseltme: 3" in game.ui_controller.last_summary_text
		and "Satış: 1" in game.ui_controller.last_summary_text,
		"Bölüm sonucu özeti doğru koşu sayaçlarını göstermeli"
	)

	var debug_panel: DebugPerformancePanel = game.ui_controller.debug_panel
	debug_panel.set_debug_visible_for_test(true)
	debug_panel._process(0.6)
	_expect(
		debug_panel.visible
		and debug_panel.sample_count == 1
		and "FPS:" in debug_panel.stats_label.text,
		"Debug panel yalnızca debug koşulunda örneklenebilmeli"
	)
	_expect(
		debug_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE
		and debug_panel.stats_label.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"Debug panel input engellememeli"
	)

	var fresh_save := GameSaveManager.new()
	fresh_save.set_save_path("/private/tmp/archer_stage13_fresh_save.json")
	fresh_save.reset_defaults()
	_expect(
		fresh_save.to_dictionary().save_version == 1,
		"Yeni kayıtta save_version 1 bulunmalı"
	)
	var legacy_path: String = "/private/tmp/archer_stage13_legacy_save.json"
	var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({
		"unlocked_level": 4,
		"level_stars": {"1": 3, "2": 2},
		"music_volume": 0.6,
		"sfx_volume": 0.7,
		"vibration_enabled": false,
		"first_launch": false,
		"last_level": 3
	}))
	legacy_file = null
	var migrated := GameSaveManager.new()
	migrated.set_save_path(legacy_path)
	_expect(
		migrated.load_data()
		and migrated.loaded_save_version == 1,
		"Version 0 kayıt version 1’e taşınmalı"
	)
	_expect(
		int(migrated.level_stars.get("1", 0)) == 3
		and int(migrated.level_stars.get("2", 0)) == 2
		and migrated.unlocked_level == 4
		and is_equal_approx(migrated.music_volume, 0.6),
		"Migration yıldızları, bölüm ilerlemesini ve ayarları korumalı"
	)
	var future_path: String = "/private/tmp/archer_stage13_future_save.json"
	var future_file := FileAccess.open(future_path, FileAccess.WRITE)
	future_file.store_string(JSON.stringify({
		"save_version": 99,
		"unlocked_level": 5,
		"level_stars": {"5": 3}
	}))
	future_file = null
	var future_save := GameSaveManager.new()
	future_save.set_save_path(future_path)
	_expect(
		future_save.load_data()
		and future_save.future_version_detected
		and not future_save.save_data()
		and future_save.unlocked_level == 5,
		"Geçersiz gelecek save version güvenli karşılanmalı"
	)

	_expect(
		FileAccess.file_exists("res://docs/final_balance_report.md")
		and "Sonsuz dalga 50" in _read_text("res://docs/final_balance_report.md"),
		"Final denge raporu oluşturulmuş olmalı"
	)
	var workflow_text: String = _read_text("res://.github/workflows/godot-tests.yml")
	_expect(
		"name:" in workflow_text
		and "push:" in workflow_text
		and "pull_request:" in workflow_text
		and "version: 4.7.1" in workflow_text
		and "stage13_runtime_test" in workflow_text
		and "/Applications/Godot.app" not in workflow_text,
		"GitHub workflow repository-root ve platform bağımsız yapı kullanmalı"
	)

	fresh_save.free()
	migrated.free()
	future_save.free()
	game.queue_free()
	await process_frame
	if failures == 0:
		print("STAGE13_TEST_PASS")
	else:
		push_error("STAGE13_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _create_game() -> Node:
	save_manager.selected_game_mode = &"story"
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.confirm_wave_preview_for_test()
	await process_frame
	return game


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
