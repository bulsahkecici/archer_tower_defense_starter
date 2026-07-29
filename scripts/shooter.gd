extends Node2D
class_name ShooterUnit

const ArrowScript = preload("res://scripts/arrow.gd")

enum TowerType {
	ARCHER,
	CROSSBOW
}

var attack_range: float = 320.0
var damage: float = 2.0
var fire_interval: float = 0.85
var arrow_speed: float = 700.0
var cooldown: float = 0.0
var is_archer: bool = false
var level: int = 1
var tower_type: TowerType = TowerType.ARCHER

func setup_archer() -> void:
	is_archer = true
	attack_range = 520.0
	damage = 2.5
	fire_interval = 0.70
	queue_redraw()

func setup_tower(
	new_tower_type: TowerType = TowerType.ARCHER,
	tower_level: int = 1
) -> void:
	is_archer = false
	tower_type = new_tower_type
	level = tower_level
	if tower_type == TowerType.CROSSBOW:
		attack_range = 400.0 + float(tower_level) * 18.0
		damage = 28.0 + float(tower_level - 1) * 4.0
		fire_interval = maxf(0.8, 1.6 - float(tower_level - 1) * 0.08)
		arrow_speed = 900.0
	else:
		attack_range = 320.0 + float(tower_level) * 16.0
		damage = 10.0 + float(tower_level - 1) * 2.0
		fire_interval = maxf(0.35, 0.8 - float(tower_level - 1) * 0.05)
		arrow_speed = 760.0
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
	arrow.setup(target, damage, arrow_speed, tower_type == TowerType.CROSSBOW)

func _draw() -> void:
	if is_archer:
		# Archer body and bow
		draw_circle(Vector2(0.0, -18.0), 13.0, Color("f0c49a"))
		draw_rect(Rect2(Vector2(-10.0, -5.0), Vector2(20.0, 32.0)), Color("2f7d4f"))
		draw_arc(Vector2(17.0, -5.0), 22.0, -1.2, 1.2, 20, Color("6f4518"), 4.0)
		draw_line(Vector2(25.0, -25.0), Vector2(25.0, 15.0), Color("d8d8d8"), 2.0)
	else:
		draw_circle(Vector2(5.0, 17.0), 38.0, Color(0.06, 0.09, 0.11, 0.24))
		draw_circle(Vector2.ZERO, 34.0, Color("88958d"))
		draw_circle(Vector2.ZERO, 28.0, Color("596b63"))
		if tower_type == TowerType.CROSSBOW:
			draw_rect(Rect2(Vector2(-28.0, -48.0), Vector2(56.0, 69.0)), Color("526d96"))
			draw_line(Vector2(-40.0, -52.0), Vector2(40.0, -52.0), Color("9ed5df"), 8.0)
			draw_line(Vector2(-30.0, -72.0), Vector2(30.0, -32.0), Color("344a61"), 6.0)
			draw_line(Vector2(30.0, -72.0), Vector2(-30.0, -32.0), Color("344a61"), 6.0)
		else:
			draw_rect(Rect2(Vector2(-25.0, -42.0), Vector2(50.0, 63.0)), Color("4f9e75"))
			draw_colored_polygon(PackedVector2Array([
				Vector2(-34.0, -40.0), Vector2(0.0, -72.0), Vector2(34.0, -40.0)
			]), Color("73bd89"))
			draw_arc(Vector2(12.0, -48.0), 22.0, -1.2, 1.2, 20, Color("6f4518"), 4.0)
		draw_string(ThemeDB.fallback_font, Vector2(-7.0, 53.0), str(level), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
