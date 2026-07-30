extends SceneTree

var failures: int = 0
var save_manager: Node
var audio_manager: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	save_manager = root.get_node("SaveManager")
	audio_manager = root.get_node("AudioManager")
	save_manager.set_save_path("/private/tmp/archer_stage9_save.json")
	save_manager.reset_defaults()
	save_manager.tutorial_completed = true
	save_manager.save_data()
	_test_export_and_assets()
	_test_safe_area_fallbacks()
	var game: Node = await _test_scenes_and_menu_transition()
	if is_instance_valid(game):
		await _test_runtime_safety_and_stress(game)
	await process_frame
	if failures == 0:
		print("STAGE9_TEST_PASS")
	else:
		push_error("STAGE9_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _test_export_and_assets() -> void:
	var preset := ConfigFile.new()
	var preset_error: Error = preset.load("res://export_presets.cfg")
	_expect(preset_error == OK, "iOS export preset parse edilmeli")
	_expect(String(preset.get_value("preset.0", "platform", "")) == "iOS", "Export platformu iOS olmalı")
	_expect(
		String(preset.get_value("preset.0.options", "application/bundle_identifier", ""))
		== "com.bulsahkecici.archertowerdefense",
		"Bundle ID güvenli placeholder değerini kullanmalı"
	)
	_expect(
		int(preset.get_value("preset.0.options", "application/targeted_device_family", -1)) == 2,
		"iPhone ve iPad birlikte hedeflenmeli"
	)
	_expect(
		not bool(preset.get_value("preset.0.options", "capabilities/access_wifi", true))
		and not bool(preset.get_value("preset.0.options", "privacy/tracking_enabled", true)),
		"Gereksiz ağ ve tracking yetenekleri kapalı olmalı"
	)
	_expect(
		String(preset.get_value("preset.0", "exclude_filter", "")).contains("references/"),
		"references klasörü export runtime kaynağı dışında kalmalı"
	)
	_expect(
		int(ProjectSettings.get_setting("display/window/handheld/orientation", -1)) == 1,
		"Projenin ana yönü portre olmalı"
	)
	_expect(
		FileAccess.file_exists("res://assets/app_icon.png")
		and FileAccess.file_exists("res://assets/splash.png"),
		"İkon ve splash PNG kaynakları mevcut olmalı"
	)
	var icon_texture: Texture2D = load("res://assets/app_icon.png")
	var splash_texture: Texture2D = load("res://assets/splash.png")
	_expect(
		icon_texture != null and icon_texture.get_size() == Vector2(1024.0, 1024.0),
		"Uygulama ikonu 1024x1024 olmalı"
	)
	_expect(
		splash_texture != null and splash_texture.get_size() == Vector2(1080.0, 1920.0),
		"Splash 1080x1920 olmalı"
	)
	var icon_image: Image = icon_texture.get_image()
	_expect(icon_image.get_format() == Image.FORMAT_RGB8, "Uygulama ikonunda alpha kanalı bulunmamalı")


func _test_safe_area_fallbacks() -> void:
	var sizes: Array[Vector2] = [
		Vector2(1080.0, 1920.0),
		Vector2(720.0, 1280.0),
		Vector2(1170.0, 2532.0),
		Vector2(1290.0, 2796.0),
		Vector2(1536.0, 2048.0),
		Vector2(2048.0, 2732.0)
	]
	var all_valid: bool = true
	for size in sizes:
		var safe_rect: Rect2 = SafeAreaHelper.get_safe_rect(size)
		all_valid = (
			all_valid
			and safe_rect.position.x >= 0.0
			and safe_rect.position.y >= 0.0
			and safe_rect.end.x <= size.x
			and safe_rect.end.y <= size.y
			and safe_rect.size.x > 0.0
			and safe_rect.size.y > 0.0
		)
	_expect(all_valid, "Bütün hedef ekran oranları geçerli safe-area fallback üretmeli")


func _test_scenes_and_menu_transition() -> Node:
	var scene_paths: Array[String] = [
		"res://scenes/main_menu.tscn",
		"res://scenes/level_select.tscn",
		"res://scenes/settings.tscn",
		"res://main.tscn"
	]
	var all_loaded: bool = true
	for scene_path in scene_paths:
		all_loaded = all_loaded and load(scene_path) is PackedScene
	_expect(all_loaded, "Bütün ana sahneler yüklenmeli")
	var menu: MainMenu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	_expect(menu._start_level(1), "Menüden açık bölüme geçiş başlatılmalı")
	await process_frame
	await process_frame
	var game: Node = current_scene
	_expect(
		is_instance_valid(game) and game.has_method("_start_next_wave"),
		"Menü geçişi gerçek oyun sahnesini açmalı"
	)
	return game


func _test_runtime_safety_and_stress(game: Node) -> void:
	game.set_process(false)
	game.archer.stop_combat()
	game._pause_game()
	_expect(paused and is_instance_valid(game.ui_controller.pause_layer), "Pause UI çalışmaya devam etmeli")
	var pause_center: Control = game.ui_controller.pause_layer.get_node("SafeActionCenter")
	_expect(_control_inside_viewport(pause_center), "Pause paneli safe-area sınırlarında kalmalı")
	game._resume_game()
	game.wave_manager.state = WaveManager.WaveState.SPAWNING
	var enemies: Array[PathEnemy] = []
	for index in range(75):
		var enemy: PathEnemy = game._spawn_enemy(
			WaveManager.SWARM_ID if index % 2 == 0 else WaveManager.ARMORED_ID
		)
		enemy.set_process(false)
		enemies.append(enemy)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.resolve_defeated()
	await create_timer(0.5).timeout
	_expect(game.active_enemy_count == 0, "75 düşman stres testi node birikmeden tamamlanmalı")
	print("STAGE9_STRESS_PASS: 75 düşman")
	game._finish_game()
	await process_frame
	var game_over_center: Control = game.game_over_layer.get_node("SafeGameOverCenter")
	_expect(_control_inside_viewport(game_over_center), "Game-over paneli safe-area sınırlarında kalmalı")
	var local_save := GameSaveManager.new()
	local_save.set_save_path("/private/tmp/archer_stage9_ios_user_save.json")
	local_save.reset_defaults()
	_expect(local_save.save_data() and local_save.load_data(), "SaveManager iOS benzeri yerel alanda çalışmalı")
	local_save.free()
	_expect(audio_manager.play_event(&"projectile_hit"), "Ses dosyası olmadan AudioManager hata vermemeli")
	_expect(get_nodes_in_group("debug_only").is_empty(), "Debug-only node release sahnelerine sızmamalı")
	var dependencies: PackedStringArray = ResourceLoader.get_dependencies("res://main.tscn")
	_expect(
		not "references/" in " ".join(dependencies),
		"Harici referans görselleri runtime sahnesine bağlı olmamalı"
	)
	game._prepare_restart()
	game.queue_free()
	await process_frame
	await process_frame


func _control_inside_viewport(control: Control) -> bool:
	var viewport_size: Vector2 = control.get_viewport_rect().size
	var rect: Rect2 = control.get_global_rect()
	return (
		rect.position.x >= 0.0
		and rect.position.y >= 0.0
		and rect.end.x <= viewport_size.x + 0.5
		and rect.end.y <= viewport_size.y + 0.5
	)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
