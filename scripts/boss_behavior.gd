extends Node
class_name BossBehavior

var enemy: PathEnemy
var game: Node
var level_id: int = 1
var description: String = ""
var threshold_triggered: bool = false
var threshold_trigger_count: int = 0
var summon_count: int = 0
var ability_cooldown: float = 0.0
var affected_enemies: Array[PathEnemy] = []


func configure(boss_enemy: PathEnemy, game_root: Node, current_level_id: int) -> void:
	enemy = boss_enemy
	game = game_root
	level_id = clampi(current_level_id, 1, 5)
	description = _description_for_level()
	enemy.boss_behavior_description = description
	enemy.damage_received.connect(_on_damage_received)
	ability_cooldown = 4.0
	set_process(level_id in [2, 3, 4])


func _process(delta: float) -> void:
	if not is_instance_valid(enemy) or enemy.has_resolved:
		return
	ability_cooldown -= delta
	if ability_cooldown > 0.0:
		return
	ability_cooldown = 4.0 if level_id != 4 else 6.0
	if level_id == 2:
		apply_armor_aura_once()
	elif level_id == 3:
		clear_slow_once()
	elif level_id == 4:
		trigger_summon()


func _on_damage_received(
	_amount: float,
	_world_position: Vector2,
	_critical: bool,
	_armor_blocked: bool
) -> void:
	if threshold_triggered or not is_instance_valid(enemy):
		return
	if enemy.health / maxf(1.0, enemy.max_health) > 0.5:
		return
	threshold_triggered = true
	threshold_trigger_count += 1
	if level_id == 1:
		enemy.base_speed *= 1.20
	elif level_id == 5:
		enemy.base_speed *= 1.25
		enemy.add_armor_source(_source_key(), 0.10)
	enemy.queue_redraw()


func apply_armor_aura_once() -> int:
	if level_id != 2 or not is_instance_valid(enemy):
		return 0
	var applied: int = 0
	for node in enemy.get_tree().get_nodes_in_group("enemies"):
		if (
			not is_instance_valid(node)
			or node == enemy
			or node.get("has_resolved") == true
		):
			continue
		var nearby := node as PathEnemy
		if nearby.global_position.distance_to(enemy.global_position) > 260.0:
			continue
		nearby.add_armor_source(_source_key(), 0.15)
		if nearby not in affected_enemies:
			affected_enemies.append(nearby)
		applied += 1
	return applied


func clear_slow_once() -> bool:
	if level_id != 3 or not is_instance_valid(enemy):
		return false
	var had_slow: bool = enemy.slow_remaining > 0.0
	enemy.clear_slow()
	return had_slow


func trigger_summon() -> int:
	if level_id != 4 or not is_instance_valid(game):
		return 0
	var spawned: int = int(game._spawn_boss_minions(4))
	summon_count += spawned
	return spawned


func cleanup() -> void:
	for affected in affected_enemies:
		if is_instance_valid(affected):
			affected.remove_armor_source(_source_key())
	affected_enemies.clear()
	if is_instance_valid(enemy):
		enemy.remove_armor_source(_source_key())
	set_process(false)


func _exit_tree() -> void:
	cleanup()


func _source_key() -> StringName:
	return StringName("boss_%d" % get_instance_id())


func _description_for_level() -> String:
	match level_id:
		2:
			return "Yakındaki düşmanlara %15 zırh verir"
		3:
			return "Buz etkisini düzenli temizler"
		4:
			return "Belirli aralıklarla sürü çağırır"
		5:
			return "%50 canda ikinci aşamaya geçer"
	return "%50 canda %20 hızlanır"
