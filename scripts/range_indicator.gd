extends Node2D
class_name TowerRangeIndicator

var radius: float = 0.0
var next_radius: float = 0.0
var accent: Color = Color("75b5aa")


func show_range(
	world_position: Vector2,
	current_radius: float,
	color: Color,
	preview_radius: float = 0.0
) -> void:
	global_position = world_position
	radius = maxf(0.0, current_radius)
	next_radius = maxf(0.0, preview_radius)
	accent = color
	visible = radius > 0.0
	queue_redraw()


func clear() -> void:
	radius = 0.0
	next_radius = 0.0
	visible = false
	queue_redraw()


func _draw() -> void:
	if radius <= 0.0:
		return
	draw_circle(Vector2.ZERO, radius, Color(accent, 0.075))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(accent, 0.72), 3.0)
	if next_radius > radius + 0.5:
		draw_arc(
			Vector2.ZERO,
			next_radius,
			0.0,
			TAU,
			96,
			Color(accent.lightened(0.22), 0.58),
			3.0
		)
