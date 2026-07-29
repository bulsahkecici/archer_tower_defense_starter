extends Node2D
class_name DefenseBase

var max_health: int = 100
var health: int = 100

func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	health = clampi(health - amount, 0, max_health)
	queue_redraw()

func reset() -> void:
	health = maxi(0, max_health)
	queue_redraw()

func _draw() -> void:
	# Castle/base
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.35, 1.35))
	draw_circle(Vector2(0.0, 35.0), 82.0, Color(0.08, 0.12, 0.13, 0.28))
	draw_rect(Rect2(Vector2(-75.0, -45.0), Vector2(150.0, 90.0)), Color("71818a"))
	draw_rect(Rect2(Vector2(-88.0, -66.0), Vector2(42.0, 45.0)), Color("53636e"))
	draw_rect(Rect2(Vector2(46.0, -66.0), Vector2(42.0, 45.0)), Color("53636e"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-96.0, -66.0), Vector2(-67.0, -94.0), Vector2(-38.0, -66.0)
	]), Color("347c86"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(38.0, -66.0), Vector2(67.0, -94.0), Vector2(96.0, -66.0)
	]), Color("347c86"))
	draw_rect(Rect2(Vector2(-18.0, 0.0), Vector2(36.0, 45.0)), Color("3d2b1f"))

	var bar_width := 150.0
	var ratio: float = float(health) / float(max_health)
	draw_rect(Rect2(Vector2(-75.0, -116.0), Vector2(bar_width, 10.0)), Color("402b2d"))
	draw_rect(Rect2(Vector2(-75.0, -116.0), Vector2(bar_width * ratio, 10.0)), Color("65d46e"))
