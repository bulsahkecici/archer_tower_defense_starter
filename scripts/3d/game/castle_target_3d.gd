extends Node3D
class_name CastleTarget3D

signal health_changed(current_health: int)
signal defeated

@export var max_health: int = 100

var health: int = 100
var model_root: Node3D
var body_material: StandardMaterial3D
var visual_state: StringName = &"healthy"


func _ready() -> void:
	health = maxi(1, max_health)
	add_to_group("castle_3d")
	_build_placeholder()


func take_damage(amount: int) -> bool:
	if amount <= 0 or health <= 0:
		return false
	health = clampi(health - amount, 0, max_health)
	_update_visual_state()
	health_changed.emit(health)
	if health == 0:
		defeated.emit()
	return true


func reset() -> void:
	health = maxi(1, max_health)
	_update_visual_state()
	health_changed.emit(health)


func _update_visual_state() -> void:
	var ratio: float = float(health) / float(maxi(1, max_health))
	visual_state = &"critical" if ratio <= 0.25 else (&"damaged" if ratio <= 0.60 else &"healthy")
	if is_instance_valid(body_material):
		body_material.albedo_color = (
			Color("85505a")
			if visual_state == &"critical"
			else (Color("8a765e") if visual_state == &"damaged" else Color("879598"))
		)


func _build_placeholder() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var replaceable := Node3D.new()
	replaceable.name = "ReplaceableVisual_Castle"
	model_root.add_child(replaceable)
	body_material = LowPolyMaterials.create(Color("879598"))
	var keep := MeshInstance3D.new()
	keep.name = "Keep"
	var keep_mesh := BoxMesh.new()
	keep_mesh.size = Vector3(5.8, 3.2, 4.5)
	keep.mesh = keep_mesh
	keep.position.y = 1.6
	keep.material_override = body_material
	replaceable.add_child(keep)
	for x_position in [-2.5, 2.5]:
		var tower := MeshInstance3D.new()
		tower.name = "CornerTower"
		var tower_mesh := CylinderMesh.new()
		tower_mesh.top_radius = 1.05
		tower_mesh.bottom_radius = 1.18
		tower_mesh.height = 4.8
		tower_mesh.radial_segments = 8
		tower.mesh = tower_mesh
		tower.position = Vector3(x_position, 2.4, -0.5)
		tower.material_override = body_material
		replaceable.add_child(tower)
	var roof_material := LowPolyMaterials.create(Color("2f6f67"))
	var roof := MeshInstance3D.new()
	roof.name = "RoofHook"
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = 1.5
	roof_mesh.height = 1.7
	roof_mesh.radial_segments = 8
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, 4.05, 0.0)
	roof.material_override = roof_material
	replaceable.add_child(roof)
	var body := StaticBody3D.new()
	body.name = "CastleCollision"
	body.collision_layer = CollisionLayers3D.CASTLE
	body.collision_mask = 0
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.5, 5.0, 5.0)
	shape.shape = box
	shape.position.y = 2.5
	body.add_child(shape)
