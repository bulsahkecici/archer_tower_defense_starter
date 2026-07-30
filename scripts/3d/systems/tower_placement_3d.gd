extends Node3D
class_name TowerPlacement3D

signal tower_placed(tower: ArcherTower3D, pad: BuildPad3D, cost: int)
signal placement_rejected(reason: String)
signal selection_changed(active: bool)

var camera: Camera3D
var build_pads: Array[BuildPad3D] = []
var economy: EconomyManager
var tower_container: Node3D
var projectile_container: Node3D
var selected_data: TowerData
var ghost_root: Node3D
var ghost_material: StandardMaterial3D
var hovered_pad: BuildPad3D
var ghost_valid: bool = false


func setup(
	game_camera: Camera3D,
	pads: Array[BuildPad3D],
	economy_manager: EconomyManager,
	tower_parent: Node3D,
	projectile_parent: Node3D
) -> void:
	camera = game_camera
	build_pads = pads
	economy = economy_manager
	tower_container = tower_parent
	projectile_container = projectile_parent
	_build_ghost()


func select_archer() -> void:
	selected_data = TowerData.create_archer()
	ghost_root.visible = true
	selection_changed.emit(true)


func cancel() -> void:
	selected_data = null
	hovered_pad = null
	ghost_valid = false
	if is_instance_valid(ghost_root):
		ghost_root.visible = false
	for pad in build_pads:
		pad.set_preview(false, false)
	selection_changed.emit(false)


func update_ghost_from_screen(screen_position: Vector2) -> bool:
	if selected_data == null:
		return false
	for pad in build_pads:
		pad.set_preview(false, false)
	hovered_pad = raycast_build_pad(screen_position)
	ghost_valid = is_pad_valid(hovered_pad)
	if is_instance_valid(hovered_pad):
		ghost_root.visible = true
		ghost_root.global_position = hovered_pad.global_position
		hovered_pad.set_preview(ghost_valid)
		ghost_material.albedo_color = (
			Color(0.30, 0.92, 0.52, 0.58)
			if ghost_valid else Color(0.95, 0.28, 0.28, 0.58)
		)
	else:
		var invalid_hit: Dictionary = raycast_restricted_surface(screen_position)
		ghost_root.visible = not invalid_hit.is_empty()
		if not invalid_hit.is_empty():
			ghost_root.global_position = invalid_hit.position
			ghost_material.albedo_color = Color(0.95, 0.28, 0.28, 0.58)
	return ghost_valid


func confirm_from_screen(screen_position: Vector2) -> ArcherTower3D:
	update_ghost_from_screen(screen_position)
	return place_on_pad(hovered_pad)


func raycast_build_pad(screen_position: Vector2) -> BuildPad3D:
	if not is_instance_valid(camera) or camera.get_world_3d() == null:
		return null
	var origin: Vector3 = camera.project_ray_origin(screen_position)
	var endpoint: Vector3 = origin + camera.project_ray_normal(screen_position) * 160.0
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		endpoint,
		CollisionLayers3D.PLACEMENT_RAY_MASK
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	return result.get("collider") as BuildPad3D


func raycast_restricted_surface(screen_position: Vector2) -> Dictionary:
	if not is_instance_valid(camera) or camera.get_world_3d() == null:
		return {}
	var origin: Vector3 = camera.project_ray_origin(screen_position)
	var endpoint: Vector3 = origin + camera.project_ray_normal(screen_position) * 160.0
	var restricted_mask: int = (
		CollisionLayers3D.ROAD
		| CollisionLayers3D.ENVIRONMENT
		| CollisionLayers3D.CASTLE
	)
	var query := PhysicsRayQueryParameters3D.create(origin, endpoint, restricted_mask)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return camera.get_world_3d().direct_space_state.intersect_ray(query)


func is_pad_valid(pad: BuildPad3D) -> bool:
	if selected_data == null or not is_instance_valid(pad) or pad.occupied:
		return false
	return economy.can_afford(get_cost_for_pad(pad))


func get_cost_for_pad(pad: BuildPad3D) -> int:
	if not is_instance_valid(pad):
		return 0
	var additional: int = selected_data.additional_cost if selected_data != null else 0
	return pad.build_cost + additional


func place_on_pad(pad: BuildPad3D) -> ArcherTower3D:
	if selected_data == null:
		placement_rejected.emit("Önce kule seç")
		return null
	if not is_instance_valid(pad):
		placement_rejected.emit("Geçerli bir inşa noktası seç")
		return null
	if pad.occupied:
		placement_rejected.emit("Bu inşa noktası dolu")
		return null
	var cost: int = get_cost_for_pad(pad)
	if not economy.spend_gold(cost):
		placement_rejected.emit("Yetersiz altın")
		return null
	var tower := ArcherTower3D.new()
	tower_container.add_child(tower)
	tower.global_position = pad.global_position
	tower.setup(selected_data, projectile_container)
	pad.set_occupied(tower)
	tower_placed.emit(tower, pad, cost)
	cancel()
	return tower


func _build_ghost() -> void:
	ghost_root = Node3D.new()
	ghost_root.name = "GhostTower"
	ghost_root.visible = false
	add_child(ghost_root)
	ghost_material = LowPolyMaterials.create(Color(0.30, 0.92, 0.52, 0.58), true)
	var base := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.2
	mesh.bottom_radius = 1.4
	mesh.height = 2.4
	mesh.radial_segments = 8
	base.mesh = mesh
	base.position.y = 1.2
	base.material_override = ghost_material
	ghost_root.add_child(base)
