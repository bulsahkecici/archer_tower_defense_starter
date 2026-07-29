extends SceneTree

var failures: int = 0
var temp_save_path: String = "/private/tmp/archer_stage8_save.json"
var save_manager: Node
var audio_manager: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	save_manager = root.get_node("SaveManager")
	audio_manager = root.get_node("AudioManager")
	save_manager.set_save_path(temp_save_path)
	save_manager.reset_defaults()
	save_manager.save_data()
	await _test_scenes_and_levels()
	_test_save_manager()
	await _test_pause_and_victory()
	await _test_settings_and_audio()
	await process_frame
	if failures == 0:
		print("STAGE8_TEST_PASS")
	else:
		push_error("STAGE8_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _test_scenes_and_levels() -> void:
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	var select_scene: PackedScene = load("res://scenes/level_select.tscn")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var settings_scene: PackedScene = load("res://scenes/settings.tscn")
	_expect(menu_scene != null and select_scene != null and game_scene != null and settings_scene != null, "Ana menü, bölüm seçimi, ayarlar ve oyun sahneleri yüklenmeli")
	var menu: MainMenu = menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	_expect(is_instance_valid(menu.start_button), "Ana menü açılmalı")
	menu.queue_free()
	await process_frame
	var selector: LevelSelect = select_scene.instantiate()
	root.add_child(selector)
	await process_frame
	_expect(selector.level_buttons.size() == 5, "Bölüm seçimi beş bölüm göstermeli")
	_expect(not selector.level_buttons[0].disabled, "İlk bölüm başlangıçta açık olmalı")
	_expect(selector.level_buttons[1].disabled, "İkinci bölüm başlangıçta kilitli olmalı")
	_expect(not selector._select_level(2), "Kilitli bölüm oynatılamamalı")
	selector.queue_free()
	await process_frame


func _test_save_manager() -> void:
	var manager := GameSaveManager.new()
	manager.set_save_path(temp_save_path)
	manager.reset_defaults()
	_expect(manager.save_data(), "SaveManager kayıt oluşturmalı")
	manager.complete_level(1, 2)
	_expect(manager.unlocked_level == 2, "Bölüm 1 tamamlanınca bölüm 2 açılmalı")
	_expect(manager.get_level_stars(1) == 2, "Yıldız hesabı kaydedilmeli")
	manager.complete_level(1, 1)
	_expect(manager.get_level_stars(1) == 2, "En yüksek yıldız kaydı düşmemeli")
	var loaded := GameSaveManager.new()
	loaded.set_save_path(temp_save_path)
	_expect(loaded.load_data() and loaded.unlocked_level == 2, "Kayıt yeniden yüklenmeli")
	var corrupt := FileAccess.open(temp_save_path, FileAccess.WRITE)
	corrupt.store_string("{bozuk")
	corrupt = null
	_expect(not loaded.load_data() and loaded.unlocked_level == 1, "Bozuk kayıt oyunu çökertmeden varsayılana dönmeli")
	manager.free()
	loaded.free()


func _test_pause_and_victory() -> void:
	save_manager.reset_defaults()
	save_manager.save_data()
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)
	game.archer.stop_combat()
	game._pause_game()
	_expect(paused and is_instance_valid(game.ui_controller.pause_layer), "Pause oyunu durdurmalı ve UI açık kalmalı")
	game._resume_game()
	_expect(not paused and not is_instance_valid(game.ui_controller.pause_layer), "Devam Et oyunu sürdürmeli")
	game._finish_victory()
	var first_layer: CanvasLayer = game.ui_controller.victory_layer
	game._finish_victory()
	_expect(is_instance_valid(first_layer) and game.ui_controller.victory_layer == first_layer, "Zafer paneli yalnızca bir kez açılmalı")
	_expect(save_manager.unlocked_level >= 2, "Zafer sonraki bölümü açmalı")
	game._finish_game()
	var game_over_layer: CanvasLayer = game.game_over_layer
	game._finish_game()
	_expect(game.game_over_layer == game_over_layer, "Game-over yalnızca bir kez açılmalı")
	game._prepare_restart()
	game.queue_free()
	await process_frame


func _test_settings_and_audio() -> void:
	save_manager.music_volume = 0.35
	save_manager.sfx_volume = 0.55
	save_manager.vibration_enabled = false
	_expect(save_manager.save_data(), "Ayarlar kaydedilmeli")
	audio_manager.set_music_volume(0.35)
	audio_manager.set_sfx_volume(0.55)
	_expect(audio_manager.play_event(&"ui_click"), "Ses dosyası olmadan AudioManager hata vermemeli")
	var settings: SettingsMenu = load("res://scenes/settings.tscn").instantiate()
	root.add_child(settings)
	await process_frame
	_expect(is_equal_approx(settings.music_slider.value, 0.35), "Ayarlar sahnesi kayıtlı müzik seviyesini göstermeli")
	_expect(not settings.vibration_toggle.button_pressed, "Titreşim tercihi ayarlar sahnesine yansımalı")
	settings.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
