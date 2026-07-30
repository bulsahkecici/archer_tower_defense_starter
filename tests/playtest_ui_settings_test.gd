extends SceneTree

var failures: int = 0
var save_manager: Node
var audio_manager: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	save_manager = root.get_node("SaveManager")
	audio_manager = root.get_node("AudioManager")
	save_manager.set_save_path("/private/tmp/archers_last_castle_ui_settings_save.json")
	save_manager.reset_defaults()
	save_manager.tutorial_completed = true
	await _test_game_name()
	await _test_responsive_hud()
	await _test_tower_cards_and_guide()
	await _test_settings_behavior()
	await _test_pause_guide_and_feedback()
	if failures == 0:
		print("PLAYTEST_UI_SETTINGS_TEST_PASS")
	else:
		push_error("PLAYTEST_UI_SETTINGS_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _test_game_name() -> void:
	_expect(
		String(ProjectSettings.get_setting("application/config/name")) == GameMetadata.GAME_NAME,
		"Proje metadata yeni oyun adını kullanmalı"
	)
	var menu: MainMenu = load(MenuNavigation.MAIN_MENU).instantiate()
	root.add_child(menu)
	await process_frame
	var visible_text: String = _collect_label_and_button_text(menu)
	_expect(
		GameMetadata.GAME_NAME.to_upper() in visible_text,
		"Ana menü yeni oyun adını göstermeli"
	)
	menu.queue_free()
	await process_frame
	var visible_sources: Array[String] = [
		_read_text("res://README.md"),
		_read_text("res://docs/app_store_description_tr.md"),
		_read_text("res://docs/app_store_description_en.md"),
		_read_text("res://scripts/game_metadata.gd")
	]
	var old_name_found: bool = false
	for source_text in visible_sources:
		old_name_found = old_name_found or (
			"Özgün Godot Kule Savunması" in source_text
			or "Özgün Godot kule savunması" in source_text
			or "Archer Tower Defense" in source_text
		)
	_expect(
		not old_name_found,
		"Eski görünür oyun adı metadata ve yayın metinlerinde kalmamalı"
	)


func _test_responsive_hud() -> void:
	var test_sizes: Array[Vector2i] = [
		Vector2i(720, 1280),
		Vector2i(1080, 1920),
		Vector2i(1179, 2556),
		Vector2i(1536, 2048)
	]
	for test_size in test_sizes:
		var viewport := SubViewport.new()
		viewport.size = test_size
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var host := Node.new()
		viewport.add_child(host)
		var ui := UIController.new()
		host.add_child(ui)
		ui.setup()
		ui.update_gold(250, false)
		ui.update_status(3, 91, 4, 10)
		await process_frame
		await process_frame
		var speed_rect: Rect2 = ui.speed_button.get_global_rect()
		var base_rect: Rect2 = ui.base_label.get_parent().get_global_rect()
		_expect(
			not speed_rect.intersects(base_rect),
			"%dx%d HUD hız ve kale alanları çakışmamalı" % [test_size.x, test_size.y]
		)
		_expect(
			ui.base_label.visible
			and base_rect.position.x >= 0.0
			and base_rect.end.x <= float(test_size.x) + 0.5,
			"%dx%d kale canı görünür viewport içinde kalmalı" % [test_size.x, test_size.y]
		)
		_expect(
			ui.primary_stats_row.get_global_rect().end.x <= float(test_size.x) + 0.5
			and ui.action_buttons_row.get_global_rect().end.x <= float(test_size.x) + 0.5,
			"%dx%d container HUD yatay taşmamalı" % [test_size.x, test_size.y]
		)
		_expect(
			ui.gold_label.text == "250"
			and is_instance_valid(ui.gold_icon)
			and "Altın" not in ui.gold_label.text
			and "●" not in ui.gold_label.text,
			"HUD altını çizilen simge ve yalnızca sayı ile göstermeli"
		)
		viewport.queue_free()
		await process_frame


func _test_tower_cards_and_guide() -> void:
	var economy := EconomyManager.new()
	root.add_child(economy)
	economy.setup(500)
	var panel := TowerSelectionPanel.new()
	root.add_child(panel)
	panel.setup(15, economy)
	await process_frame
	for button in [
		panel.archer_button,
		panel.crossbow_button,
		panel.ice_button,
		panel.bomb_button
	]:
		var content: VBoxContainer = button.get_node("Content") as VBoxContainer
		var card_text: String = _collect_label_and_button_text(content)
		_expect(
			content.get_child_count() == 3
			and content.has_node("Icon")
			and content.has_node("CostRow/Cost")
			and "Hasar" not in card_text
			and "Menzil" not in card_text
			and "Atış" not in card_text
			and "Güçlü" not in card_text,
			"Kule kartı yalnız ad, ikon ve maliyet içermeli"
		)
	panel.queue_free()
	economy.queue_free()
	var guide: TowerGuide = load(MenuNavigation.TOWER_GUIDE).instantiate()
	root.add_child(guide)
	await process_frame
	var catalog: Array[TowerData] = TowerData.create_catalog()
	_expect(guide.guide_texts.size() == catalog.size(), "Kule Rehberi tüm kuleleri göstermeli")
	for data in catalog:
		var guide_text: String = String(guide.guide_texts.get(data.id, ""))
		_expect(
			data.display_name in guide_text
			and ("Hasar %.1f" % data.get_damage(1)) in guide_text
			and ("Menzil %.0f" % data.get_attack_range(3)) in guide_text
			and data.special_effect in guide_text
			and data.strong_against in guide_text
			and data.weak_against in guide_text,
			"Kule Rehberi %s için TowerData ve seviye değerlerini kullanmalı"
			% data.display_name
		)
	guide.queue_free()
	await process_frame


func _test_settings_behavior() -> void:
	var settings: SettingsMenu = load(MenuNavigation.SETTINGS).instantiate()
	root.add_child(settings)
	await process_frame
	for row in [
		settings.music_row,
		settings.sfx_row,
		settings.vibration_toggle,
		settings.screen_shake_toggle
	]:
		_expect(
			(row as Control).custom_minimum_size.y >= 96.0,
			"Ayar satırı mobil için en az 96 px tıklama alanı sağlamalı"
		)
	settings._on_music_changed(0.0)
	var music_bus: int = AudioServer.get_bus_index("Music")
	_expect(
		music_bus >= 0 and AudioServer.is_bus_mute(music_bus),
		"Müzik sıfırda gerçek Music bus mute olmalı"
	)
	settings._on_music_changed(0.4)
	_expect(
		not AudioServer.is_bus_mute(music_bus)
		and is_equal_approx(
			AudioServer.get_bus_volume_db(music_bus),
			linear_to_db(0.4)
		),
		"Müzik seviyesi gerçek Music bus değerini değiştirmeli"
	)
	settings._on_sfx_changed(0.25)
	var sfx_bus: int = AudioServer.get_bus_index("SFX")
	_expect(
		sfx_bus >= 0
		and not AudioServer.is_bus_mute(sfx_bus)
		and is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), linear_to_db(0.25)),
		"Efekt seviyesi gerçek SFX bus değerini değiştirmeli"
	)
	settings._on_vibration_toggled(false)
	var haptic_before: int = save_manager.haptic_request_count
	_expect(
		not save_manager.request_haptic()
		and save_manager.haptic_request_count == haptic_before,
		"Titreşim kapalıyken haptic çağrısı engellenmeli"
	)
	settings._on_screen_shake_toggled(false)
	settings.queue_free()
	await process_frame
	var reloaded := GameSaveManager.new()
	reloaded.set_save_path(save_manager.save_path)
	_expect(
		reloaded.load_data()
		and is_equal_approx(reloaded.music_volume, 0.4)
		and is_equal_approx(reloaded.sfx_volume, 0.25)
		and not reloaded.vibration_enabled
		and not reloaded.screen_shake_enabled,
		"Ayarlar save/reload sonrasında korunmalı"
	)
	var invalid_path := "/private/tmp/archers_last_castle_invalid_settings.json"
	var invalid_file := FileAccess.open(invalid_path, FileAccess.WRITE)
	invalid_file.store_string(JSON.stringify({
		"save_version": 1,
		"music_volume": "bozuk",
		"sfx_volume": [],
		"vibration_enabled": "evet",
		"screen_shake_enabled": 7
	}))
	invalid_file = null
	var invalid := GameSaveManager.new()
	invalid.set_save_path(invalid_path)
	_expect(
		invalid.load_data()
		and is_equal_approx(invalid.music_volume, 0.8)
		and is_equal_approx(invalid.sfx_volume, 0.9)
		and invalid.vibration_enabled
		and invalid.screen_shake_enabled,
		"Geçersiz ayar kayıtları güvenli varsayılanlara dönmeli"
	)
	reloaded.free()
	invalid.free()


func _test_pause_guide_and_feedback() -> void:
	save_manager.selected_game_mode = &"story"
	var game: Node = load(MenuNavigation.GAME).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)
	game.archer.stop_combat()
	game.wave = 5
	game.economy.add_gold(40)
	game.ability_cooldown = 8.0
	var state_before := {
		"wave": game.wave,
		"gold": game.economy.gold,
		"health": game.base.health,
		"cooldown": game.ability_cooldown
	}
	game._pause_game()
	var guide: TowerGuide = game.ui_controller.show_pause_guide()
	await process_frame
	_expect(
		paused and is_instance_valid(guide) and guide.embedded_mode,
		"Pause Kule Rehberi oyun sahnesi üzerinde overlay açmalı"
	)
	guide.back_button.pressed.emit()
	await process_frame
	_expect(
		paused
		and not is_instance_valid(game.ui_controller.pause_guide)
		and state_before == {
			"wave": game.wave,
			"gold": game.economy.gold,
			"health": game.base.health,
			"cooldown": game.ability_cooldown
		},
		"Kule Rehberi Geri aynı pause ve oyun durumunu korumalı"
	)
	game.ui_controller.set_message("Bomba Kulesi seviye 2 oldu!")
	var message_style: StyleBoxFlat = (
		game.ui_controller.message_panel.get_theme_stylebox("panel") as StyleBoxFlat
	)
	_expect(
		is_instance_valid(message_style)
		and message_style.bg_color.a >= 0.85
		and message_style.bg_color.get_luminance() < 0.2
		and game.ui_controller.message_label.get_theme_constant("outline_size") >= 3,
		"Kule seviye bildirimi koyu panel ve outline ile okunabilir olmalı"
	)
	game._resume_game()
	game.world_shake_tween = null
	game.position = Vector2.ZERO
	game._on_bomb_explosion(Vector2(400.0, 600.0), 3)
	_expect(
		game.world_shake_tween == null and game.position == Vector2.ZERO,
		"Sarsıntı kapalıyken bomba world shake oluşturmamalı"
	)
	game.queue_free()
	await process_frame


func _collect_label_and_button_text(node: Node) -> String:
	var texts: Array[String] = []
	if node is Label:
		texts.append((node as Label).text)
	elif node is Button:
		texts.append((node as Button).text)
	for child in node.get_children():
		texts.append(_collect_label_and_button_text(child))
	return "\n".join(texts)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
