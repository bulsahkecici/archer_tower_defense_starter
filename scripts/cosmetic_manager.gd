extends Node
class_name GameCosmeticManager

var save_manager: Node


func _ready() -> void:
	save_manager = get_node("/root/SaveManager")
	validate_selection()


func get_definitions() -> Dictionary[StringName, Dictionary]:
	return {
		&"default_arrow": {
			"name": "Varsayılan Ok",
			"category": &"arrow_trail",
			"condition": "Başlangıç",
			"color": Color("dedede")
		},
		&"ice_arrow": {
			"name": "Buz Mavisi Ok İzi",
			"category": &"arrow_trail",
			"condition": "Soğuk Karşılama başarımı",
			"color": Color("8feaff")
		},
		&"gold_arrow": {
			"name": "Altın Ok İzi",
			"category": &"arrow_trail",
			"condition": "10 toplam yıldız",
			"color": Color("ffd667")
		},
		&"green_roof": {
			"name": "Yeşil Kale Çatısı",
			"category": &"castle_roof",
			"condition": "Başlangıç",
			"color": Color("4f9e75")
		},
		&"blue_roof": {
			"name": "Mavi Kale Çatısı",
			"category": &"castle_roof",
			"condition": "İlk Savunma başarımı",
			"color": Color("4f83b7")
		},
		&"gold_tower": {
			"name": "Altın Kule Vurgusu",
			"category": &"tower_accent",
			"condition": "15 toplam yıldız",
			"color": Color("d9b85f")
		},
		&"road_flags": {
			"name": "Yol Kenarı Bayrakları",
			"category": &"road_flags",
			"condition": "Sonsuz dalga 25",
			"color": Color("d95f59")
		}
	}


func is_unlocked(cosmetic_id: StringName) -> bool:
	match cosmetic_id:
		&"default_arrow", &"green_roof":
			return true
		&"ice_arrow":
			return "cold_welcome" in save_manager.unlocked_achievements
		&"gold_arrow":
			return save_manager.get_total_stars() >= 10
		&"blue_roof":
			return "first_defense" in save_manager.unlocked_achievements
		&"gold_tower":
			return save_manager.get_total_stars() >= 15
		&"road_flags":
			return save_manager.endless_high_wave >= 25
	return false


func select_cosmetic(cosmetic_id: StringName) -> bool:
	var definitions: Dictionary[StringName, Dictionary] = get_definitions()
	if not definitions.has(cosmetic_id) or not is_unlocked(cosmetic_id):
		return false
	var category: StringName = definitions[cosmetic_id].category
	save_manager.selected_cosmetics[String(category)] = String(cosmetic_id)
	save_manager.save_data()
	return true


func get_selected(category: StringName) -> StringName:
	validate_selection()
	return StringName(save_manager.selected_cosmetics.get(
		String(category),
		String(_default_for_category(category))
	))


func get_selected_color(category: StringName, fallback: Color) -> Color:
	var selected: StringName = get_selected(category)
	var definitions: Dictionary[StringName, Dictionary] = get_definitions()
	if not definitions.has(selected):
		return fallback
	return definitions[selected].color


func validate_selection() -> void:
	if save_manager == null:
		return
	var changed: bool = false
	for category in [&"arrow_trail", &"castle_roof", &"tower_accent", &"road_flags"]:
		var selected: StringName = StringName(save_manager.selected_cosmetics.get(
			String(category),
			String(_default_for_category(category))
		))
		if not get_definitions().has(selected) or not is_unlocked(selected):
			save_manager.selected_cosmetics[String(category)] = String(
				_default_for_category(category)
			)
			changed = true
	if changed and is_inside_tree():
		save_manager.save_data()


func _default_for_category(category: StringName) -> StringName:
	if category == &"castle_roof":
		return &"green_roof"
	if category == &"arrow_trail":
		return &"default_arrow"
	return &""
