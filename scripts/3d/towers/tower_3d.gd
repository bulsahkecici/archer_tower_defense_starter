extends Node3D
class_name Tower3D

signal projectile_fired(projectile: Node3D)

const RANGE_TO_METERS: float = 0.03
const PROJECTILE_SPEED_TO_METERS: float = 0.025

var tower_data: TowerData = TowerData.create_archer()
var level: int = 1
var attack_range: float = 10.0
var damage: float = 10.0
var attack_interval: float = 0.8
var projectile_speed: float = 19.0
var current_target: Enemy3D
var projectile_container: Node3D
var model_root: Node3D
var replaceable_visual: Node3D
var rotating_head: Node3D
var fire_point: Marker3D
var range_area: Area3D
var range_shape: SphereShape3D
var selection_area: Area3D
var target_scan_timer: Timer
var attack_timer: Timer
var last_projectile: Node3D


func _ready() -> void:
	add_to_group("towers_3d")
	_apply_data()
	_build_gameplay_hierarchy()
	_build_timers()


func setup(data: TowerData, projectile_parent: Node3D) -> void:
	tower_data = data
	projectile_container = projectile_parent
	_apply_data()


func _apply_data() -> void:
	attack_range = tower_data.get_attack_range(level) * RANGE_TO_METERS
	damage = tower_data.get_damage(level)
	attack_interval = tower_data.get_fire_interval(level)
	projectile_speed = tower_data.projectile_speed * PROJECTILE_SPEED_TO_METERS
	if is_instance_valid(attack_timer):
		attack_timer.wait_time = attack_interval
	if is_instance_valid(range_shape):
		range_shape.radius = attack_range


func _build_timers() -> void:
	target_scan_timer = Timer.new()
	target_scan_timer.name = "TargetScanTimer"
	target_scan_timer.wait_time = 0.20
	target_scan_timer.autostart = true
	target_scan_timer.timeout.connect(_scan_for_target)
	add_child(target_scan_timer)
	attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"
	attack_timer.wait_time = attack_interval
	attack_timer.autostart = true
	attack_timer.timeout.connect(_attempt_fire)
	add_child(attack_timer)


func _scan_for_target() -> Enemy3D:
	var best: Enemy3D
	var best_progress: float = -1.0
	for node in get_tree().get_nodes_in_group("enemies_3d"):
		var enemy := node as Enemy3D
		if (
			not is_instance_valid(enemy)
			or enemy.has_resolved
			or global_position.distance_to(enemy.global_position) > attack_range
		):
			continue
		if enemy.get_route_progress() > best_progress:
			best_progress = enemy.get_route_progress()
			best = enemy
	current_target = best
	return best


func _attempt_fire() -> bool:
	if (
		not is_instance_valid(current_target)
		or current_target.has_resolved
		or global_position.distance_to(current_target.global_position) > attack_range
	):
		_scan_for_target()
	if not is_instance_valid(current_target) or current_target.has_resolved:
		return false
	_aim_at(current_target.global_position)
	return _fire(current_target)


func _aim_at(world_position: Vector3) -> void:
	if not is_instance_valid(rotating_head):
		return
	var level_target := Vector3(world_position.x, rotating_head.global_position.y, world_position.z)
	if rotating_head.global_position.distance_squared_to(level_target) > 0.001:
		rotating_head.look_at(level_target, Vector3.UP)


func _fire(enemy: Enemy3D) -> bool:
	if not is_instance_valid(projectile_container) or not is_instance_valid(enemy):
		return false
	var projectile: Node3D = _create_projectile(enemy)
	if not is_instance_valid(projectile):
		return false
	last_projectile = projectile
	projectile_fired.emit(projectile)
	return true


func _create_projectile(_enemy: Enemy3D) -> Node3D:
	return null


func _build_gameplay_hierarchy() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	replaceable_visual = Node3D.new()
	replaceable_visual.name = "ReplaceableVisual_%s" % tower_data.display_name.replace(" ", "")
	model_root.add_child(replaceable_visual)
	rotating_head = Node3D.new()
	rotating_head.name = "RotatingHead"
	rotating_head.position.y = 1.35
	replaceable_visual.add_child(rotating_head)
	_build_model(replaceable_visual, rotating_head)
	fire_point = Marker3D.new()
	fire_point.name = "FirePoint"
	fire_point.position = Vector3(0.0, 0.65, -1.05)
	rotating_head.add_child(fire_point)

	range_area = Area3D.new()
	range_area.name = "RangeArea"
	range_area.collision_layer = 0
	range_area.collision_mask = CollisionLayers3D.ENEMY
	range_area.monitoring = true
	add_child(range_area)
	var range_collision := CollisionShape3D.new()
	range_shape = SphereShape3D.new()
	range_shape.radius = attack_range
	range_collision.shape = range_shape
	range_collision.position.y = 1.2
	range_area.add_child(range_collision)

	selection_area = Area3D.new()
	selection_area.name = "SelectionArea"
	selection_area.collision_layer = CollisionLayers3D.TOWER
	selection_area.collision_mask = 0
	add_child(selection_area)
	var selection_collision := CollisionShape3D.new()
	var selection_shape := CylinderShape3D.new()
	selection_shape.radius = 1.45
	selection_shape.height = 2.8
	selection_collision.shape = selection_shape
	selection_collision.position.y = 1.4
	selection_area.add_child(selection_collision)


func _build_model(_visual_parent: Node3D, _head_parent: Node3D) -> void:
	pass
