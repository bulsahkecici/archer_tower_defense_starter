extends StaticBody3D
class_name BuildPad3D

var pad_index: int = -1
var build_cost: int = 15
var occupied: bool = false
var placed_tower: ArcherTower3D
var pad_material: StandardMaterial3D


func setup(index: int, cost: int) -> void:
	pad_index = index
	build_cost = maxi(0, cost)
	collision_layer = CollisionLayers3D.BUILDABLE
	collision_mask = 0
	add_to_group("build_pads_3d")
	_build_placeholder()


func set_occupied(tower: ArcherTower3D) -> void:
	placed_tower = tower
	occupied = is_instance_valid(tower)
	_update_color()


func set_preview(valid: bool, visible_preview: bool = true) -> void:
	if not is_instance_valid(pad_material):
		return
	if not visible_preview:
		_update_color()
		return
	pad_material.albedo_color = Color("73c989") if valid else Color("c95d5d")


func _update_color() -> void:
	if is_instance_valid(pad_material):
		pad_material.albedo_color = Color("596462") if occupied else Color("c5ad68")


func _build_placeholder() -> void:
	name = "BuildPad_%02d" % pad_index
	pad_material = LowPolyMaterials.create(Color("c5ad68"))
	var model_root := Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var visual := MeshInstance3D.new()
	visual.name = "ReplaceableVisual_BuildPad"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.65
	mesh.bottom_radius = 1.85
	mesh.height = 0.28
	mesh.radial_segments = 12
	visual.mesh = mesh
	visual.position.y = 0.14
	visual.material_override = pad_material
	model_root.add_child(visual)
	var cost_marker := Label3D.new()
	cost_marker.name = "BuildCost"
	cost_marker.text = "%d ALTIN" % build_cost
	cost_marker.position = Vector3(0.0, 0.65, 0.0)
	cost_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cost_marker.no_depth_test = true
	cost_marker.font_size = 60
	cost_marker.pixel_size = 0.011
	cost_marker.outline_size = 10
	cost_marker.modulate = Color("fff0b0")
	model_root.add_child(cost_marker)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.72
	shape.height = 0.32
	collision.shape = shape
	collision.position.y = 0.16
	add_child(collision)
