extends Node2D

var target: Node2D
var damage: float = 2.0
var speed: float = 700.0
var is_heavy: bool = false

func setup(
	new_target: Node2D,
	new_damage: float,
	new_speed: float = 700.0,
	heavy_projectile: bool = false
) -> void:
	target = new_target
	damage = new_damage
	speed = new_speed
	is_heavy = heavy_projectile
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		queue_free()
		return

	var direction := global_position.direction_to(target.global_position)
	rotation = direction.angle()
	global_position += direction * speed * delta

	if global_position.distance_to(target.global_position) <= 20.0:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()

func _draw() -> void:
	var shaft_width: float = 7.0 if is_heavy else 4.0
	var shaft_color: Color = Color("344a61") if is_heavy else Color("5b3716")
	draw_line(Vector2(-18.0, 0.0), Vector2(12.0, 0.0), shaft_color, shaft_width)
	var arrow_head := PackedVector2Array([
		Vector2(16.0, 0.0),
		Vector2(4.0, -8.0 if is_heavy else -6.0),
		Vector2(4.0, 8.0 if is_heavy else 6.0)
	])
	draw_colored_polygon(
		arrow_head,
		Color("8fd4e5") if is_heavy else Color("dedede")
	)
