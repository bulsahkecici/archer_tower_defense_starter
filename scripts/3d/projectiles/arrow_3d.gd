extends Node3D
class_name ArrowProjectile3D

signal impact(hit: bool)

var target: Enemy3D
var fallback_position: Vector3
var damage: float = 10.0
var movement_speed: float = 18.0
var age: float = 0.0
var maximum_lifetime: float = 3.0
var has_impacted: bool = false
var model_root: Node3D
var start_position: Vector3


func _ready() -> void:
	add_to_group("projectiles_3d")
	_build_placeholder()


func setup(
	new_target: Enemy3D,
	new_damage: float,
	new_speed: float,
	new_fallback_position: Vector3
) -> void:
	target = new_target
	damage = maxf(0.0, new_damage)
	movement_speed = maxf(1.0, new_speed)
	fallback_position = new_fallback_position
	start_position = global_position


func _process(delta: float) -> void:
	if has_impacted:
		return
	age += delta
	if age >= maximum_lifetime:
		_finish(false)
		return
	var target_valid: bool = (
		is_instance_valid(target)
		and not target.is_queued_for_deletion()
		and not target.has_resolved
	)
	var destination: Vector3 = (
		target.global_position + Vector3.UP * 1.0
		if target_valid else fallback_position
	)
	var direction: Vector3 = global_position.direction_to(destination)
	var travel: float = movement_speed * delta
	if direction.length_squared() > 0.001:
		var safe_up: Vector3 = (
			Vector3.FORWARD
			if absf(direction.dot(Vector3.UP)) > 0.98 else Vector3.UP
		)
		look_at(global_position + direction, safe_up)
	if global_position.distance_to(destination) <= maxf(0.35, travel):
		global_position = destination
		if target_valid:
			target.take_damage(damage)
			_finish(true)
		else:
			_finish(false)
		return
	global_position += direction * travel


func _finish(hit: bool) -> void:
	if has_impacted:
		return
	has_impacted = true
	set_process(false)
	impact.emit(hit)
	queue_free()


func _build_placeholder() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var replaceable := Node3D.new()
	replaceable.name = "ReplaceableVisual_Arrow"
	model_root.add_child(replaceable)
	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var shaft_mesh := BoxMesh.new()
	shaft_mesh.size = Vector3(0.09, 0.09, 0.85)
	shaft.mesh = shaft_mesh
	shaft.material_override = LowPolyMaterials.create(Color("6e431d"))
	replaceable.add_child(shaft)
	var head := MeshInstance3D.new()
	head.name = "ArrowHead"
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.15
	head_mesh.height = 0.32
	head_mesh.radial_segments = 6
	head.mesh = head_mesh
	head.rotation_degrees.x = 90.0
	head.position.z = -0.56
	head.material_override = LowPolyMaterials.create(Color("e9cf7a"))
	replaceable.add_child(head)
