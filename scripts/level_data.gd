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
	var base_spots: Array[Vector2] = [
		Vector2(320.0, 1370.0), Vector2(875.0, 1240.0),
		Vector2(205.0, 815.0), Vector2(860.0, 620.0)
	]
	return [
		LevelData.new(1, "Yeşil Geçit", 20, 100, 10, 1.0, base_spots, [15, 20, 25, 30], &"green", 0),
		LevelData.new(2, "Taş Vadi", 22, 100, 12, 1.08, base_spots, [16, 21, 26, 31], &"stone", 1),
		LevelData.new(3, "Donmuş Yol", 24, 105, 14, 1.16, base_spots, [17, 22, 27, 32], &"ice", 2),
		LevelData.new(4, "Kızıl Orman", 25, 110, 16, 1.24, base_spots, [18, 23, 28, 33], &"red", 3),
		LevelData.new(5, "Son Kale", 28, 120, 20, 1.35, base_spots, [20, 25, 30, 35], &"gold", 4)
	]
