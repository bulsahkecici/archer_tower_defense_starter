extends Node
class_name GameAchievementManager

signal achievement_unlocked(achievement_id: StringName, title: String)

var save_manager: Node


func _ready() -> void:
	save_manager = get_node("/root/SaveManager")


func get_definitions() -> Dictionary[StringName, Dictionary]:
	return {
		&"first_defense": {
			"title": "İlk Savunma",
			"description": "İlk bölümü tamamla",
			"target": 1
		},
		&"master_builder": {
			"title": "Usta İnşaatçı",
			"description": "Toplam 50 kule kur",
			"target": 50
		},
		&"full_power": {
			"title": "Tam Güç",
			"description": "Bir kuleyi seviye 3 yap",
			"target": 1
		},
		&"perfect_victory": {
			"title": "Kusursuz Zafer",
			"description": "Kale canı kaybetmeden bölüm tamamla",
			"target": 1
		},
		&"boss_hunter": {
			"title": "Boss Avcısı",
			"description": "Toplam 10 boss yen",
			"target": 10
		},
		&"cold_welcome": {
			"title": "Soğuk Karşılama",
			"description": "100 düşmanı yavaşlat",
			"target": 100
		},
		&"big_blast": {
			"title": "Büyük Patlama",
			"description": "Tek bomba ile en az 5 düşmana vur",
			"target": 1
		},
		&"arrow_rain_master": {
			"title": "Ok Yağmuru",
			"description": "Ok Yağmuruyla toplam 100 düşmana hasar ver",
			"target": 100
		},
		&"final_castle": {
			"title": "Son Kale",
			"description": "Beşinci bölümü tamamla",
			"target": 1
		},
		&"enduring_defense": {
			"title": "Dayanıklı Savunma",
			"description": "Sonsuz modda dalga 25’e ulaş",
			"target": 25
		}
	}


func record_event(event_id: StringName, amount: int = 1, context: Dictionary = {}) -> Array[StringName]:
	var updates: Dictionary[StringName, int] = {}
	match event_id:
		&"level_completed":
			if int(context.get("level_id", 0)) == 1:
				updates[&"first_defense"] = 1
			if int(context.get("level_id", 0)) == 5:
				updates[&"final_castle"] = 1
			if bool(context.get("perfect", false)):
				updates[&"perfect_victory"] = 1
		&"tower_built":
			updates[&"master_builder"] = maxi(0, amount)
		&"tower_upgraded":
			if int(context.get("level", 0)) >= 3:
				updates[&"full_power"] = 1
		&"boss_defeated":
			updates[&"boss_hunter"] = maxi(0, amount)
		&"enemy_slowed":
			updates[&"cold_welcome"] = maxi(0, amount)
		&"bomb_multi_hit":
			if amount >= 5:
				updates[&"big_blast"] = 1
		&"arrow_rain_hit":
			updates[&"arrow_rain_master"] = maxi(0, amount)
		&"endless_wave":
			updates[&"enduring_defense"] = maxi(
				0,
				amount - get_progress(&"enduring_defense")
			)
	var newly_unlocked: Array[StringName] = []
	for achievement_id in updates:
		if _add_progress(achievement_id, updates[achievement_id]):
			newly_unlocked.append(achievement_id)
	if not updates.is_empty():
		save_manager.save_data()
	return newly_unlocked


func get_progress(achievement_id: StringName) -> int:
	return maxi(0, int(save_manager.achievement_progress.get(String(achievement_id), 0)))


func is_unlocked(achievement_id: StringName) -> bool:
	return String(achievement_id) in save_manager.unlocked_achievements


func _add_progress(achievement_id: StringName, amount: int) -> bool:
	var definitions: Dictionary[StringName, Dictionary] = get_definitions()
	if not definitions.has(achievement_id) or is_unlocked(achievement_id):
		return false
	var target: int = int(definitions[achievement_id].target)
	var progress: int = mini(target, get_progress(achievement_id) + maxi(0, amount))
	save_manager.achievement_progress[String(achievement_id)] = progress
	if progress < target:
		return false
	save_manager.unlocked_achievements.append(String(achievement_id))
	achievement_unlocked.emit(
		achievement_id,
		String(definitions[achievement_id].title)
	)
	return true
