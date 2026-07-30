extends Control
class_name ArcherTowerCardIcon3D


func _ready() -> void:
	custom_minimum_size = Vector2(66.0, 66.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center + Vector2(0.0, 11.0), 23.0, Color("59696a"))
	draw_colored_polygon(
		PackedVector2Array([
			center + Vector2(-27.0, 1.0),
			center + Vector2(0.0, -27.0),
			center + Vector2(27.0, 1.0)
		]),
		Color("2f6f67")
	)
	draw_rect(Rect2(center + Vector2(-17.0, 2.0), Vector2(34.0, 27.0)), Color("75b58d"))
	draw_line(center + Vector2(22.0, -13.0), center + Vector2(22.0, 24.0), Color("f3d27a"), 4.0)
