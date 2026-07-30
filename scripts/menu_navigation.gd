extends RefCounted
class_name MenuNavigation

const MAIN_MENU := "res://scenes/main_menu.tscn"
const LEVEL_SELECT := "res://scenes/level_select.tscn"
const SETTINGS := "res://scenes/settings.tscn"
const ABOUT := "res://scenes/about.tscn"
const COSMETICS := "res://scenes/cosmetics.tscn"
const GAME := "res://main.tscn"

static var return_targets: Dictionary = {}


static func change_scene(tree: SceneTree, scene_path: String) -> Error:
	tree.paused = false
	Engine.time_scale = 1.0
	return tree.change_scene_to_file(scene_path)


static func open_with_return(
	tree: SceneTree,
	scene_path: String,
	return_key: StringName,
	return_path: String = MAIN_MENU
) -> Error:
	return_targets[return_key] = return_path
	return change_scene(tree, scene_path)


static func return_from(
	tree: SceneTree,
	return_key: StringName,
	fallback_path: String = MAIN_MENU
) -> Error:
	var target: String = String(return_targets.get(return_key, fallback_path))
	return_targets.erase(return_key)
	return change_scene(tree, target)
