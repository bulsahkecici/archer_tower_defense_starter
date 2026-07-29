extends Resource
class_name EnemyData

var id: StringName
var display_name: String
var max_health: float
var movement_speed: float
var reward_gold: int
var base_damage: int
var body_radius: float
var visual_type: StringName
var is_boss: bool


func _init(
	new_id: StringName = &"normal",
	new_display_name: String = "Normal Düşman",
	new_max_health: float = 30.0,
	new_movement_speed: float = 75.0,
	new_reward_gold: int = 3,
	new_base_damage: int = 5,
	new_body_radius: float = 22.0,
	new_visual_type: StringName = &"normal",
	new_is_boss: bool = false
) -> void:
	id = new_id
	display_name = new_display_name
	max_health = new_max_health
	movement_speed = new_movement_speed
	reward_gold = new_reward_gold
	base_damage = new_base_damage
	body_radius = new_body_radius
	visual_type = new_visual_type
	is_boss = new_is_boss
