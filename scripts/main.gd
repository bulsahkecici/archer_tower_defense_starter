extends Node2D

const EnemyScript = preload("res://scripts/enemy.gd")
const ShooterScript = preload("res://scripts/shooter.gd")
const BaseScript = preload("res://scripts/base.gd")
const GamePathScript = preload("res://scripts/game_path.gd")

const WORLD_SIZE := Vector2(1080.0, 1920.0)
const STARTING_GOLD := 20
const BASE_TOWER_COST := 25

var gold: int = STARTING_GOLD
var wave: int = 0
var spawn_remaining: int = 0
var spawn_cooldown: float = 0.0
var spawn_interval: float = 0.8
var intermission: float = 1.0
var waiting_for_next_wave: bool = false
var game_over: bool = false

var base: DefenseBase
var archer: ShooterUnit
var enemy_path: Path2D
var build_spots: Array[Vector2] = [
	Vector2(185.0, 1390.0),
	Vector2(860.0, 1400.0),
	Vector2(215.0, 1110.0),
	Vector2(865.0, 1025.0),
	Vector2(185.0, 785.0),
	Vector2(855.0, 690.0),
	Vector2(265.0, 445.0),
	Vector2(820.0, 350.0)
]
var built_spots: Array[bool] = []
var towers: Array[Node2D] = []

var gold_label: Label
var wave_label: Label
var base_label: Label
var message_label: Label
var help_label: Label
var game_over_layer: CanvasLayer

func _ready() -> void:
	for _spot in build_spots:
		built_spots.append(false)

	_create_world()
	_create_ui()
	_update_ui()
	_start_next_wave()
	queue_redraw()

func _create_world() -> void:
	enemy_path = GamePathScript.new()
	enemy_path.curve = _create_enemy_curve()
	add_child(enemy_path)
	move_child(enemy_path, 0)

	base = BaseScript.new()
	add_child(base)
	base.position = Vector2(790.0, 1705.0)

	archer = ShooterScript.new()
	add_child(archer)
	archer.position = Vector2(330.0, 1600.0)
	archer.setup_archer()

func _create_enemy_curve() -> Curve2D:
	var path_curve := Curve2D.new()
	path_curve.bake_interval = 12.0
	path_curve.add_point(Vector2(535.0, -80.0))
	path_curve.add_point(Vector2(470.0, 260.0))
	path_curve.add_point(Vector2(650.0, 540.0))
	path_curve.add_point(Vector2(440.0, 850.0))
	path_curve.add_point(Vector2(570.0, 1160.0))
	path_curve.add_point(Vector2(710.0, 1450.0))
	path_curve.add_point(Vector2(790.0, 1695.0))

	for point_index in range(path_curve.point_count):
		if point_index > 0:
			var previous: Vector2 = path_curve.get_point_position(point_index - 1)
			var current: Vector2 = path_curve.get_point_position(point_index)
			path_curve.set_point_in(point_index, (previous - current) * 0.28)
		if point_index < path_curve.point_count - 1:
			var following: Vector2 = path_curve.get_point_position(point_index + 1)
			var current: Vector2 = path_curve.get_point_position(point_index)
			path_curve.set_point_out(point_index, (following - current) * 0.28)

	return path_curve

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var top_bar := ColorRect.new()
	top_bar.position = Vector2(0.0, 0.0)
	top_bar.size = Vector2(1080.0, 128.0)
	top_bar.color = Color(0.04, 0.06, 0.09, 0.84)
	canvas.add_child(top_bar)

	gold_label = Label.new()
	gold_label.position = Vector2(42.0, 32.0)
	gold_label.add_theme_font_size_override("font_size", 38)
	canvas.add_child(gold_label)

	wave_label = Label.new()
	wave_label.position = Vector2(430.0, 32.0)
	wave_label.add_theme_font_size_override("font_size", 38)
	canvas.add_child(wave_label)

	base_label = Label.new()
	base_label.position = Vector2(790.0, 32.0)
	base_label.add_theme_font_size_override("font_size", 38)
	canvas.add_child(base_label)

	message_label = Label.new()
	message_label.position = Vector2(170.0, 144.0)
	message_label.size = Vector2(740.0, 58.0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 30)
	message_label.modulate = Color("ffe08a")
	canvas.add_child(message_label)

	help_label = Label.new()
	help_label.position = Vector2(100.0, 1850.0)
	help_label.size = Vector2(880.0, 50.0)
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.text = "Boş daireye dokun: okçu kulesi kur"
	help_label.add_theme_font_size_override("font_size", 25)
	help_label.modulate = Color(1.0, 1.0, 1.0, 0.88)
	canvas.add_child(help_label)

func _process(delta: float) -> void:
	if game_over:
		return

	if spawn_remaining > 0:
		spawn_cooldown -= delta
		if spawn_cooldown <= 0.0:
			_spawn_enemy()
			spawn_remaining -= 1
			spawn_cooldown = spawn_interval
		return

	var alive_count: int = get_tree().get_nodes_in_group("enemies").size()
	if alive_count == 0:
		if not waiting_for_next_wave:
			waiting_for_next_wave = true
			intermission = 2.0
			message_label.text = "Dalga temizlendi!"
		else:
			intermission -= delta
			if intermission <= 0.0:
				waiting_for_next_wave = false
				_start_next_wave()

func _start_next_wave() -> void:
	wave += 1
	spawn_remaining = 5 + wave * 2
	spawn_interval = maxf(0.24, 0.82 - float(wave) * 0.025)
	spawn_cooldown = 0.15
	message_label.text = "Dalga %d başladı" % wave
	_update_ui()

func _spawn_enemy() -> void:
	var enemy := EnemyScript.new()
	enemy_path.add_child(enemy)
	enemy.progress = randf_range(0.0, 18.0)
	enemy.h_offset = randf_range(-38.0, 38.0)

	var health_multiplier: float = pow(1.18, float(wave - 1))
	var enemy_health: float = 10.0 * health_multiplier
	var enemy_speed: float = 55.0 * (
		1.0 + minf(float(wave - 1) * 0.025, 0.55)
	)
	var enemy_reward: int = 3 + int(wave / 4)
	var enemy_damage: int = 5 + int(wave / 5) * 2
	var enemy_radius: float = (
		18.0 + minf(float(wave) * 0.55, 16.0)
	)

	var is_boss: bool = wave % 5 == 0 and spawn_remaining == 1
	if is_boss:
		enemy_health *= 6.0
		enemy_speed *= 0.72
		enemy_reward += 25
		enemy_damage *= 3
		enemy_radius *= 1.65
		message_label.text = "BOSS geliyor!"

	enemy.setup(
		enemy_health,
		enemy_speed,
		enemy_reward,
		enemy_damage,
		enemy_radius,
		is_boss
	)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.reached_base.connect(_on_enemy_reached_base)

func _on_enemy_defeated(reward: int) -> void:
	gold += reward
	_update_ui()

func _on_enemy_reached_base(damage: int) -> void:
	base.take_damage(damage)
	_update_ui()
	if base.health <= 0:
		_finish_game()

func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		return

	var pressed: bool = false
	var input_position: Vector2 = Vector2.ZERO

	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		input_position = event.position
	elif event is InputEventScreenTouch:
		pressed = event.pressed
		input_position = event.position

	if not pressed:
		return

	for index in build_spots.size():
		if built_spots[index]:
			continue
		if input_position.distance_to(build_spots[index]) <= 48.0:
			_try_build_tower(index)
			break

func _try_build_tower(index: int) -> void:
	var cost: int = _current_tower_cost()
	if gold < cost:
		message_label.text = "Yetersiz altın: %d gerekli" % cost
		return

	gold -= cost
	built_spots[index] = true

	var tower: Node2D = ShooterScript.new()
	add_child(tower)
	tower.position = build_spots[index]
	tower.setup_tower(1)
	towers.append(tower)

	message_label.text = "Kule kuruldu!"
	_update_ui()
	queue_redraw()

func _current_tower_cost() -> int:
	return BASE_TOWER_COST + towers.size() * 10

func _finish_game() -> void:
	game_over = true
	message_label.text = "Kale düştü"

	game_over_layer = CanvasLayer.new()
	game_over_layer.layer = 30
	add_child(game_over_layer)

	var shade := ColorRect.new()
	shade.position = Vector2.ZERO
	shade.size = WORLD_SIZE
	shade.color = Color(0.02, 0.03, 0.05, 0.82)
	game_over_layer.add_child(shade)

	var title := Label.new()
	title.position = Vector2(190.0, 660.0)
	title.size = Vector2(700.0, 100.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "OYUN BİTTİ"
	title.add_theme_font_size_override("font_size", 62)
	game_over_layer.add_child(title)

	var result := Label.new()
	result.position = Vector2(190.0, 790.0)
	result.size = Vector2(700.0, 72.0)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.text = "Ulaşılan dalga: %d" % wave
	result.add_theme_font_size_override("font_size", 36)
	game_over_layer.add_child(result)

	var restart_button := Button.new()
	restart_button.position = Vector2(340.0, 920.0)
	restart_button.size = Vector2(400.0, 104.0)
	restart_button.text = "Yeniden Başlat"
	restart_button.add_theme_font_size_override("font_size", 32)
	restart_button.pressed.connect(_restart_game)
	game_over_layer.add_child(restart_button)

func _restart_game() -> void:
	get_tree().reload_current_scene()

func _update_ui() -> void:
	gold_label.text = "Altın: %d" % gold
	wave_label.text = "Dalga: %d" % wave
	base_label.text = "Kale: %d" % base.health
	help_label.text = "Kule maliyeti: %d altın • boş daireye dokun" % _current_tower_cost()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("2e9c69"))
	draw_rect(Rect2(Vector2.ZERO, Vector2(1080.0, 205.0)), Color("237b63"))
	_draw_environment()

	# Build spots
	for index in build_spots.size():
		if built_spots[index]:
			continue
		var spot := build_spots[index]
		draw_circle(spot, 43.0, Color(0.1, 0.14, 0.18, 0.55))
		draw_arc(spot, 43.0, 0.0, TAU, 48, Color("f5c451"), 4.0)
		draw_line(spot + Vector2(-13.0, 0.0), spot + Vector2(13.0, 0.0), Color("f5c451"), 4.0)
		draw_line(spot + Vector2(0.0, -13.0), spot + Vector2(0.0, 13.0), Color("f5c451"), 4.0)

func _draw_environment() -> void:
	var tree_positions: Array[Vector2] = [
		Vector2(90.0, 270.0), Vector2(940.0, 250.0), Vector2(110.0, 610.0),
		Vector2(960.0, 860.0), Vector2(90.0, 1190.0), Vector2(980.0, 1320.0),
		Vector2(120.0, 1690.0), Vector2(965.0, 1730.0)
	]
	for tree_position in tree_positions:
		draw_circle(tree_position + Vector2(8.0, 18.0), 34.0, Color(0.05, 0.20, 0.17, 0.22))
		draw_rect(Rect2(tree_position + Vector2(-8.0, 10.0), Vector2(16.0, 48.0)), Color("76522f"))
		draw_circle(tree_position + Vector2(0.0, -12.0), 36.0, Color("176a51"))
		draw_circle(tree_position + Vector2(-22.0, 2.0), 27.0, Color("23815b"))
		draw_circle(tree_position + Vector2(22.0, 4.0), 25.0, Color("2d8c60"))

	var rock_positions: Array[Vector2] = [
		Vector2(280.0, 260.0), Vector2(930.0, 510.0), Vector2(110.0, 950.0),
		Vector2(900.0, 1180.0), Vector2(210.0, 1510.0)
	]
	for rock_position in rock_positions:
		draw_colored_polygon(PackedVector2Array([
			rock_position + Vector2(-22.0, 16.0),
			rock_position + Vector2(-12.0, -15.0),
			rock_position + Vector2(15.0, -21.0),
			rock_position + Vector2(27.0, 12.0)
		]), Color("78948a"))
