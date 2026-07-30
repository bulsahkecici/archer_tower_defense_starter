extends Node
class_name TowerSynergyManager

const ARCHER_CROSSBOW_RADIUS: float = 470.0
const ICE_AURA_RADIUS: float = 430.0
const ATTACK_SPEED_BONUS: float = 0.08
const ICE_AURA_RANGE_BONUS: float = 0.08
const SLOWED_BOMB_DAMAGE_BONUS: float = 0.20

var recompute_count: int = 0


func recompute(towers: Array[Node2D]) -> void:
	recompute_count += 1
	var valid_towers: Array[ShooterUnit] = []
	for node in towers:
		if is_instance_valid(node) and node is ShooterUnit:
			var tower := node as ShooterUnit
			tower.clear_modifiers_with_prefix("synergy_")
			valid_towers.append(tower)

	for first_index in valid_towers.size():
		for second_index in range(first_index + 1, valid_towers.size()):
			var first: ShooterUnit = valid_towers[first_index]
			var second: ShooterUnit = valid_towers[second_index]
			if (
				_is_archer_crossbow_pair(first, second)
				and first.global_position.distance_to(second.global_position)
					<= ARCHER_CROSSBOW_RADIUS
			):
				first.set_stat_modifier(
					&"synergy_archer_crossbow",
					1.0,
					1.0,
					1.0 - ATTACK_SPEED_BONUS,
					"Okçu + Arbalet: +%8 saldırı hızı"
				)
				second.set_stat_modifier(
					&"synergy_archer_crossbow",
					1.0,
					1.0,
					1.0 - ATTACK_SPEED_BONUS,
					"Okçu + Arbalet: +%8 saldırı hızı"
				)

	var has_ice: bool = valid_towers.any(
		func(tower: ShooterUnit) -> bool:
			return tower.tower_type == ShooterUnit.TowerType.ICE
	)
	if has_ice:
		for tower in valid_towers:
			if tower.tower_type == ShooterUnit.TowerType.BOMB:
				tower.slowed_target_damage_multiplier = 1.0 + SLOWED_BOMB_DAMAGE_BONUS
				tower.active_modifier_descriptions[&"synergy_ice_bomb"] = (
					"Buz + Bomba: yavaş hedefe +%20 hasar"
				)

	for ice_tower in valid_towers:
		if (
			ice_tower.tower_type != ShooterUnit.TowerType.ICE
			or ice_tower.level < 3
		):
			continue
		for recipient in valid_towers:
			if (
				recipient == ice_tower
				or recipient.global_position.distance_to(ice_tower.global_position)
					> ICE_AURA_RADIUS
			):
				continue
			recipient.set_stat_modifier(
				&"synergy_ice_aura",
				1.0,
				1.0 + ICE_AURA_RANGE_BONUS,
				1.0,
				"Seviye 3 Buz aurası: +%8 menzil"
			)
	for tower in valid_towers:
		tower.recalculate_effective_stats()


func _is_archer_crossbow_pair(first: ShooterUnit, second: ShooterUnit) -> bool:
	return (
		first.tower_type == ShooterUnit.TowerType.ARCHER
		and second.tower_type == ShooterUnit.TowerType.CROSSBOW
	) or (
		first.tower_type == ShooterUnit.TowerType.CROSSBOW
		and second.tower_type == ShooterUnit.TowerType.ARCHER
	)
