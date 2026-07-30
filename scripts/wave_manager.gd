extends Node
class_name WaveManager

enum WaveState {
	WAITING,
	SPAWNING,
	ACTIVE,
	COMPLETED,
	GAME_OVER
}

const NORMAL_ID: StringName = &"normal"
const FAST_ID: StringName = &"fast"
const BOSS_ID: StringName = &"boss"
const ARMORED_ID: StringName = &"armored"
const SWARM_ID: StringName = &"swarm"

var state: WaveState = WaveState.WAITING
var current_wave: int = 0
var spawn_queue: Array[StringName] = []
var enemy_definitions: Dictionary[StringName, EnemyData] = {}


func _ready() -> void:
	_create_enemy_definitions()


func _create_enemy_definitions() -> void:
	enemy_definitions = {
		NORMAL_ID: EnemyData.new(
			NORMAL_ID, "Kor Muhafız", 30.0, 75.0, 3, 5, 22.0, &"normal", false
		),
		FAST_ID: EnemyData.new(
			FAST_ID, "Çevik İzci", 17.0, 125.0, 2, 3, 17.0, &"fast", false
		),
		BOSS_ID: EnemyData.new(
			BOSS_ID, "Taş Yürekli Dev", 350.0, 48.0, 35, 25, 37.4, &"boss", true,
			0.0, 0.50, [&"boss"]
		),
		ARMORED_ID: EnemyData.new(
			ARMORED_ID, "Zırhlı Muhafız", 95.0, 58.0, 7, 10, 27.0, &"armored", false,
			0.25, 0.20, [&"armored"]
		),
		SWARM_ID: EnemyData.new(
			SWARM_ID, "Sürücü", 9.0, 145.0, 1, 2, 13.0, &"swarm", false,
			0.0, 0.0, [&"swarm"]
		)
	}


func get_enemy_data(enemy_id: StringName) -> EnemyData:
	return enemy_definitions.get(enemy_id) as EnemyData


func begin_wave(wave_number: int) -> void:
	if state == WaveState.SPAWNING or state == WaveState.ACTIVE:
		return
	current_wave = maxi(1, wave_number)
	spawn_queue = get_wave_composition(current_wave)
	state = WaveState.SPAWNING


func take_next_spawn() -> StringName:
	if state != WaveState.SPAWNING or spawn_queue.is_empty():
		return &""
	var enemy_id: StringName = spawn_queue.pop_front()
	if spawn_queue.is_empty():
		state = WaveState.ACTIVE
	return enemy_id


func mark_completed() -> bool:
	if state != WaveState.ACTIVE:
		return false
	state = WaveState.COMPLETED
	return true


func set_waiting() -> void:
	if state == WaveState.COMPLETED:
		state = WaveState.WAITING


func set_game_over() -> void:
	spawn_queue.clear()
	state = WaveState.GAME_OVER


func reset() -> void:
	current_wave = 0
	spawn_queue.clear()
	state = WaveState.WAITING


func get_wave_composition(wave_number: int) -> Array[StringName]:
	var composition: Array[StringName] = []
	match wave_number:
		1:
			_append_enemies(composition, NORMAL_ID, 8)
		2:
			_append_enemies(composition, NORMAL_ID, 8)
			_append_enemies(composition, FAST_ID, 2)
		3:
			_append_enemies(composition, NORMAL_ID, 10)
			_append_enemies(composition, FAST_ID, 4)
		4:
			_append_enemies(composition, NORMAL_ID, 12)
			_append_enemies(composition, FAST_ID, 6)
		5:
			_append_enemies(composition, NORMAL_ID, 8)
			_append_enemies(composition, FAST_ID, 4)
			composition.append(BOSS_ID)
		_:
			var normal_count: int = 8 + wave_number
			var fast_count: int = mini(4 + int(wave_number / 2), 18)
			_append_enemies(composition, NORMAL_ID, normal_count)
			_append_enemies(composition, FAST_ID, fast_count)
			if wave_number >= 6:
				_append_enemies(composition, ARMORED_ID, 1 + int(wave_number / 3))
			if wave_number >= 7:
				_append_enemies(composition, SWARM_ID, 3 + wave_number)
			if wave_number % 5 == 0:
				composition.append(BOSS_ID)
	return composition


func get_health_multiplier(wave_number: int) -> float:
	var safe_wave: int = maxi(1, wave_number)
	if safe_wave <= 10:
		return pow(1.075, float(safe_wave - 1))
	var first_ten_multiplier: float = pow(1.075, 9.0)
	if safe_wave <= 20:
		return first_ten_multiplier * pow(1.06, float(safe_wave - 10))
	var first_twenty_multiplier: float = first_ten_multiplier * pow(1.06, 10.0)
	return first_twenty_multiplier * pow(1.075, float(safe_wave - 20))


func get_speed_multiplier(wave_number: int, is_boss: bool) -> float:
	var maximum_increase: float = 0.18 if is_boss else 0.35
	return 1.0 + minf(float(maxi(1, wave_number) - 1) * 0.02, maximum_increase)


func get_reward_bonus(wave_number: int, is_boss: bool) -> int:
	if is_boss:
		return mini(int(maxi(1, wave_number) / 5) * 2, 12)
	return mini(int(maxi(1, wave_number) / 6), 4)


func get_wave_balance(wave_number: int) -> Dictionary:
	var composition: Array[StringName] = get_wave_composition(wave_number)
	var health_multiplier: float = get_health_multiplier(wave_number)
	var total_health: float = 0.0
	var total_reward: int = 0
	for enemy_id in composition:
		var data: EnemyData = get_enemy_data(enemy_id)
		total_health += data.max_health * health_multiplier
		total_reward += data.reward_gold + get_reward_bonus(wave_number, data.is_boss)
	return {
		"wave": wave_number,
		"health_multiplier": health_multiplier,
		"normal_health": get_enemy_data(NORMAL_ID).max_health * health_multiplier,
		"fast_health": get_enemy_data(FAST_ID).max_health * health_multiplier,
		"boss_health": get_enemy_data(BOSS_ID).max_health * health_multiplier,
		"armored_health": get_enemy_data(ARMORED_ID).max_health * health_multiplier,
		"swarm_health": get_enemy_data(SWARM_ID).max_health * health_multiplier,
		"total_health": total_health,
		"total_reward": total_reward
	}


func _append_enemies(
	composition: Array[StringName],
	enemy_id: StringName,
	count: int
) -> void:
	for _index in range(maxi(0, count)):
		composition.append(enemy_id)
