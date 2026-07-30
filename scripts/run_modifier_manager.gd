extends Node
class_name RunModifierManager

const REWARD_WAVES: Array[int] = [3, 6, 9, 12]

var applied_rewards: Array[StringName] = []
var archer_damage_multiplier: float = 1.0
var crossbow_range_multiplier: float = 1.0
var ice_slow_duration_multiplier: float = 1.0
var bomb_radius_multiplier: float = 1.0
var arrow_rain_cooldown_reduction: float = 0.0
var next_upgrade_discount: float = 0.0
var apply_count: int = 0


func get_reward_definitions() -> Dictionary[StringName, Dictionary]:
	return {
		&"archer_damage": {
			"title": "Keskin Nişancılar",
			"description": "Tüm Okçu Kuleleri +%10 hasar"
		},
		&"crossbow_range": {
			"title": "Uzun Hat",
			"description": "Tüm Arbalet Kuleleri +%10 menzil"
		},
		&"ice_duration": {
			"title": "Derin Don",
			"description": "Buz yavaşlatma süresi +%10"
		},
		&"bomb_radius": {
			"title": "Geniş Patlama",
			"description": "Bomba patlama yarıçapı +%12"
		},
		&"base_health": {
			"title": "Sağlam Duvarlar",
			"description": "Kale +20 can"
		},
		&"gold": {
			"title": "Savaş Sandığı",
			"description": "+25 altın"
		},
		&"ability_cooldown": {
			"title": "Okçu Disiplini",
			"description": "Ok Yağmuru cooldown -3 saniye"
		},
		&"upgrade_discount": {
			"title": "Usta İşçilik",
			"description": "Sonraki yükseltme %20 daha ucuz"
		}
	}


func get_reward_choices(wave: int) -> Array[Dictionary]:
	var definitions: Dictionary[StringName, Dictionary] = get_reward_definitions()
	var keys: Array[StringName] = definitions.keys()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(wave) * 7919 + applied_rewards.size() * 101
	for index in range(keys.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temporary: StringName = keys[index]
		keys[index] = keys[swap_index]
		keys[swap_index] = temporary
	var choices: Array[Dictionary] = []
	for index in mini(3, keys.size()):
		var reward_id: StringName = keys[index]
		var definition: Dictionary = definitions[reward_id]
		choices.append({
			"id": reward_id,
			"title": definition.title,
			"description": definition.description
		})
	return choices


func is_reward_wave(wave: int, endless: bool = false) -> bool:
	return (
		wave in REWARD_WAVES
		or (endless and wave > 0 and wave % 3 == 0)
	)


func apply_reward(
	reward_id: StringName,
	economy: EconomyManager,
	base: DefenseBase,
	towers: Array[Node2D]
) -> bool:
	if not get_reward_definitions().has(reward_id):
		return false
	applied_rewards.append(reward_id)
	apply_count += 1
	match reward_id:
		&"archer_damage":
			archer_damage_multiplier *= 1.10
		&"crossbow_range":
			crossbow_range_multiplier *= 1.10
		&"ice_duration":
			ice_slow_duration_multiplier *= 1.10
		&"bomb_radius":
			bomb_radius_multiplier *= 1.12
		&"base_health":
			base.max_health += 20
			base.health += 20
			base.queue_redraw()
		&"gold":
			economy.add_gold(25)
		&"ability_cooldown":
			arrow_rain_cooldown_reduction = minf(
				12.0,
				arrow_rain_cooldown_reduction + 3.0
			)
		&"upgrade_discount":
			next_upgrade_discount = 0.20
	for node in towers:
		if is_instance_valid(node) and node is ShooterUnit:
			apply_to_tower(node as ShooterUnit)
	return true


func apply_to_tower(tower: ShooterUnit) -> void:
	tower.clear_modifiers_with_prefix("run_")
	tower.effective_slow_duration = (
		tower.tower_data.slow_duration * ice_slow_duration_multiplier
	)
	tower.effective_explosion_radius = (
		tower.tower_data.explosion_radius * bomb_radius_multiplier
	)
	if tower.tower_type == ShooterUnit.TowerType.ARCHER:
		tower.set_stat_modifier(
			&"run_archer_damage",
			archer_damage_multiplier,
			1.0,
			1.0,
			"Koşu ödülü: Okçu hasarı"
		)
	elif tower.tower_type == ShooterUnit.TowerType.CROSSBOW:
		tower.set_stat_modifier(
			&"run_crossbow_range",
			1.0,
			crossbow_range_multiplier,
			1.0,
			"Koşu ödülü: Arbalet menzili"
		)


func get_upgrade_cost(base_cost: int) -> int:
	if next_upgrade_discount <= 0.0:
		return base_cost
	return maxi(1, int(ceil(float(base_cost) * (1.0 - next_upgrade_discount))))


func consume_upgrade_discount() -> void:
	next_upgrade_discount = 0.0


func reset() -> void:
	applied_rewards.clear()
	archer_damage_multiplier = 1.0
	crossbow_range_multiplier = 1.0
	ice_slow_duration_multiplier = 1.0
	bomb_radius_multiplier = 1.0
	arrow_rain_cooldown_reduction = 0.0
	next_upgrade_discount = 0.0
	apply_count = 0
