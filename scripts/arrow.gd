extends Node2D

var target: Node2D
var damage: float = 2.0
var speed: float = 700.0

func setup(new_target: Node2D, new_damage: float, new_speed: float = 700.0) -> void:
	target = new_target
	damage = new_damage
	speed = new_speed

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
	draw_line(Vector2(-15.0, 0.0), Vector2(12.0, 0.0), Color("5b3716"), 4.0)
	var arrow_head := PackedVector2Array([
		Vector2(12.0, 0.0),
		Vector2(4.0, -6.0),
		Vector2(4.0, 6.0)
	])
	draw_colored_polygon(arrow_head, Color("dedede"))
