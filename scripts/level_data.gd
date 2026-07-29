extends Resource
class_name LevelData

var id: int
var display_name: String
var starting_gold: int
var base_health: int
var total_waves: int
var wave_difficulty_multiplier: float
var build_spot_positions: Array[Vector2]
var build_spot_costs: Array[int]
var map_theme: StringName
var unlock_requirement: int
var star_thresholds: Array[int]


func _init(
	new_id: int = 1,
	new_name: String = "Yeşil Geçit",
	new_gold: int = 20,
	new_health: int = 100,
	new_waves: int = 10,
	new_difficulty: float = 1.0,
	new_spots: Array[Vector2] = [],
	new_costs: Array[int] = [15, 20, 25, 30],
	new_theme: StringName = &"green",
	new_unlock: int = 0,
	new_thresholds: Array[int] = [1, 50, 80]
) -> void:
	id = new_id
	display_name = new_name
	starting_gold = new_gold
	base_health = new_health
	total_waves = new_waves
	wave_difficulty_multiplier = new_difficulty
	build_spot_positions = new_spots
	build_spot_costs = new_costs
	map_theme = new_theme
	unlock_requirement = new_unlock
	star_thresholds = new_thresholds


static func create_catalog() -> Array[LevelData]:
	var green_spots: Array[Vector2] = [
		Vector2(320.0, 1370.0), Vector2(875.0, 1240.0),
		Vector2(205.0, 815.0), Vector2(860.0, 620.0)
	]
	return [
		LevelData.new(1, "Yeşil Geçit", 20, 100, 10, 1.0, green_spots, [15, 20, 25, 30], &"green", 0),
		LevelData.new(2, "Taş Vadi", 22, 100, 12, 1.08, [
			Vector2(250.0, 1375.0), Vector2(885.0, 1210.0),
			Vector2(220.0, 760.0), Vector2(820.0, 560.0)
		], [16, 21, 26, 31], &"stone", 1),
		LevelData.new(3, "Donmuş Yol", 24, 105, 14, 1.16, [
			Vector2(300.0, 1430.0), Vector2(900.0, 1300.0),
			Vector2(190.0, 900.0), Vector2(845.0, 700.0)
		], [17, 22, 27, 32], &"ice", 2),
		LevelData.new(4, "Kızıl Orman", 25, 110, 16, 1.24, [
			Vector2(235.0, 1450.0), Vector2(900.0, 1130.0),
			Vector2(210.0, 700.0), Vector2(875.0, 470.0)
		], [18, 23, 28, 33], &"red", 3),
		LevelData.new(5, "Son Kale", 28, 120, 20, 1.35, [
			Vector2(285.0, 1390.0), Vector2(910.0, 1260.0),
			Vector2(180.0, 840.0), Vector2(880.0, 600.0)
		], [20, 25, 30, 35], &"gold", 4)
	]


func get_path_points() -> Array[Vector2]:
	match map_theme:
		&"stone":
			return [
				Vector2(360.0, -80.0), Vector2(650.0, 250.0),
				Vector2(430.0, 520.0), Vector2(600.0, 820.0),
				Vector2(450.0, 1120.0), Vector2(710.0, 1450.0),
				Vector2(790.0, 1695.0)
			]
		&"ice":
			return [
				Vector2(690.0, -80.0), Vector2(470.0, 260.0),
				Vector2(620.0, 560.0), Vector2(390.0, 860.0),
				Vector2(660.0, 1160.0), Vector2(620.0, 1440.0),
				Vector2(790.0, 1695.0)
			]
		&"red":
			return [
				Vector2(430.0, -80.0), Vector2(680.0, 230.0),
				Vector2(400.0, 490.0), Vector2(650.0, 780.0),
				Vector2(390.0, 1080.0), Vector2(690.0, 1400.0),
				Vector2(790.0, 1695.0)
			]
		&"gold":
			return [
				Vector2(540.0, -80.0), Vector2(700.0, 270.0),
				Vector2(390.0, 570.0), Vector2(680.0, 850.0),
				Vector2(420.0, 1140.0), Vector2(720.0, 1430.0),
				Vector2(790.0, 1695.0)
			]
	return [
		Vector2(535.0, -80.0), Vector2(470.0, 260.0),
		Vector2(650.0, 540.0), Vector2(440.0, 850.0),
		Vector2(570.0, 1160.0), Vector2(710.0, 1450.0),
		Vector2(790.0, 1695.0)
	]


func get_ground_color() -> Color:
	match map_theme:
		&"stone":
			return Color("70806f")
		&"ice":
			return Color("72a7ad")
		&"red":
			return Color("8b5a46")
		&"gold":
			return Color("8b7a43")
	return Color("2e9c69")
