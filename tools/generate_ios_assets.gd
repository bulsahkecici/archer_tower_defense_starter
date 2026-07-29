extends SceneTree

const ASSETS: Array[Dictionary] = [
	{
		"source": "res://assets/app_icon.svg",
		"target": "res://assets/app_icon.png",
		"size": Vector2i(1024, 1024)
	},
	{
		"source": "res://assets/splash.svg",
		"target": "res://assets/splash.png",
		"size": Vector2i(1080, 1920)
	}
]


func _init() -> void:
	var exit_code: int = 0
	for asset in ASSETS:
		var image := Image.new()
		var load_error: Error = image.load(String(asset["source"]))
		if load_error != OK:
			push_error("Kaynak yüklenemedi: %s" % String(asset["source"]))
			exit_code = 1
			continue
		var target_size: Vector2i = asset["size"] as Vector2i
		if image.get_size() != target_size:
			image.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
		image.convert(Image.FORMAT_RGB8)
		var target_path: String = ProjectSettings.globalize_path(String(asset["target"]))
		var save_error: Error = image.save_png(target_path)
		if save_error != OK:
			push_error("PNG yazılamadı: %s" % target_path)
			exit_code = 1
			continue
		print("IOS_ASSET_READY: %s (%dx%d RGB)" % [
			String(asset["target"]), target_size.x, target_size.y
		])
	quit(exit_code)
