extends SceneTree

var failures: int = 0
var save_manager: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	save_manager = root.get_node("SaveManager")
	save_manager.set_save_path("/private/tmp/archers_last_castle_navigation_save.json")
	save_manager.reset_defaults()
	save_manager.tutorial_completed = true
	await _test_main_menu_routes()
	await _test_pause_state_preservation()
	if failures == 0:
		print("PLAYTEST_NAVIGATION_TEST_PASS")
	else:
		push_error("PLAYTEST_NAVIGATION_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _test_main_menu_routes() -> void:
	await _open_scene(MenuNavigation.MAIN_MENU)
	var menu: MainMenu = current_scene as MainMenu
	var initial_child_count: int = menu.get_child_count()
	menu._build_ui()
	_expect(
		menu.get_child_count() == initial_child_count,
		"Ana menü ikinci kez çağrıldığında çift UI oluşturmamalı"
	)

	menu.level_select_button.pressed.emit()
	await _wait_frames()
	_expect(current_scene is LevelSelect, "Bölüm Seç ekranı açılmalı")
	var level_select: LevelSelect = current_scene as LevelSelect
	var level_child_count: int = level_select.get_child_count()
	level_select._build_ui()
	_expect(
		level_select.get_child_count() == level_child_count,
		"Bölüm seçimi ikinci kez çağrıldığında çift UI oluşturmamalı"
	)
	level_select.back_button.pressed.emit()
	await _wait_frames()
	_expect(current_scene is MainMenu, "Bölüm Seç Geri ana menüye dönmeli")

	menu = current_scene as MainMenu
	menu.about_button.pressed.emit()
	await _wait_frames()
	_expect(current_scene is AboutMenu, "Hakkında ekranı açılmalı")
	var about: AboutMenu = current_scene as AboutMenu
	_expect(
		GameMetadata.GAME_NAME in about.about_label.text
		and GameMetadata.VERSION in about.about_label.text
		and GameMetadata.ENGINE in about.about_label.text,
		"Hakkında merkezi metadata içeriğini göstermeli"
	)
	about.back_button.pressed.emit()
	await _wait_frames()
	_expect(current_scene is MainMenu, "Hakkında Geri ana menüye dönmeli")

	menu = current_scene as MainMenu
	_expect(
		not menu.cosmetics_button.disabled
		and menu.cosmetics_button.mouse_filter == Control.MOUSE_FILTER_STOP,
		"Kozmetikler gerçek input alabilir durumda olmalı"
	)
	await _click_button_with_mouse(menu.cosmetics_button)
	_expect(current_scene is CosmeticsMenu, "Kozmetikler gerçek mouse input ile açılmalı")
	if current_scene is CosmeticsMenu:
		var cosmetics: CosmeticsMenu = current_scene as CosmeticsMenu
		cosmetics.back_button.pressed.emit()
		await _wait_frames()
		_expect(current_scene is MainMenu, "Kozmetikler Geri ana menüye dönmeli")
	else:
		await _open_scene(MenuNavigation.MAIN_MENU)

	menu = current_scene as MainMenu
	menu.settings_button.pressed.emit()
	await _wait_frames()
	_expect(current_scene is SettingsMenu, "Ana menü Ayarlar ekranını açmalı")
	var settings: SettingsMenu = current_scene as SettingsMenu
	settings.back_button.pressed.emit()
	await _wait_frames()
	_expect(
		current_scene is MainMenu
		and not paused
		and is_equal_approx(Engine.time_scale, 1.0),
		"Ana menü Ayarlar Geri ana menüye normal zaman ölçeğiyle dönmeli"
	)


func _test_pause_state_preservation() -> void:
	save_manager.selected_game_mode = &"story"
	await _open_scene(MenuNavigation.GAME, 4)
	var game: Node = current_scene
	if game.wave_preview_pending:
		game.confirm_wave_preview_for_test()
		await _wait_frames()
	game.set_process(false)
	game.archer.stop_combat()
	game.wave = 4
	game.economy.add_gold(57)
	game.base.health = maxi(1, game.base.health - 9)
	game.active_enemy_count = 3
	game.ability_cooldown = 11.5
	game.upgrades_count = 2
	game.run_modifier_manager.arrow_rain_cooldown_reduction = 3.0
	var tower := Node2D.new()
	tower.name = "NavigationStateTower"
	game.add_child(tower)
	game.towers.append(tower)
	var before := _game_state(game)
	var game_instance_id: int = game.get_instance_id()

	game._pause_game()
	await process_frame
	var resume_button := _find_button(game.ui_controller.pause_layer, "Devam Et")
	_expect(
		paused and is_instance_valid(resume_button),
		"Pause menüsünde Devam Et düğmesi görünmeli"
	)
	var settings_button := _find_button(game.ui_controller.pause_layer, "Ayarlar")
	settings_button.pressed.emit()
	await _wait_frames()
	_expect(
		current_scene.get_instance_id() == game_instance_id
		and paused
		and is_instance_valid(game.ui_controller.pause_settings_menu),
		"Pause Ayarlar sahne değiştirmeden overlay açmalı"
	)
	var overlay_settings: SettingsMenu = game.ui_controller.pause_settings_menu
	var duplicate: SettingsMenu = game.ui_controller.show_pause_settings()
	_expect(
		duplicate == overlay_settings,
		"Aynı pause Settings overlay üst üste oluşturulmamalı"
	)
	overlay_settings.back_button.pressed.emit()
	await _wait_frames()
	_expect(
		paused
		and is_instance_valid(game.ui_controller.pause_layer)
		and not is_instance_valid(game.ui_controller.pause_settings_menu),
		"Pause Ayarlar Geri duraklatma menüsüne dönmeli"
	)
	_expect(
		_game_state(game) == before,
		"Ayarlardan dönüşte tüm oyun durumu korunmalı"
	)
	resume_button = _find_button(game.ui_controller.pause_layer, "Devam Et")
	resume_button.pressed.emit()
	await _wait_frames()
	_expect(
		not paused
		and current_scene.get_instance_id() == game_instance_id
		and _game_state(game) == before,
		"Devam Et sahneyi yüklemeden aynı oyun durumunu sürdürmeli"
	)


func _game_state(game: Node) -> Dictionary:
	return {
		"wave": game.wave,
		"gold": game.economy.gold,
		"base_health": game.base.health,
		"tower_count": game.towers.size(),
		"enemy_count": game.active_enemy_count,
		"upgrades": game.upgrades_count,
		"cooldown": game.ability_cooldown,
		"modifier": game.run_modifier_manager.arrow_rain_cooldown_reduction
	}


func _open_scene(path: String, frames: int = 3) -> void:
	var error: Error = MenuNavigation.change_scene(self, path)
	_expect(error == OK, "%s sahnesi yükleme isteğini kabul etmeli" % path)
	await _wait_frames(frames)


func _click_button_with_mouse(button: Button) -> void:
	var ancestor: Node = button.get_parent()
	while ancestor != null and not ancestor is ScrollContainer:
		ancestor = ancestor.get_parent()
	if ancestor is ScrollContainer:
		(ancestor as ScrollContainer).ensure_control_visible(button)
	await process_frame
	var center: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = center
	press.pressed = true
	root.push_input(press, true)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = center
	release.pressed = false
	root.push_input(release, true)
	await _wait_frames()


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text)
		if is_instance_valid(found):
			return found
	return null


func _wait_frames(count: int = 3) -> void:
	for _index in range(count):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
