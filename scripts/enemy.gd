extends Node2D

signal defeated(reward: int)
signal reached_base(damage: int)

var max_health: float = 10.0
var health: float = 10.0
var speed: float = 60.0
var reward: int = 3
var base_damage: int = 5
var body_radius: float = 20.0
var target_position: Vector2
var is_boss: bool = false

func setup(
	new_target: Vector2,
	new_health: float,
	new_speed: float,
	new_reward: int,
	new_damage: int,
	new_radius: float,
	boss: bool = false
) -> void:
	target_position = new_target
	max_health = new_health
	health = max_health
	speed = new_speed
	reward = new_reward
	base_damage = new_damage
	body_radius = new_radius
	is_boss = boss
	add_to_group("enemies")
	queue_redraw()

func _process(delta: float) -> void:
	position = position.move_toward(target_position, speed * delta)
	if position.distance_to(target_position) <= body_radius + 30.0:
		reached_base.emit(base_damage)
		queue_free()

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		defeated.emit(reward)
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var body_color := Color("b23a48") if not is_boss else Color("7b2cbf")
	var outline_color := Color("5c1720") if not is_boss else Color("3c096c")

	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 40, outline_color, 4.0)

	# Eyes
	draw_circle(Vector2(-body_radius * 0.32, -body_radius * 0.12), max(2.5, body_radius * 0.10), Color.WHITE)
	draw_circle(Vector2(body_radius * 0.32, -body_radius * 0.12), max(2.5, body_radius * 0.10), Color.WHITE)
	draw_circle(Vector2(-body_radius * 0.32, -body_radius * 0.10), max(1.5, body_radius * 0.05), Color.BLACK)
	draw_circle(Vector2(body_radius * 0.32, -body_radius * 0.10), max(1.5, body_radius * 0.05), Color.BLACK)

	# Health bar
	var bar_width := body_radius * 2.2
	var ratio: float = clamp(health / max_health, 0.0, 1.0)
	var bar_rect := Rect2(Vector2(-bar_width / 2.0, -body_radius - 14.0), Vector2(bar_width, 7.0))
	draw_rect(bar_rect, Color("402b2d"))
	draw_rect(Rect2(bar_rect.position, Vector2(bar_width * ratio, 7.0)), Color("65d46e"))
