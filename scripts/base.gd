extends Node2D

var max_health: int = 100
var health: int = 100

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	queue_redraw()

func reset() -> void:
	health = max_health
	queue_redraw()

func _draw() -> void:
	# Castle/base
	draw_rect(Rect2(Vector2(-75.0, -45.0), Vector2(150.0, 90.0)), Color("6e7781"))
	draw_rect(Rect2(Vector2(-88.0, -66.0), Vector2(42.0, 45.0)), Color("59616a"))
	draw_rect(Rect2(Vector2(46.0, -66.0), Vector2(42.0, 45.0)), Color("59616a"))
	draw_rect(Rect2(Vector2(-18.0, 0.0), Vector2(36.0, 45.0)), Color("3d2b1f"))

	var bar_width := 150.0
	var ratio: float = float(health) / float(max_health)
	draw_rect(Rect2(Vector2(-75.0, -88.0), Vector2(bar_width, 10.0)), Color("402b2d"))
	draw_rect(Rect2(Vector2(-75.0, -88.0), Vector2(bar_width * ratio, 10.0)), Color("65d46e"))
