extends Control
class_name ArrowRainAbilityIcon

var ready_fill: float = 1.0:
	set(value):
		ready_fill = clampf(value, 0.0, 1.0)
		queue_redraw()
var is_ready: bool = true:
	set(value):
		is_ready = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(92.0, 76.0)
	queue_redraw()


func set_cooldown(remaining: float, duration: float) -> void:
	var safe_duration: float = maxf(0.001, duration)
	ready_fill = 1.0 - clampf(remaining / safe_duration, 0.0, 1.0)
	is_ready = remaining <= 0.0


func _draw() -> void:
	var center := size * 0.5
	var radius: float = minf(size.x, size.y) * 0.43
	draw_circle(center, radius, Color(0.04, 0.08, 0.11, 0.96))
	draw_arc(center, radius - 3.0, -PI * 0.5, -PI * 0.5 + TAU, 40, Color("34424a"), 7.0)
	if ready_fill > 0.001:
		draw_arc(
			center,
			radius - 3.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * ready_fill,
			maxi(3, int(40.0 * ready_fill)),
			Color("f1c65b"),
			7.0
		)
	var dim_color := Color("58636a")
	var active_color := Color("fff0a8") if is_ready else Color("d7a849")
	var arrow_color: Color = dim_color.lerp(active_color, ready_fill)
	for offset_x in [-18.0, 0.0, 18.0]:
		var start := center + Vector2(offset_x - 7.0, -22.0)
		var finish := center + Vector2(offset_x + 7.0, 20.0)
		draw_line(start, finish, arrow_color, 5.0)
		draw_colored_polygon(PackedVector2Array([
			finish + Vector2(0.0, 8.0),
			finish + Vector2(-7.0, -3.0),
			finish + Vector2(7.0, -3.0)
		]), arrow_color)
