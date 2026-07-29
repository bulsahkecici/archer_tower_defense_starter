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
var tower_data: TowerData
var combat_enabled: bool = true
var build_tween: Tween
var fire_tween: Tween
var build_unlock_remaining: float = 0.0
var combat_permanently_stopped: bool = false
var resting_position: Vector2 = Vector2.ZERO
var static_base: Node2D
var turret_head: Node2D
var muzzle: Marker2D
var last_projectile: Node2D
var projectile_parent: Node2D


func _ready() -> void:
	_ensure_visual_nodes()


func set_projectile_parent(container: Node2D) -> void:
	projectile_parent = container


func setup_archer() -> void:
	is_archer = true
	combat_enabled = true
	combat_permanently_stopped = false
	attack_range = 520.0
	damage = 2.5
	fire_interval = 0.70
	arrow_speed = 700.0
	_ensure_visual_nodes()
	muzzle.position = Vector2(0.0, -42.0)
	_queue_visual_redraw()


func setup_tower(
	new_tower_type: TowerType = TowerType.ARCHER,
	tower_level: int = 1
) -> void:
	is_archer = false
	tower_type = new_tower_type
	level = tower_level
	combat_enabled = true
	combat_permanently_stopped = false
	var tower_id: StringName = (
		TowerData.CROSSBOW_ID
		if tower_type == TowerType.CROSSBOW
		else TowerData.ARCHER_ID
	)
	tower_data = TowerData.create_for_id(tower_id)
	attack_range = tower_data.attack_range + float(level - 1) * 16.0
	damage = tower_data.damage + float(level - 1) * (4.0 if tower_data.is_heavy_projectile else 2.0)
	fire_interval = maxf(
		0.8 if tower_data.is_heavy_projectile else 0.35,
		tower_data.fire_interval - float(level - 1) * (0.08 if tower_data.is_heavy_projectile else 0.05)
	)
	arrow_speed = tower_data.projectile_speed
	_ensure_visual_nodes()
	muzzle.position = Vector2(0.0, -82.0 if tower_data.is_heavy_projectile else -74.0)
	_queue_visual_redraw()


func _ensure_visual_nodes() -> void:
	if is_instance_valid(static_base):
		return
	static_base = Node2D.new()
	static_base.name = "StaticBase"
	add_child(static_base)
	static_base.draw.connect(func() -> void: _draw_static_visual(static_base))

	turret_head = Node2D.new()
	turret_head.name = "TurretHead"
	add_child(turret_head)
	turret_head.draw.connect(func() -> void: _draw_rotating_visual(turret_head))

	muzzle = Marker2D.new()
	muzzle.name = "Muzzle"
	turret_head.add_child(muzzle)


func _process(delta: float) -> void:
	if build_unlock_remaining > 0.0:
		build_unlock_remaining -= delta
		if build_unlock_remaining <= 0.0 and not combat_permanently_stopped:
			_finish_build_animation()
	if not combat_enabled:
		return
	cooldown -= delta
	if cooldown > 0.0:
		return
	var target: Node2D = _find_nearest_enemy()
	if target == null:
		return
	_shoot(target)
	cooldown = fire_interval


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance: float = attack_range
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if not node.is_in_group("enemies") or node.get("has_resolved") == true:
			continue
		var enemy := node as Node2D
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest


func _shoot(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	_ensure_visual_nodes()
	var direction: Vector2 = global_position.direction_to(target.global_position)
	turret_head.global_rotation = direction.angle() + PI * 0.5
	_play_fire_animation()
	var arrow := ArrowScript.new()
	if not is_instance_valid(projectile_parent) or not projectile_parent.is_inside_tree():
		arrow.queue_free()
		return
	projectile_parent.add_child(arrow)
	arrow.global_position = muzzle.global_position
	arrow.global_rotation = direction.angle()
	var heavy_projectile: bool = (
		not is_archer
		and tower_data != null
		and tower_data.is_heavy_projectile
	)
	arrow.setup(target, damage, arrow_speed, heavy_projectile)
	last_projectile = arrow


func _play_fire_animation() -> void:
	if fire_tween != null and fire_tween.is_valid():
		fire_tween.kill()
	turret_head.scale = Vector2.ONE
	turret_head.position = Vector2.ZERO
	var is_heavy: bool = not is_archer and tower_data != null and tower_data.is_heavy_projectile
	var recoil_scale: Vector2 = Vector2(1.14, 0.82) if is_heavy else Vector2(1.08, 0.90)
	var recoil_offset: Vector2 = Vector2(0.0, 7.0 if is_heavy else 4.0)
	var recovery_time: float = 0.18 if is_heavy else 0.12
	fire_tween = create_tween()
	fire_tween.set_parallel(true)
	fire_tween.tween_property(turret_head, "scale", recoil_scale, 0.05)
	fire_tween.tween_property(turret_head, "position", recoil_offset, 0.05)
	fire_tween.set_parallel(false)
	fire_tween.set_parallel(true)
	fire_tween.tween_property(turret_head, "scale", Vector2.ONE, recovery_time)
	fire_tween.tween_property(turret_head, "position", Vector2.ZERO, recovery_time)


func play_build_animation() -> void:
	_ensure_visual_nodes()
	resting_position = position
	combat_enabled = false
	combat_permanently_stopped = false
	build_unlock_remaining = 0.30
	_kill_build_tween()
	scale = Vector2(0.58, 0.58)
	modulate = Color(1.0, 1.0, 1.0, 0.35)
	position = resting_position + Vector2(0.0, 30.0)
	build_tween = create_tween()
	build_tween.set_parallel(true)
	build_tween.tween_property(self, "scale", Vector2.ONE, 0.28)
	build_tween.tween_property(self, "modulate", Color.WHITE, 0.22)
	build_tween.tween_property(self, "position", resting_position, 0.28)
	build_tween.set_parallel(false)
	build_tween.tween_callback(_finish_build_animation)


func _finish_build_animation() -> void:
	build_unlock_remaining = 0.0
	position = resting_position
	scale = Vector2.ONE
	modulate = Color.WHITE
	if not combat_permanently_stopped:
		combat_enabled = true


func stop_combat() -> void:
	combat_permanently_stopped = true
	combat_enabled = false
	build_unlock_remaining = 0.0
	_kill_build_tween()
	_kill_fire_tween()
	if resting_position != Vector2.ZERO and not is_archer:
		position = resting_position
	scale = Vector2.ONE
	modulate = Color.WHITE
	if is_instance_valid(turret_head):
		turret_head.scale = Vector2.ONE
		turret_head.position = Vector2.ZERO
	cooldown = fire_interval


func _kill_build_tween() -> void:
	if build_tween != null and build_tween.is_valid():
		build_tween.kill()
	build_tween = null


func _kill_fire_tween() -> void:
	if fire_tween != null and fire_tween.is_valid():
		fire_tween.kill()
	fire_tween = null


func _queue_visual_redraw() -> void:
	if is_instance_valid(static_base):
		static_base.queue_redraw()
	if is_instance_valid(turret_head):
		turret_head.queue_redraw()


func _draw_static_visual(canvas: Node2D) -> void:
	if is_archer:
		canvas.draw_circle(Vector2(5.0, 18.0), 25.0, Color(0.06, 0.10, 0.09, 0.24))
		canvas.draw_rect(Rect2(Vector2(-10.0, -5.0), Vector2(20.0, 32.0)), Color("2f7d4f"))
		return
	canvas.draw_circle(Vector2(5.0, 17.0), 38.0, Color(0.06, 0.09, 0.11, 0.24))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -38.0), Vector2(42.0, -10.0),
		Vector2(42.0, 28.0), Vector2(0.0, 48.0),
		Vector2(-42.0, 28.0), Vector2(-42.0, -10.0)
	]), Color("88958d"))
	canvas.draw_circle(Vector2.ZERO, 28.0, Color("596b63"))


func _draw_rotating_visual(canvas: Node2D) -> void:
	if is_archer:
		canvas.draw_circle(Vector2(0.0, -18.0), 13.0, Color("f0c49a"))
		canvas.draw_arc(Vector2(17.0, -18.0), 22.0, -1.2, 1.2, 20, Color("6f4518"), 4.0)
		canvas.draw_line(Vector2(25.0, -38.0), Vector2(25.0, 2.0), Color("d8d8d8"), 2.0)
		return
	var is_heavy: bool = tower_data != null and tower_data.is_heavy_projectile
	if is_heavy:
		canvas.draw_rect(Rect2(Vector2(-28.0, -48.0), Vector2(56.0, 69.0)), Color("526d96"))
		canvas.draw_line(Vector2(-40.0, -52.0), Vector2(40.0, -52.0), Color("9ed5df"), 8.0)
		canvas.draw_line(Vector2(-30.0, -72.0), Vector2(30.0, -32.0), Color("344a61"), 6.0)
		canvas.draw_line(Vector2(30.0, -72.0), Vector2(-30.0, -32.0), Color("344a61"), 6.0)
	else:
		canvas.draw_rect(Rect2(Vector2(-25.0, -42.0), Vector2(50.0, 63.0)), Color("4f9e75"))
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(-34.0, -40.0), Vector2(0.0, -72.0), Vector2(34.0, -40.0)
		]), Color("73bd89"))
		canvas.draw_arc(Vector2(12.0, -48.0), 22.0, -1.2, 1.2, 20, Color("6f4518"), 4.0)
