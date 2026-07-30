extends Node2D

const VisualEffectScript = preload("res://scripts/visual_effect.gd")

var target: Node2D
var damage: float = 2.0
var speed: float = 700.0
var is_heavy: bool = false
var slow_ratio: float = 0.0
var slow_duration: float = 0.0
var explosion_radius: float = 0.0
var critical: bool = false
var source_tower_id: StringName = &"hero"
var slowed_target_damage_multiplier: float = 1.0

func _ready() -> void:
	add_to_group("projectiles")

func setup(
	new_target: Node2D,
	new_damage: float,
	new_speed: float = 700.0,
	heavy_projectile: bool = false,
	new_slow_ratio: float = 0.0,
	new_slow_duration: float = 0.0,
	new_explosion_radius: float = 0.0,
	new_critical: bool = false,
	new_source_tower_id: StringName = &"hero",
	new_slowed_target_damage_multiplier: float = 1.0
) -> void:
	target = new_target
	damage = new_damage
	speed = new_speed
	is_heavy = heavy_projectile
	slow_ratio = maxf(0.0, new_slow_ratio)
	slow_duration = maxf(0.0, new_slow_duration)
	explosion_radius = maxf(0.0, new_explosion_radius)
	critical = new_critical
	source_tower_id = new_source_tower_id
	slowed_target_damage_multiplier = maxf(1.0, new_slowed_target_damage_multiplier)
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		queue_free()
		return

	var direction := global_position.direction_to(target.global_position)
	rotation = direction.angle()
	global_position += direction * speed * delta

	if global_position.distance_to(target.global_position) <= 20.0:
		var hit_effect := VisualEffectScript.new()
		var effect_parent: Node = get_parent()
		if effect_parent == null:
			effect_parent = get_tree().current_scene
		if effect_parent != null:
			effect_parent.add_child(hit_effect)
		else:
			hit_effect.queue_free()
		hit_effect.global_position = target.global_position
		hit_effect.setup_hit(is_heavy)
		if explosion_radius > 0.0:
			_apply_area_damage(target.global_position)
		else:
			if target.has_method("take_damage"):
				target.take_damage(damage, critical)
			if slow_ratio > 0.0 and target.has_method("apply_slow"):
				target.apply_slow(slow_ratio, slow_duration)
		queue_free()


func _apply_area_damage(center: Vector2) -> void:
	var hit_ids: Dictionary[int, bool] = {}
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var enemy := node as Node2D
		if enemy.global_position.distance_to(center) > explosion_radius:
			continue
		var instance_id: int = enemy.get_instance_id()
		if hit_ids.has(instance_id):
			continue
		hit_ids[instance_id] = true
		if enemy.has_method("take_damage"):
			var effective_damage: float = damage
			if (
				source_tower_id == TowerData.BOMB_ID
				and float(enemy.get("slow_remaining")) > 0.0
			):
				effective_damage *= slowed_target_damage_multiplier
			enemy.take_damage(effective_damage, critical)
	if not hit_ids.is_empty():
		get_tree().call_group(
			"gameplay_root",
			"_on_bomb_explosion",
			center,
			hit_ids.size()
		)

func _draw() -> void:
	var cosmetic_manager: Node = get_node_or_null("/root/CosmeticManager")
	var arrow_color: Color = Color("8fd4e5") if is_heavy else Color("dedede")
	if cosmetic_manager != null:
		arrow_color = cosmetic_manager.get_selected_color(&"arrow_trail", arrow_color)
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
		arrow_color
	)
