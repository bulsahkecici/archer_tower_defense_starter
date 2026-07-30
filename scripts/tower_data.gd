extends Resource
class_name TowerData

const ARCHER_ID: StringName = &"archer"
const CROSSBOW_ID: StringName = &"crossbow"
const ICE_ID: StringName = &"ice"
const BOMB_ID: StringName = &"bomb"

var id: StringName
var display_name: String
var description: String
var base_damage: float
var base_attack_range: float
var base_fire_interval: float
var projectile_speed: float
var additional_cost: int
var is_heavy_projectile: bool
var visual_type: StringName
var accent: Color
var maximum_level: int
var upgrade_costs: Array[int]
var damage_multipliers: Array[float]
var range_multipliers: Array[float]
var fire_rate_multipliers: Array[float]
var sell_refund_ratio: float
var slow_ratio: float
var slow_duration: float
var explosion_radius: float
var role_description: String
var special_effect: String
var strong_against: String
var critical_chance: float
var critical_multiplier: float

# Backwards-compatible level-one aliases.
var damage: float:
	get:
		return base_damage
var attack_range: float:
	get:
		return base_attack_range
var fire_interval: float:
	get:
		return base_fire_interval


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
	new_upgrade_costs: Array[int] = [20, 35],
	new_damage_multipliers: Array[float] = [1.0, 1.5, 2.2],
	new_range_multipliers: Array[float] = [1.0, 1.0714286, 1.1607143],
	new_fire_rate_multipliers: Array[float] = [1.0, 0.875, 0.725],
	new_sell_refund_ratio: float = 0.70,
	new_slow_ratio: float = 0.0,
	new_slow_duration: float = 0.0,
	new_explosion_radius: float = 0.0,
	new_role_description: String = "Genel amaçlı",
	new_special_effect: String = "Yok",
	new_strong_against: String = "Normal düşmanlar",
	new_critical_chance: float = 0.0,
	new_critical_multiplier: float = 1.0
) -> void:
	id = new_id
	display_name = new_display_name
	description = new_description
	base_damage = new_damage
	base_attack_range = new_attack_range
	base_fire_interval = new_fire_interval
	projectile_speed = new_projectile_speed
	additional_cost = new_additional_cost
	is_heavy_projectile = new_is_heavy_projectile
	visual_type = new_visual_type
	accent = new_accent
	upgrade_costs = new_upgrade_costs
	damage_multipliers = new_damage_multipliers
	range_multipliers = new_range_multipliers
	fire_rate_multipliers = new_fire_rate_multipliers
	maximum_level = mini(
		damage_multipliers.size(),
		mini(range_multipliers.size(), fire_rate_multipliers.size())
	)
	sell_refund_ratio = clampf(new_sell_refund_ratio, 0.0, 1.0)
	slow_ratio = clampf(new_slow_ratio, 0.0, 0.9)
	slow_duration = maxf(0.0, new_slow_duration)
	explosion_radius = maxf(0.0, new_explosion_radius)
	role_description = new_role_description
	special_effect = new_special_effect
	strong_against = new_strong_against
	critical_chance = clampf(new_critical_chance, 0.0, 1.0)
	critical_multiplier = maxf(1.0, new_critical_multiplier)


func get_damage(level: int) -> float:
	var index: int = clampi(level, 1, maximum_level) - 1
	return base_damage * damage_multipliers[index]


func get_attack_range(level: int) -> float:
	var index: int = clampi(level, 1, maximum_level) - 1
	return base_attack_range * range_multipliers[index]


func get_fire_interval(level: int) -> float:
	var index: int = clampi(level, 1, maximum_level) - 1
	return base_fire_interval * fire_rate_multipliers[index]


func get_upgrade_cost(level: int) -> int:
	if level < 1 or level >= maximum_level:
		return 0
	return upgrade_costs[level - 1]


func get_sell_refund(invested_gold: int) -> int:
	return maxi(0, int(floor(float(maxi(0, invested_gold)) * sell_refund_ratio)))


func get_role_summary() -> String:
	return "%s\nÖzel: %s\nGüçlü: %s" % [
		role_description,
		special_effect,
		strong_against
	]


static func create_archer() -> TowerData:
	return TowerData.new(
		ARCHER_ID, "Okçu Kulesi", "Dengeli ve çevik",
		10.0, 336.0, 0.8, 760.0, 0, false, &"archer", Color("4f9e75"),
		[20, 35], [1.0, 1.5, 2.2], [1.0, 1.0714286, 1.1607143],
		[1.0, 0.875, 0.725], 0.70, 0.0, 0.0, 0.0,
		"Genel amaçlı • Dengeli hasar ve hız",
		"%10 kritik vuruş", "Normal ve hızlı düşmanlar", 0.10, 1.6
	)


static func create_crossbow() -> TowerData:
	return TowerData.new(
		CROSSBOW_ID, "Arbalet Kulesi", "Ağır ve uzun menzilli",
		28.0, 418.0, 1.6, 900.0, 15, true, &"crossbow", Color("526d96"),
		[35, 55], [1.0, 1.5357143, 2.3214286], [1.0, 1.076555, 1.160287],
		[1.0, 0.8875, 0.7625], 0.70, 0.0, 0.0, 0.0,
		"Yavaş ama ağır hasar", "Ağır mermi", "Boss ve zırhlı düşmanlar"
	)


static func create_ice() -> TowerData:
	return TowerData.new(
		ICE_ID, "Buz Kulesi", "Düşmanları geçici yavaşlatır",
		6.0, 350.0, 1.05, 720.0, 20, false, &"ice", Color("72cfe8"),
		[28, 42], [1.0, 1.55, 2.2], [1.0, 1.08, 1.16],
		[1.0, 0.88, 0.75], 0.70, 0.25, 1.5, 0.0,
		"Destek kulesi", "%25 yavaşlatma", "Hızlı düşmanlar"
	)


static func create_bomb() -> TowerData:
	return TowerData.new(
		BOMB_ID, "Bomba Kulesi", "Yüksek alan hasarı",
		35.0, 370.0, 2.1, 620.0, 30, true, &"bomb", Color("d87942"),
		[45, 65], [1.0, 1.5, 2.15], [1.0, 1.08, 1.16],
		[1.0, 0.88, 0.74], 0.70, 0.0, 0.0, 95.0,
		"Kalabalık gruplara karşı güçlü", "95 alan hasarı", "Sürü düşmanları"
	)


static func create_for_id(tower_id: StringName) -> TowerData:
	if tower_id == CROSSBOW_ID:
		return create_crossbow()
	if tower_id == ICE_ID:
		return create_ice()
	if tower_id == BOMB_ID:
		return create_bomb()
	return create_archer()
