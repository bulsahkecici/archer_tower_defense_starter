extends Node2D

const ArrowScript = preload("res://scripts/arrow.gd")

var attack_range: float = 320.0
var damage: float = 2.0
var fire_interval: float = 0.85
var arrow_speed: float = 700.0
var cooldown: float = 0.0
var is_archer: bool = false
var level: int = 1

func setup_archer() -> void:
	is_archer = true
	attack_range = 430.0
	damage = 2.5
	fire_interval = 0.70
	queue_redraw()

func setup_tower(tower_level: int = 1) -> void:
	is_archer = false
	level = tower_level
	attack_range = 280.0 + tower_level * 18.0
	damage = 1.8 + tower_level * 0.65
	fire_interval = max(0.28, 0.92 - tower_level * 0.07)
	queue_redraw()

func _process(delta: float) -> void:
	cooldown -= delta
	if cooldown > 0.0:
		return

	var target := _find_nearest_enemy()
	if target == null:
		return

	_shoot(target)
	cooldown = fire_interval

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := attack_range

	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var enemy := node as Node2D
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy

	return nearest

func _shoot(target: Node2D) -> void:
	var arrow := ArrowScript.new()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position + Vector2(0.0, -22.0)
	arrow.setup(target, damage, arrow_speed)

func _draw() -> void:
	if is_archer:
		# Archer body and bow
		draw_circle(Vector2(0.0, -18.0), 13.0, Color("f0c49a"))
		draw_rect(Rect2(Vector2(-10.0, -5.0), Vector2(20.0, 32.0)), Color("2f7d4f"))
		draw_arc(Vector2(17.0, -5.0), 22.0, -1.2, 1.2, 20, Color("6f4518"), 4.0)
		draw_line(Vector2(25.0, -25.0), Vector2(25.0, 15.0), Color("d8d8d8"), 2.0)
	else:
		# Tower base and roof
		draw_rect(Rect2(Vector2(-25.0, -28.0), Vector2(50.0, 58.0)), Color("73808c"))
		draw_rect(Rect2(Vector2(-30.0, -34.0), Vector2(60.0, 13.0)), Color("4f5963"))
		draw_circle(Vector2(0.0, -38.0), 8.0, Color("d8b25c"))
		draw_string(ThemeDB.fallback_font, Vector2(-7.0, 53.0), str(level), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
