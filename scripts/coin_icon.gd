extends Control
class_name CoinIcon

var coin_color: Color = Color("e6b84f")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(42.0, 42.0)
	queue_redraw()


func _draw() -> void:
	var radius: float = minf(size.x, size.y) * 0.34
	var center := size * 0.5
	draw_circle(center, radius + 4.0, Color("8e5b21"))
	draw_circle(center, radius, coin_color)
	draw_arc(center, radius * 0.62, 0.0, TAU, 24, coin_color.lightened(0.28), 3.0)
	draw_line(
		center + Vector2(-radius * 0.26, 0.0),
		center + Vector2(radius * 0.26, 0.0),
		Color("fff0a8"),
		3.0
	)
