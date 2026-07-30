extends Control
class_name ArcherTowerCardIcon3D

var tower_id: StringName = TowerData.ARCHER_ID
var accent: Color = Color("4f9e75")


func _ready() -> void:
	custom_minimum_size = Vector2(66.0, 66.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(data: TowerData) -> void:
	tower_id = data.id
	accent = data.accent
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius: float = minf(size.x, size.y) * 0.34
	draw_circle(center + Vector2(0.0, 8.0), radius, Color("59696a"))
	draw_colored_polygon(
		PackedVector2Array([
			center + Vector2(-radius, 0.0),
			center + Vector2(0.0, -radius),
			center + Vector2(radius, 0.0)
		]),
		accent.darkened(0.22)
	)
	draw_rect(
		Rect2(center + Vector2(-radius * 0.62, 1.0), Vector2(radius * 1.24, radius)),
		accent
	)
	match tower_id:
		TowerData.CROSSBOW_ID:
			draw_line(center + Vector2(-16.0, 3.0), center + Vector2(16.0, 3.0), Color("e9cf7a"), 4.0)
			draw_line(center + Vector2(0.0, -9.0), center + Vector2(0.0, 17.0), Color("e9cf7a"), 3.0)
		TowerData.ICE_ID:
			for angle in [0.0, PI / 3.0, 2.0 * PI / 3.0]:
				var direction := Vector2(cos(angle), sin(angle)) * 17.0
				draw_line(center - direction, center + direction, Color("e6fcff"), 3.0)
		TowerData.BOMB_ID:
			draw_circle(center + Vector2(0.0, 4.0), 10.0, Color("343638"))
			draw_line(center + Vector2(5.0, -6.0), center + Vector2(11.0, -14.0), Color("f4a34f"), 3.0)
		_:
			draw_line(center + Vector2(15.0, -10.0), center + Vector2(15.0, 19.0), Color("f3d27a"), 4.0)
