extends Node
class_name GameSaveManager

var save_path: String = "user://save_data.json"
var unlocked_level: int = 1
var level_stars: Dictionary = {}
var music_volume: float = 0.8
var sfx_volume: float = 0.9
var vibration_enabled: bool = true
var first_launch: bool = true
var last_level: int = 1
var tutorial_completed: bool = false
var screen_shake_enabled: bool = true


func _ready() -> void:
	load_data()


func set_save_path(path: String) -> void:
	save_path = path


func load_data() -> bool:
	if not FileAccess.file_exists(save_path):
		reset_defaults()
		save_data()
		return true
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		reset_defaults()
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		reset_defaults()
		save_data()
		return false
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		reset_defaults()
		save_data()
		return false
	_apply_dictionary(parsed as Dictionary)
	return true


func save_data() -> bool:
	var temporary_path: String = save_path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dictionary(), "\t"))
	file = null
	var absolute_path: String = ProjectSettings.globalize_path(save_path)
	var absolute_temporary_path: String = ProjectSettings.globalize_path(temporary_path)
	var absolute_backup_path: String = absolute_path + ".bak"
	if FileAccess.file_exists(absolute_backup_path):
		DirAccess.remove_absolute(absolute_backup_path)
	var had_previous_save: bool = FileAccess.file_exists(absolute_path)
	if had_previous_save:
		if DirAccess.rename_absolute(absolute_path, absolute_backup_path) != OK:
			return false
	if DirAccess.rename_absolute(absolute_temporary_path, absolute_path) != OK:
		if had_previous_save:
			DirAccess.rename_absolute(absolute_backup_path, absolute_path)
		return false
	if had_previous_save and FileAccess.file_exists(absolute_backup_path):
		DirAccess.remove_absolute(absolute_backup_path)
	return true


func to_dictionary() -> Dictionary:
	return {
		"unlocked_level": unlocked_level,
		"level_stars": level_stars,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"vibration_enabled": vibration_enabled,
		"first_launch": first_launch,
		"last_level": last_level,
		"tutorial_completed": tutorial_completed,
		"screen_shake_enabled": screen_shake_enabled
	}


func _apply_dictionary(data: Dictionary) -> void:
	unlocked_level = clampi(int(data.get("unlocked_level", 1)), 1, 5)
	level_stars = data.get("level_stars", {}) as Dictionary
	music_volume = clampf(float(data.get("music_volume", 0.8)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx_volume", 0.9)), 0.0, 1.0)
	vibration_enabled = bool(data.get("vibration_enabled", true))
	first_launch = bool(data.get("first_launch", false))
	last_level = clampi(int(data.get("last_level", 1)), 1, unlocked_level)
	tutorial_completed = bool(data.get("tutorial_completed", not first_launch))
	screen_shake_enabled = bool(data.get("screen_shake_enabled", true))


func reset_defaults() -> void:
	unlocked_level = 1
	level_stars = {}
	music_volume = 0.8
	sfx_volume = 0.9
	vibration_enabled = true
	first_launch = true
	last_level = 1
	tutorial_completed = false
	screen_shake_enabled = true


func is_level_unlocked(level_id: int) -> bool:
	return level_id >= 1 and level_id <= unlocked_level


func complete_level(level_id: int, stars: int) -> void:
	var safe_level: int = clampi(level_id, 1, 5)
	var safe_stars: int = clampi(stars, 1, 3)
	var key: String = str(safe_level)
	level_stars[key] = maxi(int(level_stars.get(key, 0)), safe_stars)
	unlocked_level = maxi(unlocked_level, mini(5, safe_level + 1))
	last_level = safe_level
	first_launch = false
	save_data()


func get_level_stars(level_id: int) -> int:
	return clampi(int(level_stars.get(str(level_id), 0)), 0, 3)


func get_total_stars() -> int:
	var total: int = 0
	for value in level_stars.values():
		total += clampi(int(value), 0, 3)
	return total


func complete_tutorial() -> void:
	if tutorial_completed:
		return
	tutorial_completed = true
	first_launch = false
	save_data()
