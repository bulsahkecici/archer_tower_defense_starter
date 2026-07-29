extends SceneTree

var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_resource: PackedScene = load("res://main.tscn")
	var game: Node = scene_resource.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	_expect(game.build_spots.size() == 4, "Dört inşa noktası bulunmalı")
	_expect(
		game.BUILD_SPOT_COSTS == [15, 20, 25, 30],
		"İnşa noktası maliyetleri 15/20/25/30 olmalı"
	)
	_expect(
		game.economy.gold == game.level_data.starting_gold
		and game.economy.gold == 35,
		"Kolaylaştırılan ilk bölüm 35 başlangıç altını vermeli"
	)
	var level_starting_gold: int = game.economy.gold
	_expect(not game.economy.spend_gold(-1), "Negatif harcama reddedilmeli")
	_expect(not game.economy.spend_gold(999), "Yetersiz bakiye harcaması reddedilmeli")
	_expect(
		game.economy.gold == level_starting_gold,
		"Reddedilen harcamalar bakiyeyi değiştirmemeli"
	)
	# Eski düşük-bakiye ekonomi senaryosunu yeni bölüm başlangıç bonusundan
	# bağımsız doğrula.
	game.economy.setup(20)

	game._open_tower_selection(0)
	await process_frame
	_expect(
		is_instance_valid(game.tower_selection_panel),
		"Boş noktaya dokununca seçim paneli açılmalı"
	)
	_expect(
		not game.tower_selection_panel.archer_button.disabled,
		"Yeterli altın varsa Okçu Kulesi seçilebilir olmalı"
	)
	_expect(
		game.tower_selection_panel.crossbow_button.disabled,
		"Yetersiz altın varsa Arbalet Kulesi pasif olmalı"
	)

	game._on_tower_selected(ShooterUnit.TowerType.ARCHER)
	await process_frame
	_expect(game.built_spots[0], "Okçu Kulesi seçilen noktaya kurulmalı")
	_expect(game.economy.gold == 5, "Okçu Kulesi maliyeti yalnızca bir kere harcanmalı")
	_expect(game.towers.size() == 1, "İlk kurulumdan sonra bir kule bulunmalı")
	_expect(
		game.towers[0].tower_type == ShooterUnit.TowerType.ARCHER,
		"Kurulan ilk kule Okçu Kulesi olmalı"
	)

	game._open_tower_selection(0)
	await process_frame
	_expect(
		not is_instance_valid(game.tower_selection_panel),
		"Dolu noktaya ikinci kez panel açılmamalı"
	)

	game.economy.add_gold(100)
	game._open_tower_selection(1)
	await process_frame
	_expect(
		not game.tower_selection_panel.crossbow_button.disabled,
		"Yeterli altın sonrası Arbalet Kulesi seçilebilir olmalı"
	)
	game._on_tower_selected(ShooterUnit.TowerType.CROSSBOW)
	await process_frame
	_expect(game.built_spots[1], "Arbalet Kulesi seçilen noktaya kurulmalı")
	_expect(game.economy.gold == 70, "Arbalet toplam maliyeti güvenli harcanmalı")
	_expect(
		game.towers[1].tower_type == ShooterUnit.TowerType.CROSSBOW,
		"Kurulan ikinci kule Arbalet Kulesi olmalı"
	)

	var touch := InputEventScreenTouch.new()
	touch.position = game.build_spots[2]
	touch.pressed = true
	game._unhandled_input(touch)
	await process_frame
	_expect(
		is_instance_valid(game.tower_selection_panel),
		"Dokunmatik giriş seçim panelini açmalı"
	)
	var outside_touch := InputEventScreenTouch.new()
	outside_touch.position = Vector2(40.0, 400.0)
	outside_touch.pressed = true
	game.tower_selection_panel._gui_input(outside_touch)
	await process_frame
	_expect(
		not is_instance_valid(game.tower_selection_panel),
		"Panel dışına dokunmak seçim panelini kapatmalı"
	)

	var mouse_click := InputEventMouseButton.new()
	mouse_click.position = game.build_spots[3]
	mouse_click.button_index = MOUSE_BUTTON_LEFT
	mouse_click.pressed = true
	game._unhandled_input(mouse_click)
	await process_frame
	_expect(
		is_instance_valid(game.tower_selection_panel),
		"Sol mouse tıklaması seçim panelini açmalı"
	)
	game._close_tower_panel()
	await process_frame

	if failures == 0:
		print("STAGE3_TEST_PASS")
	else:
		push_error("STAGE3_TEST_FAIL: %d hata" % failures)
	quit(failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
