extends Tower3D
class_name ArcherTower3D


func _create_projectile(enemy: Enemy3D) -> Node3D:
	var arrow := ArrowProjectile3D.new()
	projectile_container.add_child(arrow)
	arrow.global_transform = fire_point.global_transform
	arrow.setup(enemy, damage, projectile_speed, enemy.global_position + Vector3.UP)
	return arrow


func _build_model(visual_parent: Node3D, head_parent: Node3D) -> void:
	replaceable_visual.name = "ReplaceableVisual_ArcherTower"
	var base := MeshInstance3D.new()
	base.name = "BaseVisual"
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.2
	base_mesh.bottom_radius = 1.4
	base_mesh.height = 1.25
	base_mesh.radial_segments = 8
	base.mesh = base_mesh
	base.position.y = 0.62
	base.material_override = LowPolyMaterials.create(Color("59696a"))
	visual_parent.add_child(base)
	var head_visual := MeshInstance3D.new()
	head_visual.name = "HeadVisual"
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(1.25, 0.85, 1.45)
	head_visual.mesh = head_mesh
	head_visual.position.y = 0.42
	head_visual.material_override = LowPolyMaterials.create(tower_data.accent)
	head_parent.add_child(head_visual)
	var roof := MeshInstance3D.new()
	roof.name = "Roof"
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = 1.05
	roof_mesh.height = 0.9
	roof_mesh.radial_segments = 8
	roof.mesh = roof_mesh
	roof.position.y = 1.25
	roof.material_override = LowPolyMaterials.create(Color("2f6f67"))
	head_parent.add_child(roof)
