extends Resource
class_name TowerData

const ARCHER_ID: StringName = &"archer"
const CROSSBOW_ID: StringName = &"crossbow"

var id: StringName
var display_name: String
var description: String
var damage: float
var attack_range: float
var fire_interval: float
var projectile_speed: float
var additional_cost: int
var is_heavy_projectile: bool
var visual_type: StringName
var accent: Color
var maximum_level: int


func _init(
	new_id: StringName = ARCHER_ID,
	new_display_name: String = "Okçu Kulesi",
	new_description: String = "Dengeli ve çevik",
	new_damage: float = 10.0,
	new_attack_range: float = 336.0,
	new_fire_interval: float = 0.8,
	new_projectile_speed: float = 760.0,
	new_additional_cost: int = 0,
	new_is_heavy_projectile: bool = false,
	new_visual_type: StringName = &"archer",
	new_accent: Color = Color("4f9e75"),
	new_maximum_level: int = 5
) -> void:
	id = new_id
	display_name = new_display_name
	description = new_description
	damage = new_damage
	attack_range = new_attack_range
	fire_interval = new_fire_interval
	projectile_speed = new_projectile_speed
	additional_cost = new_additional_cost
	is_heavy_projectile = new_is_heavy_projectile
	visual_type = new_visual_type
	accent = new_accent
	maximum_level = new_maximum_level


static func create_archer() -> TowerData:
	return TowerData.new(
		ARCHER_ID, "Okçu Kulesi", "Dengeli ve çevik",
		10.0, 336.0, 0.8, 760.0, 0, false, &"archer", Color("4f9e75"), 5
	)


static func create_crossbow() -> TowerData:
	return TowerData.new(
		CROSSBOW_ID, "Arbalet Kulesi", "Ağır ve uzun menzilli",
		28.0, 418.0, 1.6, 900.0, 15, true, &"crossbow", Color("526d96"), 5
	)


static func create_for_id(tower_id: StringName) -> TowerData:
	if tower_id == CROSSBOW_ID:
		return create_crossbow()
	return create_archer()
