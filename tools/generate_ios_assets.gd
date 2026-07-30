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
	call_deferred("_generate")


func _generate() -> void:
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
		if String(asset["target"]) == "res://assets/splash.png":
			_draw_bitmap_title(image, "OKÇULARIN", 1170, 14)
			_draw_bitmap_title(image, "SON KALESİ", 1330, 14)
		var save_error: Error = image.save_png(target_path)
		if save_error != OK:
			push_error("PNG yazılamadı: %s" % target_path)
			exit_code = 1
			continue
		print("IOS_ASSET_READY: %s (%dx%d RGB)" % [
			String(asset["target"]), target_size.x, target_size.y
		])
	quit(exit_code)


func _draw_bitmap_title(
	image: Image,
	text: String,
	top: int,
	pixel_size: int
) -> void:
	var glyphs: Dictionary = _get_bitmap_glyphs()
	var advance: int = pixel_size * 6
	var text_width: int = 0
	for character in text:
		text_width += pixel_size * 3 if character == " " else advance
	var left: int = (image.get_width() - text_width) / 2
	var cursor: int = left
	for character in text:
		if character == " ":
			cursor += pixel_size * 3
			continue
		var rows: Array = glyphs.get(character, glyphs["?"])
		for row_index in rows.size():
			var row: String = String(rows[row_index])
			for column in row.length():
				if row[column] != "1":
					continue
				var rect := Rect2i(
					cursor + column * pixel_size,
					top + row_index * pixel_size,
					pixel_size - 2,
					pixel_size - 2
				)
				image.fill_rect(
					Rect2i(rect.position + Vector2i(4, 5), rect.size),
					Color("2e211b")
				)
				image.fill_rect(rect, Color("fff3c4"))
		cursor += advance


func _get_bitmap_glyphs() -> Dictionary:
	return {
		"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
		"C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
		"Ç": ["01111", "10000", "10000", "10000", "10000", "01111", "00100", "01000"],
		"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
		"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
		"İ": ["00100", "00000", "11111", "00100", "00100", "00100", "11111"],
		"K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
		"L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
		"N": ["10001", "11001", "10101", "10101", "10011", "10001", "10001"],
		"O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
		"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
		"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
		"U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
		"?": ["01110", "10001", "00010", "00100", "00100", "00000", "00100"]
	}
